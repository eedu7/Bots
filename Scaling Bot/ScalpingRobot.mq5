#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>

CTrade         trade;
CPositionInfo  pos;
COrderInfo     ord;

input group "=== Trading Profiles ==="
   enum SystemType{Forex=0, BitCoin=1, _Gold=2, US_Indices=3};
   input SystemType SType=0;  
   
   int SysChoice;
   
input group "=== Common Trading Inputs ==="
   input double            RiskPercent = 3;  // Risk as % of Trading Capital
   input ENUM_TIMEFRAMES   Timeframe = PERIOD_CURRENT;  // The current TimeFrame on the chart
   input int               InpMagic = 298347;  // EA identification number
   input string            TradeComment = "Scalping Robot";
   
   enum StartHour {
       Inactive=0, _0100=1, _0200=2, _0300=3, _0400=4, _0500=5,
       _0600=6, _0700=7, _0800=8, _0900=9, _1000=10, _1100=11, 
       _1200=12, _1300=13, _1400=14, _1500=15, _1600=16, 
       _1700=17, _1800=18, _1900=19, _2000=20, _2100=21, 
       _2200=22, _2300=23};
   
   input StartHour SHInput=0;  // Start Hour
   
    enum EndHour {
       Inactive=0, _0100=1, _0200=2, _0300=3, _0400=4, _0500=5,
       _0600=6, _0700=7, _0800=8, _0900=9, _1000=10, _1100=11, 
       _1200=12, _1300=13, _1400=14, _1500=15, _1600=16, 
       _1700=17, _1800=18, _1900=19, _2000=20, _2100=21, 
       _2200=22, _2300=23};
   
   input EndHour EHInput=0;  // End Hour
   int ShChoice;
   int EhChoice;
   
   int BarsN = 5;  // Number of bars to check in the left and right of a bar, to see if the current bar is higher high or lower low
   int ExpirationBars = 100;
   double OrderDistPoints = 100;
   double Tppoints, Slpoints, TslTriggerPoints, TslPoints;
   
   int handleRSI, handleMovAvg;
   input color ChartColorTradingOff = clrPink;  // Char color when EA is Inactive  
   input color ChartColorTradingon = clrBlack;  // Chart color when EA is active
   
   bool TradingEnabled = true;
   input bool HideIndicators = true;  // Hide Indicators on Chart?
      string TradingEnabledComm = "";


input group "=== Forex Trading Inputs ==="
  
   input int               TppointsInput = 200; // Take Profit (10 points = 1 pip)
   input int               SlpointsInput = 200; // Stoploss (10 points = 1 pip)
   input int               TslTriggerPointsInput = 15; // Points in profit before Trailing SL is activated (10 points = 1 pip)
   input int               TslPointsInput = 10; // Trailing Stop Loss (10 points = 1 pip)
   
input group "=== Crypto Related Input === (effective only under BitCoin Profile) ==="
   input double TPasPct          = 0.4;      // TP as % of Price
   input double SLasPct          = 0.4;      // SL as % of Price
   input double TSLasPctofTP     = 5;   // Traill SL as % of TP
   input double TSLTgrassPctofTP = 7;   // Trigger of Trail SL % of TP
   
input group "=== Gold Related Input === (effective only under Gold Profile)"
   input double TPasPctGold = 0.2;  // TP as % of Price
   input double SLasPctGold = 0.2;  // SL as % of Price
   input double TSLasPctofTPGold = 5;  // Trail SL as % of TP
   input double TSLTgrassPctofTPGold =7; //Trigger of Trail SL % of TP

input group "=== Indices Related Input === (effective only under Indices Profile)"
   input double TPasPctIndices = 0.2;  // TP as % of Price
   input double SLasPctIndices = 0.2;  // SL as % of Price
   input double TSLasPctofTPIndices = 5;  // Trail SL as % of TP
   input double TSLTgrassPctofTPIndices =7; //Trigger of Trail SL % of TP
   
input group "=== News Filter ==="
   input bool NewsFilterOn = true;  // Filter for Level 3 News?
   enum sep_dropdown{comma=0, semicolon=1};
   input sep_dropdown separator = 0;  // Separator to separate news keywords
   input string KeyNews = "BCB,NFP,JOLTS,Nonfarm,PMI,Retail,GDP,Confidence,Interest Rate";  // Keywords
   input string NewsCurrencies = "USD,GBP,EUR,JPY,BRL"; // Currencies for News LookUp
   input int DaysNewsLookup = 100;  // No of days to look up news;
   input int StopBeforeMin = 15;  // Stop Trading before (in minutes)
   input int StartTradingMin = 15;  // Start Trading after (in minutes)
         bool TriDisabledNews = false;  // Variable to store if trading disable due to news
   
         ushort sep_code;
         string NewsToAvoid[];
         datetime LastNewsAvoided;
         
input group "=== RSI Filter ==="
 input bool RSIFilterOn = false;
 input ENUM_TIMEFRAMES RSITimeframe = PERIOD_H1;
 input int RSILowerLvl = 20;
 input int RSIUpperLvl = 80;
 input int RSI_MA = 14;
 input ENUM_APPLIED_PRICE RSI_AppPrice = PRICE_MEDIAN;
   
input group "=== Moving Average Filter ==="
   input bool MAFilterOn = false;
   input ENUM_TIMEFRAMES MATimeframe = PERIOD_H4;
   input double PctPricefromMA = 3;
   input int MA_Period = 200;
   input ENUM_MA_METHOD MA_Mode = MODE_EMA;
   input ENUM_APPLIED_PRICE MA_AppPrice = PRICE_MEDIAN;

int OnInit()
{


   trade.SetExpertMagicNumber(InpMagic);
      
   ChartSetInteger(0, CHART_SHOW_GRID, false);  // Disable the Grid
      
   Tppoints = TppointsInput;
   Slpoints = SlpointsInput;
   TslTriggerPoints = TslTriggerPointsInput;
   TslPoints = TslPointsInput;
      
   ShChoice = SHInput;
   EhChoice = EHInput;
   
   if (SType==0) SysChoice=0;
   if (SType==1) SysChoice=1;
   if (SType==2) SysChoice=2;
   if (SType==3) SysChoice=3;
   
   if (HideIndicators==true) TesterHideIndicators(true);
   
   handleRSI = iRSI(_Symbol,RSITimeframe,RSI_MA,RSI_AppPrice);
   handleMovAvg = iMA(_Symbol,MATimeframe,MA_Period,0,MA_Mode,MA_AppPrice);
   
      
   
   return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason)
{
   

  
}


void OnTick()
{

   TrailStop();
   
   
   if(isRSIFilter() || IsUpcomingNews() || IsMAFilter()){
      CloseAllOrders();
      TradingEnabled=false;
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, ChartColorTradingOff);
      if(TradingEnabledComm!="Printed"){
         Print(TradingEnabledComm);}
         TradingEnabledComm="Printed";
         return;
      }
      
      
      TradingEnabled=true;
      if(TradingEnabledComm!=""){
         Print("Trading is enabled again");
         TradingEnabledComm = "";
      }
      
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, ChartColorTradingon);
   
   

   if(!IsNewBar()) return;
   
   MqlDateTime time;
   TimeToStruct(TimeCurrent(), time);
   int HourNow = time.hour;

   
   if(HourNow < ShChoice){CloseAllOrders(); return;}
   if(HourNow >= EhChoice && EhChoice != 0){CloseAllOrders(); return;}
   
   if(SysChoice==1){
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      Tppoints = ask * TPasPct;
      Slpoints = ask * SLasPct;
      OrderDistPoints = Tppoints / 2;
      TslPoints = Tppoints * TSLasPctofTP / 100;
      TslTriggerPoints = Tppoints * TSLTgrassPctofTP/100;
   }
      if(SysChoice==2){
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      Tppoints = ask * TPasPctGold;
      Slpoints = ask * SLasPctGold;
      OrderDistPoints = Tppoints / 2;
      TslPoints = Tppoints * TSLasPctofTPGold / 100;
      TslTriggerPoints = Tppoints * TSLTgrassPctofTPGold/100;
   }
      if(SysChoice==3){
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      Tppoints = ask * TPasPctIndices;
      Slpoints = ask * SLasPctIndices;
      OrderDistPoints = Tppoints / 2;
      TslPoints = Tppoints * TSLasPctofTPIndices / 100;
      TslTriggerPoints = Tppoints * TSLTgrassPctofTPIndices/100;
   }
   
   int BuyTotal = 0;
   int SellTotal = 0;
   
   for (int i = PositionsTotal() -1; i >= 0; i--) {
      pos.SelectByIndex(i);
      if(pos.PositionType() == POSITION_TYPE_BUY && pos.Symbol() == _Symbol && pos.Magic() == InpMagic) BuyTotal++;
      if(pos.PositionType() == POSITION_TYPE_SELL && pos.Symbol()==_Symbol && pos.Magic() == InpMagic) SellTotal++;
   }
   
   for (int i = OrdersTotal() - 1; i >= 0; i--){
      ord.SelectByIndex(i);
      if(ord.OrderType()==ORDER_TYPE_BUY_STOP && ord.Symbol()==_Symbol && ord.Magic()==InpMagic) BuyTotal++;
      if(ord.OrderType()==ORDER_TYPE_SELL_STOP && ord.Symbol()==_Symbol && ord.Magic()==InpMagic) SellTotal++;
   }
   
   if (BuyTotal <= 0) {
      double high = findHigh();
      if (high > 0) {
         SendBuyOrder(high);
      }
   }
   
   if (SellTotal <= 0) {
      double low = findLow();
      if (low > 0) {
      SendSellOrder(low);
      }
   }
}


double findHigh() {

   double highestHigh = 0;

   for (int i = 0; i < 200; i++) {
   
      double high = iHigh(_Symbol, Timeframe, i);
      
      if(i > BarsN && iHighest(_Symbol, Timeframe, MODE_HIGH, BarsN*2+1,i-BarsN) == i){
      
         if(high > highestHigh) {
            return high;
         }
         
         highestHigh = MathMax(high, highestHigh);
      }
   }
   return -1;

}

double findLow() {
   double lowestLow = DBL_MAX;
   for(int i = 0; i < 200; i++){
      double low = iLow(_Symbol, Timeframe, i);
      if(i > BarsN && iLowest(_Symbol,Timeframe,MODE_LOW,BarsN*2+1,i-BarsN) ==i){
         if(low < lowestLow){
            return low;
         }
      }
      lowestLow = MathMin(low, lowestLow);
   }
   return -1;
}

bool IsNewBar(){
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol, Timeframe, 0);
   if(previousTime != currentTime){
      previousTime=currentTime;
      return true;
   }
   return false;
}


void SendBuyOrder(double entry){
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);  // Current Price
   
   if (ask > entry - OrderDistPoints * _Point) return;
   
   double tp = entry + Tppoints * _Point;
   double sl = entry - Slpoints * _Point;
   
   double lots = 0.01;
   if(RiskPercent > 0) lots = calcLots(entry-sl);
   
   datetime expiration = iTime(_Symbol, Timeframe,0) + ExpirationBars * PeriodSeconds(Timeframe);
  
   trade.BuyStop(lots, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration);
}

void SendSellOrder(double entry){
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid < entry + OrderDistPoints * _Point) return;
   
   double tp = entry - Tppoints * _Point;
   double sl = entry + Slpoints * _Point;
   
   double lots = 0.01;
   if(RiskPercent > 0) lots = calcLots(sl - entry);
   
   datetime expiration = iTime(_Symbol, Timeframe,0) + ExpirationBars * PeriodSeconds(Timeframe);
  
   trade.SellStop(lots, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration);
}


double calcLots(double slPoints) {
   double risk = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100;
   
   double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minvolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double maxvolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double volumelimit = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
   
   double moneyPerLotstep = slPoints / ticksize * tickvalue * lotstep;
   double lots = MathFloor(risk / moneyPerLotstep) * lotstep;
   
   if(volumelimit != 0) lots = MathMin(lots, volumelimit);
   if(maxvolume != 0) lots = MathMin(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
   if(minvolume != 0) lots = MathMax(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
   lots = NormalizeDouble(lots, 2);
   
   return lots;
}

void CloseAllOrders() {
   
   for(int i = OrdersTotal()-1; i>=0; i--){
      ord.SelectByIndex(i);
      ulong ticket = ord.Ticket();
      if(ord.Symbol() == _Symbol && ord.Magic() == InpMagic){
         trade.OrderDelete(ticket);
      }
   
   }
}

void TrailStop(){
   
   double sl = 0;
   double tp = 0;
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   for(int i = PositionsTotal() -1; i >= 0; i--){
      if(pos.SelectByIndex(i)){
         ulong ticket = pos.Ticket();
         
         if (pos.Magic()==InpMagic && pos.Symbol()==_Symbol){
            if(pos.PositionType()==POSITION_TYPE_BUY){
               if(bid-pos.PriceOpen()>TslTriggerPoints*_Point){
                  tp = pos.TakeProfit();
                  sl = bid - (TslPoints * _Point);
                  
                  if (sl > pos.StopLoss() && sl != 0){
                     trade.PositionModify(ticket, sl, tp);
                  }
                  
               }
            }
            
            else if (pos.PositionType()==POSITION_TYPE_SELL) {
               if(ask+(TslTriggerPoints*_Point)<pos.PriceOpen()){
                  tp = pos.TakeProfit();
                  sl = ask + (TslPoints * _Point);
                  
                  if (sl < pos.StopLoss() && sl != 0) {
                     trade.PositionModify(ticket, sl, tp);
                  }
               }
            }
            
         }
         
         
      }
   }
}


bool IsUpcomingNews() {
   if(NewsFilterOn==false) return (false);
   
   if(TriDisabledNews && TimeCurrent()-LastNewsAvoided < StartTradingMin*PeriodSeconds(PERIOD_M1)) return true;
   
   TriDisabledNews=false;
   string sep;
   switch(separator){
      case 0: sep=",";break;
      case 1: sep=";";
   }
   
   sep_code = StringGetCharacter(sep, 0);
   
   int k = StringSplit(KeyNews, sep_code, NewsToAvoid);
   
   MqlCalendarValue values[];
   datetime starttime = TimeCurrent();  // iTime(_Symbol, Period_D1, 0);
   datetime endtime = starttime + PeriodSeconds(PERIOD_D1)*DaysNewsLookup;
   
   CalendarValueHistory(values,starttime,endtime,NULL, NULL);
   
   for(int i =0; i< ArraySize(values);i++){
      MqlCalendarEvent event;
      CalendarEventById(values[i].event_id, event);
      MqlCalendarCountry country;
      CalendarCountryById(event.country_id, country);
      
      if(StringFind(NewsCurrencies, country.currency) < 0) continue;
      
      for (int j =0; j<k; j++){
         string currentenvet = NewsToAvoid[j];
         string currentnews = event.name;
         if(StringFind(currentnews, currentenvet) < 0) continue;
         
         Comment("Next News: ", country.currency, ": ", event.name, " -> ", values[i].time);
         if(values[i].time - TimeCurrent() < StopBeforeMin*PeriodSeconds(PERIOD_M1)){
            LastNewsAvoided = values[i].time;
            TriDisabledNews = true;
            if (TradingEnabledComm=="" || TradingEnabledComm!="Printed"){
               TradingEnabledComm="Trading is disabled due to upcoming news: " + event.name;
            }
            return true;
         }
         return false;
         
               
       }
      
   }
   
     return false;
 }
 
 
 bool isRSIFilter() {
   
   if(RSIFilterOn==false) return false;
   
   double RSI[];
   
   CopyBuffer(handleRSI, MAIN_LINE,0, 1, RSI);
   ArraySetAsSeries(RSI, true);
   
   double RSInow = RSI[0];
   
   Comment("RSI = ", RSInow);
   
   if(RSInow>RSIUpperLvl || RSInow<RSILowerLvl){
      if(TradingEnabledComm=="" || TradingEnabledComm!="Printed"){
         TradingEnabledComm="Trading is disabled due to RSI filter";
      }
      return true;
   }
   return false;
   
 }

bool IsMAFilter(){
   if (MAFilterOn==false) return false;
   
   double MovAvg[];
   
   CopyBuffer(handleMovAvg, MAIN_LINE, 0, 1, MovAvg);
   ArraySetAsSeries(MovAvg, true);
   
   double MAnow = MovAvg[0];
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   if (ask > MAnow * (1 + PctPricefromMA/100) ||
      ask < MAnow * (1 - PctPricefromMA/100)
   )
   {
      if(TradingEnabledComm==""||TradingEnabledComm!="Printed"){
         TradingEnabledComm = "Trading is disabled due to Mov Avg Filter";
      }
      return true;
   }
   return false;
}