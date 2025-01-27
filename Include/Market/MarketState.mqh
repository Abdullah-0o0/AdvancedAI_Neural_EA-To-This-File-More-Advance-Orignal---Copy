struct MarketState
{
    datetime time;
    double price;
    double volume;
    double volatility;
    double momentum;
    double sentiment;
    bool isGoodTradeSetup;
    
    string ToJson()
    {
        string json = "{";
        json += "\"time\":\"" + TimeToString(time) + "\",";
        json += "\"price\":" + DoubleToString(price, 8) + ",";
        json += "\"volume\":" + DoubleToString(volume, 2) + ",";
        json += "\"volatility\":" + DoubleToString(volatility, 8) + ",";
        json += "\"momentum\":" + DoubleToString(momentum, 8) + ",";
        json += "\"sentiment\":" + DoubleToString(sentiment, 8) + ",";
        json += "\"setup\":" + (isGoodTradeSetup ? "true" : "false");
        json += "}";
        return json;
    }
    
    void FromJson(string json)
    {
        // JSON parsing implementation will be added later
    }
};

class MarketAnalyzer
{
public:
    static double CalculateMomentum(int period = 14)
    {
        double prices[];
        ArraySetAsSeries(prices, true);
        CopyClose(_Symbol, PERIOD_CURRENT, 0, period, prices);
        return ((prices[0] - prices[period-1]) / prices[period-1]) * 100;
    }
    
    static double CalculateVolatility(int period = 14)
    {
        double atr[];
        ArraySetAsSeries(atr, true);
        int handle = iATR(_Symbol, PERIOD_CURRENT, period);
        CopyBuffer(handle, 0, 0, 1, atr);
        IndicatorRelease(handle);
        return atr[0];
    }
    
    static double CalculateSentiment()
    {
        double rsi[], macd[];
        ArraySetAsSeries(rsi, true);
        ArraySetAsSeries(macd, true);
        
        int rsi_handle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
        int macd_handle = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
        
        CopyBuffer(rsi_handle, 0, 0, 1, rsi);
        CopyBuffer(macd_handle, 0, 0, 1, macd);
        
        IndicatorRelease(rsi_handle);
        IndicatorRelease(macd_handle);
        
        return (rsi[0] / 100 + macd[0]) / 2;
    }
};