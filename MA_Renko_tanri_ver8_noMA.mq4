//+------------------------------------------------------------------+
//|                                               MA_Renko_tanri.mq4 |
//|                                                     Yuki Shinoda |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Yuki Shinoda"
#property link      ""
#property version   "1.00"
#property strict

#include <stdlib.mqh>

#define   MAGIC_NO  42244224

input double order_lot = 0.1;
input int ma_short_0 = 5;
input double stddev_rate = 0.005;
input bool h23 = true;
input bool h20_21 = true;
input bool h16_17 = true;
input bool h0 = true;
input bool h1 = true;
input bool Mend = true;
input bool M1 = true;
input bool M5 = true;
input bool M10 = true;
input bool M15 = true;
input bool M20 = true;
input bool M25 = true;
input bool M30 = true;
input bool friend = false;
input bool wed = false;

struct struct_PositionInfo {                // ポジション情報構造体型
    int               ticket_no;                // チケットNo
    int               entry_dir;                // エントリーオーダータイプ
    double            set_limit;                // リミットレート
    double            set_stop;                 // ストップレート
    datetime          entry_time;
};

enum RENKO_VARY { up_to_up, up_to_dn, up_cont, dn_to_dn, dn_to_up, dn_cont};

static struct_PositionInfo  _StPositionInfoData;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
    static    datetime s_lasttime;                      // 最後に記録した時間軸時間
                                                        // staticはこの関数が終了してもデータは保持される
    datetime temptime = iTime( Symbol(), Period() ,0 ); // 現在の時間軸の時間取得
    if ( temptime == s_lasttime ) {                     // 時間に変化が無い場合
        return;                                         // 処理終了
    }
    s_lasttime = temptime;                              // 最後に記録した時間軸時間を
        
    if ( iBars(NULL,0) <= ma_short_0 ) {                     // 時間に変化が無い場合
        return;                                         // 処理終了
    }
    
    
    static int renko_dir = 1;
    static double ATR = stddev_rate*iClose(NULL, 0, 1);
    static int renko_dir_new;
    //static double max_std = iMA(NULL, 0, ma_short_0, 0, MODE_EMA, PRICE_CLOSE, 1);
    static double max_std = iClose(NULL, 0, 1);
    //static double min_std = iMA(NULL, 0, ma_short_0, 0, MODE_EMA, PRICE_CLOSE, 1);
    static double min_std = iClose(NULL, 0, 1);
    static int n = 0;
    RENKO_VARY ret;
   
    double ema_short = iMA(NULL, 0, ma_short_0, 0, MODE_EMA, PRICE_CLOSE, 1);
    //double close = iClose(NULL, 0, 1);
   
    if (renko_dir == 1){
       if(ema_short - max_std >= ATR){
          n = MathFloor((ema_short - max_std)/ATR);
          max_std = max_std + n*ATR;
          ATR = stddev_rate*max_std;
          renko_dir_new = 1;
          ret = up_to_up;
       }
       else if(ema_short - max_std <= -1*ATR){
          n = MathFloor((max_std - ema_short)/ATR);
          min_std = max_std - n*ATR;
          ATR = stddev_rate*min_std;
          renko_dir_new = -1;
          ret = up_to_dn;
       }
       else{
          renko_dir_new = 1;
          ret = up_cont;
       }
    }
   
    if (renko_dir == -1){
       if(ema_short - min_std <= -1*ATR){
          n = MathFloor((min_std - ema_short)/ATR);
          min_std = min_std - n*ATR;
          ATR = stddev_rate*min_std;
          renko_dir_new = -1;
          ret = dn_to_dn;
       }
       else if(ema_short - min_std >= ATR){
          n = MathFloor((ema_short - min_std)/ATR);
          max_std = min_std + n*ATR;
          ATR = stddev_rate*max_std;
          renko_dir_new = 1;
          ret = dn_to_up;
       }
       else{
          renko_dir_new = -1;
          ret = dn_cont;
       }
    }
   
    renko_dir = renko_dir_new;
 
    
    JudgeClose( ret );                           // 決済オーダー判定
    JudgeEntry( ret );                           // エントリーオーダー判定    
  }
  
  

//+------------------------------------------------------------------+
//| エントリーオーダー判定
//+------------------------------------------------------------------+
void JudgeEntry( RENKO_VARY in_renko ) {
    
    bool entry_bool = false;    // エントリー判定
    bool entry_long = false;    // ロングエントリー判定

    if ( in_renko == up_to_up || in_renko == dn_to_up ) {           // MA上抜け
    //if ( in_renko == up_to_up ) {
        entry_bool = true;
        entry_long = true;
    } 
    else if ( in_renko == dn_to_dn || in_renko == up_to_dn ) {  // MA下抜け
    //else if ( in_renko == dn_to_dn ) {
        entry_bool = true;
        entry_long = false;
    }

    GetPosiInfo( _StPositionInfoData );        // ポジション情報を取得
    
    if ( _StPositionInfoData.ticket_no > 0 ) { // ポジション保有中の場合
        entry_bool = false;                    // エントリー禁止
    }
    
    if ( h23 == true ){
       if ( Hour() == 23 ){
         entry_bool = false;
       }
    }
    
    if ( h0 == true ){
       if ( Hour() == 0 ){
         entry_bool = false;
       }
    }
    
    if ( h1 == true ){
       if ( Hour() == 1 ){
         entry_bool = false;
       }
    }
    
    if ( h16_17 == true ){
       if ((isSummerTime() == true && Hour() == (16||17)) || (isSummerTime() == false && Hour() == (17||18)) ){
         entry_bool = false;
       }
    }
    
    if ( h20_21 == true ){
       if ( Hour() == 20 || Hour() == 21 ){
         entry_bool = false;
       }
    }
    
    if ( Mend == true ){
       if ( (Month() == 1 || Month() == 3 || Month() == 5 || Month() == 7 || Month() == 8 || Month() == 10 || Month() == 12) && Day() == 31 ){
         if ( Hour() >= 0 ){
            entry_bool = false;
            }
       }
       if ( (Month() == 4 || Month() == 6 || Month() == 9 || Month() == 11) && Day() == 30 ){
         if ( Hour() >= 0 ){
            entry_bool = false;
            }
       }
       if ( Month() == 2 && Day() == 28 ){
         if ( Hour() >= 0 ){
            entry_bool = false;
            }
       }
    }
    
    if ( M1 == true ){
       if ( Day() == 1 ){
         entry_bool = false;
       }
    }
    
    if ( M5 == true ){
       if ( Day() == 5 ){
         entry_bool = false;
       }
    }
    
    if ( M10 == true ){
       if ( Day() == 10 ){
         entry_bool = false;
       }
    }
    
    if ( M15 == true ){
       if ( Day() == 15 ){
         entry_bool = false;
       }
    }
    
    if ( M20 == true ){
       if ( Day() == 20 ){
         entry_bool = false;
       }
    }
    
    if ( M25 == true ){
       if ( Day() == 25 ){
         entry_bool = false;
       }
    }
    
    if ( M30 == true ){
       if ( Day() == 30 ){
         entry_bool = false;
       }
    }
    
    
    if ( friend == true ){
       if ( (DayOfWeek() == 5 && Hour() >= 12) || DayOfWeek() == 6 ){
         entry_bool = false;
       }
    }
    
    if ( wed == true ){
       if ( (DayOfWeek() == 3 && Hour() < 9) ){
         entry_bool = false;
       }
    }
    
    if ( entry_bool == true ) {
        EA_EntryOrder( entry_long );        // 新規エントリー
    }
}

//+------------------------------------------------------------------+
//| 決済オーダー判定
//+------------------------------------------------------------------+
void JudgeClose( RENKO_VARY in_renko ) {    
    
    bool close_bool = false;    // 決済判定

    GetPosiInfo( _StPositionInfoData );
    
    if ( _StPositionInfoData.ticket_no > 0 ) { // ポジション保有中の場合

        if ( _StPositionInfoData.entry_dir == OP_SELL ) {       // 売りポジ保有中の場合
            if ( in_renko == dn_to_up || in_renko == up_to_up ) {               // MA上抜け
                close_bool = true;
            }
            
        } else if ( _StPositionInfoData.entry_dir == OP_BUY ) { // 買いポジ保有中の場合
            if ( in_renko == up_to_dn || in_renko == dn_to_dn ) {             // MA下抜け
                close_bool = true;
            }
        } 
    }
    
    //if (friend == true){
      // if ( _StPositionInfoData.ticket_no > 0 && (DayOfWeek() == 5 && Hour() == 23 && Minute() == 55 ) ){
        // close_bool = true;
      // }
    //}
    
    
    if ( close_bool == true ) {
        bool close_done = false;
        close_done = EA_Close_Order( _StPositionInfoData.ticket_no );        // 決済処理

        if ( close_done == true ) {
            ClearPosiInfo(_StPositionInfoData);                             // ポジション情報クリア(決済済みの場合)
        }
    }
}


//+------------------------------------------------------------------+
//| ポジション情報を取得
//+------------------------------------------------------------------+
bool GetPosiInfo( struct_PositionInfo &in_st ){

    bool ret = false;
    int  position_total = OrdersTotal();     // 保有しているポジション数取得

    // 全ポジション分ループ
    for ( int icount = 0 ; icount < position_total ; icount++ ) {

        if ( OrderSelect( icount , SELECT_BY_POS ) == true ) {          // インデックス指定でポジションを選択

            if ( OrderMagicNumber() != MAGIC_NO ) {                   // マジックナンバー不一致判定
                continue;                                               // 次のループ処理へ
            }

            if ( OrderSymbol() != Symbol() ) {                        // 通貨ペア不一致判定
                continue;                                               // 次のループ処理へ
            }

            in_st.ticket_no      = OrderTicket();                       // チケット番号を取得
            in_st.entry_dir      = OrderType();                         // オーダータイプを取得
            in_st.set_limit      = OrderTakeProfit();                   // リミットを取得
            in_st.set_stop       = OrderStopLoss();                     // ストップを取得
            in_st.entry_time     = OrderOpenTime();

            ret = true;

            break;                                                      // ループ処理中断
        }
    }

    return ret;
}

//+------------------------------------------------------------------+
//| ポジション情報をクリア(決済済みの場合)
//+------------------------------------------------------------------+
void ClearPosiInfo( struct_PositionInfo &in_st ) {
    
    if ( in_st.ticket_no > 0 ) { // ポジション保有中の場合

        bool select_bool;                // ポジション選択結果

        // ポジションを選択
        select_bool = OrderSelect(
                        in_st.ticket_no ,// チケットNo
                        SELECT_BY_TICKET // チケット指定で注文選択
                    ); 

        // ポジション選択失敗時
        if ( select_bool == false ) {
            printf( "[%d]不明なチケットNo = %d" , __LINE__ , in_st.ticket_no);
            return;
        }

        // ポジションがクローズ済みの場合
        if ( OrderCloseTime() > 0 ) {
            ZeroMemory( in_st );            // ゼロクリア
        }

    }
    
}



//+------------------------------------------------------------------+
//| 新規エントリー
//+------------------------------------------------------------------+
bool EA_EntryOrder( 
                    bool in_long // true:Long false:Short
) {
    
    bool   ret        = false;      // 戻り値
    int    order_type = OP_BUY;     // 注文タイプ
    double order_rate = Ask;        // オーダープライスレート
    //double stop;
    
    if ( in_long == true ) {        // Longエントリー
        order_type = OP_BUY;
        order_rate = Ask;
        //stop       = Ask - ATR*LCrate;

    } else {                        // Shortエントリー
        order_type = OP_SELL;
        order_rate = Bid;
        //stop       = Bid + ATR*LCrate;
    }

    int ea_ticket_res = -1; // チケットNo

    ea_ticket_res = OrderSend(                           // 新規エントリー注文
                                Symbol(),                // 通貨ペア
                                order_type,               // オーダータイプ[OP_BUY / OP_SELL]
                                order_lot,                // ロット[0.01単位]
                                order_rate,               // オーダープライスレート
                                100,                      // スリップ上限    (int)[分解能 0.1pips]
                                0,                        // ストップレート
                                0,                        // リミットレート
                                "SMAクロスEA",            // オーダーコメント
                                MAGIC_NO                  // マジックナンバー(識別用)
                               );   

    if ( ea_ticket_res != -1) {    // オーダー正常完了
        ret = true;

    } else {                       // オーダーエラーの場合

        int    get_error_code   = GetLastError();                   // エラーコード取得
        string error_detail_str = ErrorDescription(get_error_code); // エラー詳細取得

        // エラーログ出力
        printf( "[%d]エントリーオーダーエラー。 エラーコード=%d エラー内容=%s" 
            , __LINE__ ,  get_error_code , error_detail_str
         );        
    }

    return ret;
}

//+------------------------------------------------------------------+
//| 注文決済
//+------------------------------------------------------------------+
bool EA_Close_Order( int in_ticket ){

    bool select_bool;                // ポジション選択結果
    bool ret = false;                // 結果

    // ポジションを選択
    select_bool = OrderSelect(
                    in_ticket ,      // チケットNo
                    SELECT_BY_TICKET // チケット指定で注文選択
                ); 

    // ポジション選択失敗時
    if ( select_bool == false ) {
        printf( "[%d]不明なチケットNo = %d" , __LINE__ , in_ticket);
        return ret;    // 処理終了
    }

    // ポジションがクローズ済みの場合
    if ( OrderCloseTime() > 0 ) {
        printf( "[%d]ポジションクローズ済み チケットNo = %d" , __LINE__ , in_ticket );
        return true;   // 処理終了
    }

    bool   close_bool;                  // 注文結果
    int    get_order_type;               // エントリー方向
    double close_rate = 0 ;              // 決済価格
    double close_lot  = 0;               // 決済数量

    get_order_type = OrderType();        // 注文タイプ取得
    close_lot      = OrderLots();        // ロット数


    if ( get_order_type == OP_BUY ) {            // 買いの場合
        close_rate = Bid;

    } else if ( get_order_type == OP_SELL ) {    // 売りの場合
        close_rate = Ask;

    } else {                                      // エントリー指値注文の場合
        return ret;                              // 処理終了
    }


    close_bool = OrderClose(              // 決済オーダー
                    in_ticket,              // チケットNo
                    close_lot,              // ロット数
                    close_rate,             // クローズ価格
                    20,                     // スリップ上限    (int)[分解能 0.1pips]
                    clrWhite              // 色
                  );

    if ( close_bool == false) {    // 失敗

        int    get_error_code   = GetLastError();                   // エラーコード取得
        string error_detail_str = ErrorDescription(get_error_code); // エラー詳細取得

        // エラーログ出力
        printf( "[%d]決済オーダーエラー。 エラーコード=%d エラー内容=%s" 
            , __LINE__ ,  get_error_code , error_detail_str
         );        
    } else {
        ret = true; // 戻り値設定：成功
    }

    return ret; // 戻り値を返す
}


//+------------------------------------------------------------------+
//| サマータイム判定
//+------------------------------------------------------------------+

bool isSummerTime(){
   bool ret = false;
   
   datetime summerStart;   //サマータイム開始日
   datetime summerEnd;     //サマータイム終了日
   datetime tc = TimeCurrent();
   
   //サマータイム開始日を3/14の前の日曜日に設定
   summerStart = StringToTime(IntegerToString(Year()) + ".03.14");
   summerStart = summerStart - TimeDayOfWeek(summerStart) * 24 * 60 * 60;
   
   //サマータイム終了日を11/7の前の日曜日に設定
   summerEnd = StringToTime(IntegerToString(Year()) + ".11.07");
   summerEnd = summerEnd - TimeDayOfWeek(summerEnd) *24 * 60 * 60;
   
   //現在の時刻がサマータイム開始日と終了日の間であればtrueを返す
   if(tc > summerStart && tc < summerEnd) ret = true;
   return ret;
}