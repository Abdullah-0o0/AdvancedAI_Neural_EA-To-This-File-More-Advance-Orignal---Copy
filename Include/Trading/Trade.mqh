#property copyright "Advanced AI Trading System"
#property version   "2.00"

#include "Strategy.mqh"
#include "../Market/MarketState.mqh"

class CTrade
{
private:
    CStrategy* strategy;
    double initial_balance;
    double current_drawdown;
    double max_drawdown;
    int consecutive_losses;
    int max_consecutive_losses;
    
    struct TradeStats
    {
        int total_trades;
        int winning_trades;
        int losing_trades;
        double profit_factor;
        double average_win;
        double average_loss;
        double largest_win;
        double largest_loss;
        double total_profit;
        
        void Reset()
        {
            total_trades = 0;
            winning_trades = 0;
            losing_trades = 0;
            profit_factor = 0;
            average_win = 0;
            average_loss = 0;
            largest_win = 0;
            largest_loss = 0;
            total_profit = 0;
        }
    } stats;
    
    void UpdateStats(double profit)
    {
        stats.total_trades++;
        stats.total_profit += profit;
        
        if(profit > 0)
        {
            stats.winning_trades++;
            stats.average_win = ((stats.average_win * (stats.winning_trades - 1)) + profit) / stats.winning_trades;
            stats.largest_win = MathMax(stats.largest_win, profit);
            consecutive_losses = 0;
        }
        else
        {
            stats.losing_trades++;
            stats.average_loss = ((stats.average_loss * (stats.losing_trades - 1)) + profit) / stats.losing_trades;
            stats.largest_loss = MathMin(stats.largest_loss, profit);
            consecutive_losses++;
            max_consecutive_losses = MathMax(max_consecutive_losses, consecutive_losses);
        }
        
        if(stats.losing_trades > 0)
            stats.profit_factor = (stats.average_win * stats.winning_trades) / (MathAbs(stats.average_loss) * stats.losing_trades);
            
        double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
        current_drawdown = (initial_balance - current_balance) / initial_balance * 100;
        max_drawdown = MathMax(max_drawdown, current_drawdown);
    }
    
    bool ValidateTradeConditions()
    {
        if(current_drawdown > 20 || consecutive_losses >= 5)
            return false;
            
        return true;
    }

public:
    CTrade(CStrategy* strat): 
        strategy(strat),
        initial_balance(AccountInfoDouble(ACCOUNT_BALANCE)),
        current_drawdown(0),
        max_drawdown(0),
        consecutive_losses(0),
        max_consecutive_losses(0)
    {
        stats.Reset();
    }
    
    bool ExecuteTrade()
    {
        if(!ValidateTradeConditions())
            return false;
            
        ENUM_TRADE_SIGNAL signal = strategy.GenerateSignal();
        return strategy.ExecuteSignal(signal);
    }
    
    void MonitorPositions()
    {
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            ulong ticket = PositionGetTicket(i);
            if(ticket <= 0) continue;
            
            if(PositionSelectByTicket(ticket))
            {
                double profit = PositionGetDouble(POSITION_PROFIT);
                if(profit != 0)
                    UpdateStats(profit);
            }
        }
    }
    
    string GetTradeStats()
    {
        string report = "Trade Statistics\n";
        report += "Total Trades: " + IntegerToString(stats.total_trades) + "\n";
        report += "Win Rate: " + DoubleToString(stats.winning_trades * 100.0 / (stats.total_trades > 0 ? stats.total_trades : 1), 2) + "%\n";
        report += "Profit Factor: " + DoubleToString(stats.profit_factor, 2) + "\n";
        report += "Max Drawdown: " + DoubleToString(max_drawdown, 2) + "%\n";
        report += "Current Drawdown: " + DoubleToString(current_drawdown, 2) + "%\n";
        report += "Max Consecutive Losses: " + IntegerToString(max_consecutive_losses) + "\n";
        report += "Total Profit: " + DoubleToString(stats.total_profit, 2);
        return report;
    }
};