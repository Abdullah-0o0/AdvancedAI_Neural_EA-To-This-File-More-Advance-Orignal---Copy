#property copyright "Advanced AI Trading System"
#property version   "2.00"

#include "../AI/Interfaces.mqh"

class CSentimentImpl : public CSentiment
{
private:
    double price_data[];
    double volume_data[];
    double momentum_data[];
    double rsi_data[];
    double macd_data[];
    
    void UpdatePriceData()
    {
        ArrayResize(price_data, window_size);
        for(int i = 0; i < window_size; i++)
        {
            price_data[i] = (double)iClose(_Symbol, PERIOD_CURRENT, i);
        }
    }
    
    void UpdateVolumeData()
    {
        ArrayResize(volume_data, window_size);
        for(int i = 0; i < window_size; i++)
        {
            volume_data[i] = (double)iVolume(_Symbol, PERIOD_CURRENT, i);
        }
    }
    
    void UpdateMomentumData()
    {
        ArrayResize(momentum_data, window_size);
        ArrayResize(rsi_data, window_size);
        ArrayResize(macd_data, window_size);
        
        int rsi_handle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
        int macd_handle = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
        
        for(int i = 0; i < window_size; i++)
        {
            momentum_data[i] = (double)iMomentum(_Symbol, PERIOD_CURRENT, 14, i);
            
            double rsi_buffer[];
            ArraySetAsSeries(rsi_buffer, true);
            CopyBuffer(rsi_handle, 0, i, 1, rsi_buffer);
            rsi_data[i] = rsi_buffer[0];
            
            double macd_buffer[];
            ArraySetAsSeries(macd_buffer, true);
            CopyBuffer(macd_handle, 0, i, 1, macd_buffer);
            macd_data[i] = macd_buffer[0];
        }
        
        IndicatorRelease(rsi_handle);
        IndicatorRelease(macd_handle);
    }
    
    double CalculatePriceSentiment()
    {
        double sentiment = 0;
        double weight = 1.0;
        double total_weight = 0;
        
        for(int i = 1; i < window_size; i++)
        {
            if(price_data[i] > price_data[i-1])
                sentiment += weight;
            else if(price_data[i] < price_data[i-1])
                sentiment -= weight;
                
            total_weight += weight;
            weight *= 0.95;
        }
        return sentiment / total_weight;
    }
    
    double CalculateVolumeSentiment()
    {
        double avg_volume = 0;
        double std_dev = 0;
        
        for(int i = 0; i < window_size; i++)
            avg_volume += volume_data[i];
        avg_volume /= window_size;
        
        for(int i = 0; i < window_size; i++)
            std_dev += MathPow(volume_data[i] - avg_volume, 2);
        std_dev = MathSqrt(std_dev / window_size);
        
        return (volume_data[0] - avg_volume) / (std_dev > 0 ? std_dev : 1);
    }
    
    double CalculateMomentumSentiment()
    {
        double momentum = 0;
        momentum += (momentum_data[0] - 100) / 100;
        momentum += (rsi_data[0] - 50) / 50;
        momentum += (macd_data[0] > 0 ? 1 : -1);
        return momentum / 3;
    }
    
    double CalculateTrendStrength()
    {
        int up_count = 0, down_count = 0;
        
        for(int i = 1; i < window_size; i++)
        {
            if(price_data[i] > price_data[i-1]) up_count++;
            if(price_data[i] < price_data[i-1]) down_count++;
        }
        
        return MathAbs((double)(up_count - down_count) / (window_size - 1));
    }

public:
    CSentimentImpl(): CSentiment()
    {
        UpdateSentimentData();
    }
    
    double GetMarketTrend() override
    {
        UpdateSentimentData();
        return CalculateTrendStrength();
    }
    
    double GetVolatilityIndex() override
    {
        double volatility = 0.0;
        for(int i = 1; i < window_size; i++)
        {
            volatility += MathAbs(price_data[i] - price_data[i-1]);
        }
        return volatility / (window_size - 1);
    }
    
    void UpdateSentimentData() override
    {
        UpdatePriceData();
        UpdateVolumeData();
        UpdateMomentumData();
    }
    
    double AnalyzeMarketSentiment() override
    {
        UpdateSentimentData();
        
        double price_sentiment = CalculatePriceSentiment();
        double volume_sentiment = CalculateVolumeSentiment();
        double momentum_sentiment = CalculateMomentumSentiment();
        double trend_strength = CalculateTrendStrength();
        
        return (price_sentiment * weight_price + 
                volume_sentiment * weight_volume + 
                momentum_sentiment * weight_momentum + 
                trend_strength * 0.1);
    }
};

CSentiment* new_CSentiment(void)
{
    return new CSentimentImpl();
}