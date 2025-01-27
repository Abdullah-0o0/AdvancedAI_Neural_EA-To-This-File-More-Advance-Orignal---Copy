#property copyright "Advanced AI Trading System"
#property version   "2.00"

#include "../AI/Interfaces.mqh"
#include "../Market/MarketState.mqh"

enum ENUM_TRADE_SIGNAL
{
    SIGNAL_NONE,
    SIGNAL_BUY,
    SIGNAL_SELL
};

class CStrategy
{
private:
    double risk_ratio;
    double profit_target;
    double stop_loss;
    int max_positions;
    double position_size;
    
    CNeuralNetwork* network;
    CSentiment* sentiment;
    
    double CalculatePositionSize(double risk)
    {
        double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        return (account_balance * risk) / (stop_loss * tick_value);
    }
    
    double CalculateStopLoss(ENUM_TRADE_SIGNAL signal, double entry_price)
    {
        double atr = MarketAnalyzer::CalculateVolatility();
        return signal == SIGNAL_BUY ? entry_price - (atr * 2) : entry_price + (atr * 2);
    }
    
    double CalculateTakeProfit(ENUM_TRADE_SIGNAL signal, double entry_price, double stop_loss)
    {
        double risk = MathAbs(entry_price - stop_loss);
        return signal == SIGNAL_BUY ? entry_price + (risk * profit_target) : entry_price - (risk * profit_target);
    }

public:
    CStrategy(CNeuralNetwork* net, CSentiment* sent):
        risk_ratio(0.02),
        profit_target(2.0),
        max_positions(3),
        network(net),
        sentiment(sent)
    {
    }
    
    ENUM_TRADE_SIGNAL GenerateSignal()
    {
        double direction = network.PredictDirection();
        double volatility = network.PredictVolatility();
        double market_sentiment = sentiment.AnalyzeMarketSentiment();
        
        if(direction > 0.7 && market_sentiment > 0.5 && volatility < 0.3)
            return SIGNAL_BUY;
            
        if(direction < 0.3 && market_sentiment < -0.5 && volatility < 0.3)
            return SIGNAL_SELL;
            
        return SIGNAL_NONE;
    }
    
    bool ExecuteSignal(ENUM_TRADE_SIGNAL signal)
    {
        if(signal == SIGNAL_NONE) return false;
        
        double entry_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        stop_loss = CalculateStopLoss(signal, entry_price);
        double take_profit = CalculateTakeProfit(signal, entry_price, stop_loss);
        position_size = CalculatePositionSize(risk_ratio);
        
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = _Symbol;
        request.volume = position_size;
        request.type = signal == SIGNAL_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        request.price = entry_price;
        request.sl = stop_loss;
        request.tp = take_profit;
        request.deviation = 5;
        request.type_filling = ORDER_FILLING_FOK;
        
        return OrderSend(request, result);
    }
    
    void SetRiskParameters(double risk, double profit_ratio, int max_pos)
    {
        risk_ratio = risk;
        profit_target = profit_ratio;
        max_positions = max_pos;
    }
};