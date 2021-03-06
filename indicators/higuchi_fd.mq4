//+------------------------------------------------------------------+
//|                                                   Higuchi_FD.mq4 |
//| Higuchi's Fractgal Dimention              Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.1"
#property strict

//---
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_level1     1.5
#property indicator_maximum     2.0

#property indicator_color1 clrSaddleBrown    
#property indicator_color2 clrDarkSlateBlue 
#property indicator_color3 clrHotPink   
#property indicator_color4 clrCyan 
#property indicator_type1 DRAW_ARROW
#property indicator_type2 DRAW_ARROW
#property indicator_type3 DRAW_LINE
#property indicator_type4 DRAW_LINE

#property indicator_label1 "Correlation 1"
#property indicator_label2 "Correlation 2"
#property indicator_label3 "FD1"
#property indicator_label4 "FD2"
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 1
#property indicator_width4 1

//--- input parameter
input int length= 200;
input int k1 = 20;
input int k2 = 60;
input double corr_threshold=0.999;
double corr_level=1.0;

//--- buffers
//--- i, q, Hq, tq, dq, hq))
#import "fractal.dll"
int Create(int,int,int);
int Push(int,int,double,datetime,datetime);
bool Calculate(int,double &slope1,double &corr1,double &slope2,double &corr2); //
void Destroy(int);
#import


//--- 
int instance;
double HFD1[];
double HFD2[];
double CORR1SIG[];
double CORR2SIG[];
double CORR1[];
double CORR2[];
//---
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorBuffers(6); 
   
   SetIndexBuffer(0,CORR1SIG);
   SetIndexBuffer(1,CORR2SIG);
   SetIndexBuffer(2,HFD1);
   SetIndexBuffer(3,HFD2);
   SetIndexBuffer(4,CORR1);
   SetIndexBuffer(5,CORR2);
   SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexEmptyValue(2,0);
   SetIndexEmptyValue(3,0);
   SetIndexArrow(0,110);
   SetIndexArrow(1,110);
   
   instance=Create(length,k1,k2); //インスタンスを生成
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
   if(ArrayGetAsSeries(HFD1))ArraySetAsSeries(HFD1,false);
   if(ArrayGetAsSeries(HFD2))ArraySetAsSeries(HFD2,false);
   if(ArrayGetAsSeries(CORR1SIG))ArraySetAsSeries(CORR1SIG,false);
   if(ArrayGetAsSeries(CORR2SIG))ArraySetAsSeries(CORR2SIG,false);
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
         instance=Create(length,k1,k2); //インスタンスを生成
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
            HFD1[i-1]=fd1;
            HFD2[i-1]=fd2;
            CORR1SIG[i-1]=(chk1 >= 0)?corr_level+0.1 :EMPTY_VALUE;
            CORR2SIG[i-1]=(chk2 >= 0)?corr_level :EMPTY_VALUE;
            CORR1[i-1]=corr1;
            CORR2[i-1]=corr2;
           }
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
