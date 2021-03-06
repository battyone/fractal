//+------------------------------------------------------------------+
//|                                                        MFDFA.mq4 |
//| MFDFA                                     Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.0"
#property strict

//---
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_level1     0.5
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
#property indicator_color1 Red          // 
#property indicator_color2 Blue         // 
#property indicator_color3 SandyBrown   // 
#property indicator_color4 Thistle      // 
#property indicator_color5 Lime         // 

#property indicator_type1 DRAW_LINE
#property indicator_type2 DRAW_LINE
#property indicator_type3 DRAW_LINE
#property indicator_type4 DRAW_LINE
#property indicator_type5 DRAW_LINE

//--- input parameter
input int length = 2048;
input double scale_step = 1.0;
input int scale_min = 16; 
input int scale_max = 256;
double q_step = 0.5; 
double q_min = -1.0; 
double q_max = 1.0;
//--- buffers
//---
#import "mfdfa.dll"
   int Create( int,  double ,  int ,  int ,double , double, double); 
   int Push(int,int,double,datetime,datetime);//
   int Calculate (int); // 
   bool GetResults(int , unsigned int i, double &q, double &a, double &v);
   void Destroy(int); // 
#import


//--- 
int instance;
long ChNo=ChartID();
double Q1[];
double Q2[];
double Q3[];
double Q4[];
double Q5[];

//---
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   SetIndexBuffer(0,Q1);
   SetIndexBuffer(1,Q2);
   SetIndexBuffer(2,Q3);
   SetIndexBuffer(3,Q4);
   SetIndexBuffer(4,Q5);
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
    if(ArrayGetAsSeries(Q1))ArraySetAsSeries(Q1,false);
    if(ArrayGetAsSeries(Q2))ArraySetAsSeries(Q2,false);
    if(ArrayGetAsSeries(Q3))ArraySetAsSeries(Q3,false);
    if(ArrayGetAsSeries(Q4))ArraySetAsSeries(Q4,false);
    if(ArrayGetAsSeries(Q5))ArraySetAsSeries(Q5,false);

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
      
      //if(i<rates_total-2)continue;
      int sz = Calculate(instance);
      
      for(int j=0;j<sz;j++)
      {
         double q,a,v;
         if (GetResults(instance, j,q,a,v))
         {
            if(j==0)Q1[i]=a; 
            if(j==1)Q2[i]=a; 
            if(j==2)Q3[i]=a; 
            if(j==3)Q4[i]=a; 
            if(j==4)Q5[i]=a; 
         }
      }
        
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
