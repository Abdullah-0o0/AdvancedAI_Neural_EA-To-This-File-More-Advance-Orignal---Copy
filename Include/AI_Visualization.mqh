#include "/Market/MarketState.mqh"

class CAIVisualization
{
private:
    string prefix;
    color buyColor;
    color sellColor;
    color predictionColor;
    
public:
    CAIVisualization()
    {
        prefix = "AI_Visual_";
        buyColor = clrGreen;
        sellColor = clrRed;
        predictionColor = clrBlue;
    }
    
    void InitializeChartObjects()
    {
        ClearOldObjects();
        CreatePredictionPanel();
    }
    
    void ShowPrediction(double prediction, double price)
    {
        string name = prefix + "Prediction";
        ObjectCreate(0, name, OBJ_ARROW, 0, TimeCurrent(), price);
        ObjectSetInteger(0, name, OBJPROP_ARROWCODE, prediction > 0.5 ? 233 : 234);
        ObjectSetInteger(0, name, OBJPROP_COLOR, predictionColor);
    }
    
    void MarkEntry(string type, double price)
    {
        string name = prefix + "Entry_" + TimeToString(TimeCurrent());
        ObjectCreate(0, name, OBJ_ARROW, 0, TimeCurrent(), price);
        ObjectSetInteger(0, name, OBJPROP_ARROWCODE, type == "Buy" ? 241 : 242);
        ObjectSetInteger(0, name, OBJPROP_COLOR, type == "Buy" ? buyColor : sellColor);
    }
    
    void DrawTrendLines(const MarketState& state)
    {
        DrawSupportResistance(state.price);
        DrawTrendChannel();
    }
    
    void ShowPredictionLevels(double &levels[])
    {
        for(int i = 0; i < ArraySize(levels); i++)
        {
            string name = prefix + "Level_" + IntegerToString(i);
            ObjectCreate(0, name, OBJ_HLINE, 0, 0, levels[i]);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, name, OBJPROP_COLOR, predictionColor);
        }
    }
    
    void UpdateTradeMarkers()
    {
        UpdateActiveTradeMarkers();
        CleanOldMarkers();
    }
    
    void ClearOldObjects()
    {
        ObjectsDeleteAll(0, prefix);
    }
    
    void ShowAnalysis(double trend, double strength, double quality)
    {
        ShowAnalysisPanel(trend, strength, quality);
    }
    
private:
    void CreatePredictionPanel()
    {
        string name = prefix + "Panel";
        ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 20);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20);
        ObjectSetInteger(0, name, OBJPROP_XSIZE, 200);
        ObjectSetInteger(0, name, OBJPROP_YSIZE, 100);
        ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrBlack);
        ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrWhite);
    }
    
    void DrawSupportResistance(double price)
    {
        double levels[];
        CalculateSR(levels, price);
        
        for(int i = 0; i < ArraySize(levels); i++)
        {
            string name = prefix + "SR_" + IntegerToString(i);
            ObjectCreate(0, name, OBJ_HLINE, 0, 0, levels[i]);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrGray);
        }
    }
    
    void DrawTrendChannel()
    {
        double upper, lower;
        CalculateTrendChannel(upper, lower);
        
        ObjectCreate(0, prefix + "TrendUpper", OBJ_TREND, 0, 
                    iTime(_Symbol, PERIOD_CURRENT, 20), upper,
                    TimeCurrent(), upper + (upper - lower)/2);
                    
        ObjectCreate(0, prefix + "TrendLower", OBJ_TREND, 0,
                    iTime(_Symbol, PERIOD_CURRENT, 20), lower,
                    TimeCurrent(), lower - (upper - lower)/2);
    }
    
    void UpdateActiveTradeMarkers()
    {
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            if(PositionSelectByTicket(PositionGetTicket(i)))
            {
                string name = prefix + "Position_" + IntegerToString(PositionGetTicket(i));
                if(!ObjectFind(0, name))
                {
                    ObjectCreate(0, name, OBJ_ARROW, 0, 
                               PositionGetInteger(POSITION_TIME),
                               PositionGetDouble(POSITION_PRICE_OPEN));
                }
            }
        }
    }
    
    void CleanOldMarkers()
    {
        datetime oldestValidTime = TimeCurrent() - PeriodSeconds(PERIOD_D1);
        for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
        {
            string name = ObjectName(0, i);
            if(StringFind(name, prefix) == 0)
            {
                datetime objTime = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME);
                if(objTime < oldestValidTime)
                {
                    ObjectDelete(0, name);
                }
            }
        }
    }
    
    void ShowAnalysisPanel(double trend, double strength, double quality)
    {
        string name = prefix + "Analysis";
        string text = "Market Analysis\n";
        text += "Trend: " + DoubleToString(trend * 100, 1) + "%\n";
        text += "Strength: " + DoubleToString(strength * 100, 1) + "%\n";
        text += "Quality: " + DoubleToString(quality * 100, 1) + "%";
        
        ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 20);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 140);
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
    }
    
    void CalculateSR(double &levels[], double price)
    {
        ArrayResize(levels, 4);
        double atr = iATR(_Symbol, PERIOD_CURRENT, 14);
        levels[0] = price + atr * 2;
        levels[1] = price + atr;
        levels[2] = price - atr;
        levels[3] = price - atr * 2;
    }
    
    void CalculateTrendChannel(double &upper, double &lower)
    {
        double high[], low[];
        ArraySetAsSeries(high, true);
        ArraySetAsSeries(low, true);
        
        CopyHigh(_Symbol, PERIOD_CURRENT, 0, 20, high);
        CopyLow(_Symbol, PERIOD_CURRENT, 0, 20, low);
        
        upper = high[ArrayMaximum(high, 0, 20)];
        lower = low[ArrayMinimum(low, 0, 20)];
    }