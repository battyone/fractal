//+------------------------------------------------------------------+
//|                                        isokinetic_chart_v2_0.mq5 |
//| isokinetic chart v2.00                   Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//|                                                                  |
//| This code is a based on this article ↓↓↓                         | 
//|                              https://www.mql5.com/en/articles/60 |  
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "2.00"

#property indicator_separate_window
#property indicator_plots 1
#property indicator_buffers 5
#property indicator_type1 DRAW_COLOR_CANDLES
#property indicator_color1 clrLimeGreen,clrDarkOrange
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// Declaration of the enumeration
enum price_types
  {
   Bid,
   Ask
  };
input int ticks_in_candle=16; //Tick Count in Candles
input price_types applied_price=0; // Price
input string path_prefix=""; // FileName Prefix

input int resolution=20; //Tick Resolution(in Points) 
input int InpThreshold=150;  //Threshold(in Points) 

double reso=resolution*_Point;
double threshold=InpThreshold*_Point;

double prev_price=0;
int ticks_stored;

double TicksBuffer[],OpenBuffer[],HighBuffer[],LowBuffer[],CloseBuffer[],ColorIndexBuffer[];
//+------------------------------------------------------------------+
//| Indicator initialization function                                |
//+------------------------------------------------------------------+
void OnInit()
  {
// The OpenBuffer[] array is an indicator buffer
   SetIndexBuffer(0,OpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,CloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ColorIndexBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,TicksBuffer,INDICATOR_CALCULATIONS);
   ArraySetAsSeries(OpenBuffer,false);
   ArraySetAsSeries(HighBuffer,false);
   ArraySetAsSeries(LowBuffer,false);
   ArraySetAsSeries(CloseBuffer,false);
   ArraySetAsSeries(ColorIndexBuffer,false);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int file_handle,BidPosition,AskPosition,line_string_len,i;
   double last_price_bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   double last_price_ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);

   double last_price=(last_price_bid+last_price_ask)*0.5;
   if(fabs(last_price-prev_price)<reso)return(rates_total);
   prev_price=last_price;
   string filename,file_buffer;
   ArrayResize(TicksBuffer,ArraySize(CloseBuffer));
   StringConcatenate(filename,path_prefix,Symbol(),".txt");
   file_handle=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_ANSI|FILE_SHARE_READ);
   if(prev_calculated==0)
     {
      line_string_len=StringLen(FileReadString(file_handle))+2;
      if(FileSize(file_handle)>(ulong)line_string_len*rates_total/2)
        {
         FileSeek(file_handle,-line_string_len*rates_total/2,SEEK_END);
         FileReadString(file_handle);
        }
      else
        {
         FileSeek(file_handle,0,SEEK_SET);
        }
      ticks_stored=0;
      while(FileIsEnding(file_handle)==false)
        {
         file_buffer=FileReadString(file_handle);
         if(StringLen(file_buffer)>6)
           {
            BidPosition=StringFind(file_buffer," ",StringFind(file_buffer," ")+1)+1;
            AskPosition=StringFind(file_buffer," ",BidPosition)+1;
            if(applied_price==0) TicksBuffer[ticks_stored]=StringToDouble(StringSubstr(file_buffer,BidPosition,AskPosition-BidPosition-1));
            if(applied_price==1) TicksBuffer[ticks_stored]=StringToDouble(StringSubstr(file_buffer,AskPosition));
            ticks_stored++;
           }
        }
     }
   else
     {
      FileSeek(file_handle,0,SEEK_END);
      StringConcatenate(file_buffer,TimeCurrent()," ",DoubleToString(last_price_bid,_Digits)," ",DoubleToString(last_price_ask,_Digits));
      FileWrite(file_handle,file_buffer);
      if(applied_price==0) TicksBuffer[ticks_stored]=last_price_bid;
      if(applied_price==1) TicksBuffer[ticks_stored]=last_price_ask;
      ticks_stored++;
     }
// Closing the file
   FileClose(file_handle);
   if(ticks_stored>=rates_total)
     {
      for(i=ticks_stored/2;i<ticks_stored;i++)
        {
         TicksBuffer[i-ticks_stored/2]=TicksBuffer[i];
        }
      ticks_stored-=ticks_stored/2;
     }
   MqlRates rate;
   MqlRates wk[]; //キャンドル用のバッファ
   ArrayResize(wk,ticks_stored);
   int cnt=0;   // キャンドル数
   double accum_volat=0;  //ボラティリティをここに蓄積
   double last_close = TicksBuffer[0]; 
//---
   create_bar(rate,last_close);
//---
   for(i=0;i<ticks_stored;i++)
     {
      // 価格差を計算
      double diff=TicksBuffer[i]-last_close;
      double adiff=fabs(diff);
      int sign=(diff>0) -(diff<0);
      if(accum_volat+adiff<threshold) 
        {
         // ボラティリティが基準量に満たない場合
         update_bar(rate,TicksBuffer[i]);
         //---
         last_close=rate.close;
         accum_volat+=adiff;
        }
      else
        { 
         //ボラティリティが基準量を超えたのでバーを作る
         while(accum_volat+adiff>=threshold)
           {
            // 基準量ごとにバーを作る
            double decrease=(threshold-accum_volat);
            last_close=last_close+sign*decrease;
            //---
            update_bar(rate,last_close);
            //---
            accum_volat=0;
            adiff-=decrease;
            //output
            wk[cnt].open = rate.open;
            wk[cnt].high = rate.high;
            wk[cnt].low=rate.low;
            wk[cnt].close=rate.close;
            cnt++;
            //---
            create_bar(rate,last_close);
            //---
           }
        }
     }

//---
   ArrayInitialize(OpenBuffer,0);
   ArrayInitialize(HighBuffer,0);
   ArrayInitialize(LowBuffer,0);
   ArrayInitialize(CloseBuffer,0);
   ArrayInitialize(ColorIndexBuffer,0);
//---

   int ii=rates_total;
   for(int j=cnt-1;j>=0;j--)
     {
      OpenBuffer[ii-j-1]=wk[cnt-j-1].open;
      HighBuffer[ii-j-1]=wk[cnt-j-1].high;
      LowBuffer[ii-j-1]=wk[cnt-j-1].low;
      CloseBuffer[ii-j-1]=wk[cnt-j-1].close;
      ColorIndexBuffer[ii-j-1]=(CloseBuffer[ii-j-1]>=OpenBuffer[ii-j-1])?0:1;
     }
//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void create_bar(MqlRates &r,const double v)
  {
   r.open=v;
   r.low=v;
   r.high=v;
   r.close=v;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void update_bar(MqlRates &r,const double v)
  {
   if(r.low>v) r.low=v;
   if(r.high<v) r.high=v;
   r.close=v;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
