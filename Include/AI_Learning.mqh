#property copyright "Advanced AI Trading System"
#property version   "2.00"

#include "/Market/MarketState.mqh"

class CAILearning
{
private:
    struct Pattern
    {
        double priceAction[];
        double volume[];
        double momentum[];
        bool successful;
    };
    
    Pattern patterns[];
    double learning_rate;
    double momentum_rate;
    double success_threshold;
    string learning_file;
    
public:
    CAILearning()
    {
        learning_file = "Memory\\learning_progress.json";
        learning_rate = 0.001;
        momentum_rate = 0.9;
        success_threshold = 0.6;
        LoadPatterns();
    }
    
    void Initialize()
    {
        ArrayResize(patterns, 0);
        LoadPatterns();
    }
    
    double GetSuccessRate()
    {
        int successful = 0;
        int total = ArraySize(patterns);
        
        for(int i = 0; i < total; i++)
        {
            if(patterns[i].successful) successful++;
        }
        
        return total > 0 ? (double)successful/total : 0.5;
    }
    
    void AddPattern(const double &price[], const double &vol[], const double &mom[], bool success)
    {
        int size = ArraySize(patterns);
        ArrayResize(patterns, size + 1);
        
        ArrayCopy(patterns[size].priceAction, price);
        ArrayCopy(patterns[size].volume, vol);
        ArrayCopy(patterns[size].momentum, mom);
        patterns[size].successful = success;
        
        SavePatterns();
    }
    
    double AnalyzePattern(const double &current_price[], const double &current_vol[], const double &current_mom[])
    {
        double max_similarity = 0;
        double weighted_prediction = 0;
        int pattern_count = 0;
        
        for(int i = 0; i < ArraySize(patterns); i++)
        {
            double similarity = CalculateSimilarity(current_price, current_vol, current_mom, i);
            if(similarity > success_threshold)
            {
                weighted_prediction += similarity * (patterns[i].successful ? 1 : -1);
                pattern_count++;
                max_similarity = MathMax(max_similarity, similarity);
            }
        }
        
        return pattern_count > 0 ? weighted_prediction/pattern_count : 0;
    }
    
    void UpdateWeights(double error)
    {
        learning_rate *= (1.0 - error * momentum_rate);
        learning_rate = MathMax(learning_rate, 0.0001);
    }

private:
    void LoadPatterns()
    {
        if(FileIsExist(learning_file))
        {
            int handle = FileOpen(learning_file, FILE_READ|FILE_TXT);
            if(handle != INVALID_HANDLE)
            {
                while(!FileIsEnding(handle))
                {
                    string line = FileReadString(handle);
                    ParseAndAddPattern(line);
                }
                FileClose(handle);
            }
        }
    }
    
    void SavePatterns()
    {
        int handle = FileOpen(learning_file, FILE_WRITE|FILE_TXT);
        if(handle != INVALID_HANDLE)
        {
            for(int i = 0; i < ArraySize(patterns); i++)
            {
                string pattern_json = PatternToJson(patterns[i]);
                FileWriteString(handle, pattern_json + "\n");
            }
            FileClose(handle);
        }
    }
    
    double CalculateSimilarity(const double &price[], const double &vol[], const double &mom[], int pattern_index)
    {
        double price_sim = CalculateArraySimilarity(price, patterns[pattern_index].priceAction);
        double vol_sim = CalculateArraySimilarity(vol, patterns[pattern_index].volume);
        double mom_sim = CalculateArraySimilarity(mom, patterns[pattern_index].momentum);
        
        return (price_sim * 0.5 + vol_sim * 0.3 + mom_sim * 0.2);
    }
    
    double CalculateArraySimilarity(const double &arr1[], const double &arr2[])
    {
        int size = MathMin(ArraySize(arr1), ArraySize(arr2));
        if(size == 0) return 0;
        
        double diff_sum = 0;
        for(int i = 0; i < size; i++)
        {
            diff_sum += MathAbs(arr1[i] - arr2[i]);
        }
        
        return 1.0 - (diff_sum / size);
    }
    
    string PatternToJson(Pattern &pattern)
    {
        string json = "{";
        json += "\"successful\":" + (pattern.successful ? "true" : "false") + ",";
        json += "\"priceAction\":" + ArrayToString(pattern.priceAction) + ",";
        json += "\"volume\":" + ArrayToString(pattern.volume) + ",";
        json += "\"momentum\":" + ArrayToString(pattern.momentum);
        json += "}";
        return json;
    }
    
    string ArrayToString(double &arr[])
    {
        string result = "[";
        for(int i = 0; i < ArraySize(arr); i++)
        {
            if(i > 0) result += ",";
            result += DoubleToString(arr[i], 8);
        }
        result += "]";
        return result;
    }
    
    void ParseAndAddPattern(string json)
    {
        // Basic JSON parsing implementation
        // This would need to be expanded based on your JSON structure
        if(StringFind(json, "\"successful\":true") >= 0)
        {
            Pattern pattern;
            pattern.successful = true;
            // Parse arrays and add pattern
            int size = ArraySize(patterns);
            ArrayResize(patterns, size + 1);
            patterns[size] = pattern;
        }
    }
};