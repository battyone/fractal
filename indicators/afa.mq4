//+------------------------------------------------------------------+
//|                                                          afa.mq4 |
//| Adaptive Fractal Analysis v1.1            Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.1"
#property strict
#include <MovingAverages.mqh>

//---
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   4

#property indicator_level1     1.5
#property indicator_maximum     1.65

#property indicator_color1 clrSaddleBrown   // 
#property indicator_color2 clrDarkSlateBlue 
#property indicator_color3 clrHotPink   // 
#property indicator_color4 clrCyan 
#property indicator_type1 DRAW_ARROW
#property indicator_type2 DRAW_ARROW
#property indicator_type3 DRAW_LINE
#property indicator_type4 DRAW_LINE

#property indicator_label1 "Correlation 1"
#property indicator_label2 "Correlation 2"
#property indicator_label3 "AFA1"
#property indicator_label4 "AFA2"
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 2
#property indicator_width4 2

//--- input parameter
input int length= 512;
input int order = 2;
input int scale1=64;
input int scale2=128;
input int MaPeriod=4;
input double corr_threshold=0.998;
double corr_level=1.35;

//--- buffers
#import "afa.dll"
int Create(int,int,int,int);
int Push(int,int,double,datetime,datetime);
bool Calculate(int,double &slope1,double &corr1,double &slope2,double &corr2); //
void Destroy(int);
#import


//--- 
int instance;
double AFA1MA[];
double AFA2MA[];
double AFA1[];
double AFA2[];
double CORR1[];
double CORR2[];
double CORR1MA[];
double CORR2MA[];
//---
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorBuffers(8); 
   SetIndexBuffer(0,CORR1MA);
   SetIndexBuffer(1,CORR2MA);
   SetIndexBuffer(2,AFA1MA);
   SetIndexBuffer(3,AFA2MA);
   SetIndexBuffer(4,CORR1);
   SetIndexBuffer(5,CORR2);
   SetIndexBuffer(6,AFA1);
   SetIndexBuffer(7,AFA2);
   SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexEmptyValue(2,0);
   SetIndexEmptyValue(3,0);
   SetIndexArrow(0,110);
   SetIndexArrow(1,110);

   instance=Create(length,order,scale1,scale2); //インスタンスを生成
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| De-initialization                                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0);
   Destroy(instance); //インスタンスを破棄
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

   if(ArrayGetAsSeries(close))ArraySetAsSeries(close,false);
   if(ArrayGetAsSeries(time))ArraySetAsSeries(time,false);
   if(ArrayGetAsSeries(AFA1MA))ArraySetAsSeries(AFA1MA,false);
   if(ArrayGetAsSeries(AFA2MA))ArraySetAsSeries(AFA2MA,false);
   if(ArrayGetAsSeries(AFA1))ArraySetAsSeries(AFA1,false);
   if(ArrayGetAsSeries(AFA2))ArraySetAsSeries(AFA2,false);
   if(ArrayGetAsSeries(CORR1MA))ArraySetAsSeries(CORR1MA,false);
   if(ArrayGetAsSeries(CORR2MA))ArraySetAsSeries(CORR2MA,false);
   if(ArrayGetAsSeries(CORR1))ArraySetAsSeries(CORR1,false);
   if(ArrayGetAsSeries(CORR2))ArraySetAsSeries(CORR2,false);

   for(int i=(int)MathMax(prev_calculated-1,0);i<rates_total && !IsStopped();i++)
     {
      datetime prev=(i>0) ? time[i-1]: 0;
      int n= Push(instance,i,close[i],time[i],prev);
      if(n == -1 )continue;
      if(n == -9999)
        {
         Print(i," ",time[i]);
         Print(n," ------------- Reset --------------- ",time[i]);
         Destroy(instance); //インスタンスを破棄
         instance=Create(length,order,scale1,scale2); //インスタンスを生成
         return 0;
        }
      if(rates_total-10000<i && i>1)
        {
         double fd1,fd2;
         double corr1,corr2;
         if(Calculate(instance,fd1,corr1,fd2,corr2))
           {
            double chk1 = (corr1 - corr_threshold);
            double chk2 = (corr2 - corr_threshold);
            AFA1[i-1]=2-fd1;
            AFA2[i-1]=2-fd2;
            CORR1[i-1]=chk1;
            CORR2[i-1]=chk2;
            if(i-1<=MaPeriod)
              {
               AFA1MA[i-1]=AFA1[i-1];
               AFA2MA[i-1]=AFA2[i-1];
            
              }
            else
              {
               AFA1MA[i-1]=SimpleMA(i-1,MaPeriod,AFA1);
               AFA2MA[i-1]=SimpleMA(i-1,MaPeriod,AFA2);
               double corr1ma=SimpleMA(i-1,MaPeriod,CORR1);
               double corr2ma=SimpleMA(i-1,MaPeriod,CORR2);
               CORR1MA[i-1]=(corr1ma >= 0)?corr_level+0.02:EMPTY_VALUE;
               CORR2MA[i-1]=(corr2ma >= 0)?corr_level:EMPTY_VALUE;
              }
           }
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
