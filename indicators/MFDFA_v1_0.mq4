//+------------------------------------------------------------------+
//|                                                   MFDFA_v1_0.mq4 |
//| MFDFA v1.0                                Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.0"
#property strict
#include <MovingAverages.mqh>

//---
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 clrCornflowerBlue   // 
#property indicator_color2 clrHotPink         // 

#property indicator_type1 DRAW_HISTOGRAM
#property indicator_type2 DRAW_LINE

#property indicator_width2 2

//--- input parameter
input int length = 1024;
input double scale_step = 1.0;
input int scale_min = 16; 
input int scale_max = 256;
input double q_step = 0.5; 
input double q_min = -10.0; 
input double q_max = 10.0;
input int MaPeriod=16;

//--- buffers
//--- i, q, Hq, tq, dq, hq))
#import "mfdfa_v1.dll"
   int Create( int,  double ,  int ,  int ,double , double, double); 
   int Push(int,int,double,datetime,datetime);//
   int Calculate (int); // 
   bool GetResults(int , unsigned int i, double &q, double &Hq, double &tq, double &Dq, double &hq);
   void Destroy(int); // 
#import


//--- 
int instance;
long ChNo=ChartID();
double WHQ[];
double WHQMA[];

//---
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   SetIndexBuffer(0,WHQ);
   SetIndexBuffer(1,WHQMA);
	instance = Create(length,scale_step,scale_min,scale_max,q_step,q_min,q_max); //インスタンスを生成
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
    if(ArrayGetAsSeries(WHQ))ArraySetAsSeries(WHQ,false);
    if(ArrayGetAsSeries(WHQMA))ArraySetAsSeries(WHQMA,false);
    
    for(int i=(int)MathMax(prev_calculated-1,0);i<rates_total && !IsStopped();i++)
     {
      datetime prev = (i>0) ? time[i-1]: 0;
      int n = Push(instance, i,close[i],time[i],prev);      
      if(n == -1 )continue;   
      if(n == -9999)
      {
         Print(i," ",time[i]);
         Print(n ," ------------- Reset --------------- ",time[i]);
      	Destroy(instance); //インスタンスを破棄
      	instance = Create(length,scale_step,scale_min,scale_max,q_step,q_min,q_max); //インスタンスを生成
      	return 0;      
      }
      
      int sz = Calculate(instance);
      
      double hq_max=0;
      double hq_min=0;
      
      for(int j=0;j<sz-1;j++)
      {
         double q,Hq,tq,Dq,hq;
         if (GetResults(instance, j,q,Hq,tq,Dq,hq))
         {
            if(j==0 || hq>hq_max)hq_max=hq;
            if(j==0 || hq<hq_min)hq_min=hq;
         }
      }
      WHQ[i]=hq_max-hq_min;      
      if(i<=MaPeriod)continue;
      WHQMA[i]=SimpleMA(i,MaPeriod,WHQ);

     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
