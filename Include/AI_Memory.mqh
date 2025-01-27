#property copyright "Advanced AI Trading System"
#property version   "2.00"

#include "/Market/MarketState.mqh"

class CAIMemory
{
private:
    struct MemoryRecord
    {
        datetime time;
        double price;
        double prediction;
        double actual;
        double error;
        bool success;
    };
    
    MemoryRecord memory[];
    int max_records;
    string memory_file;
    double total_error;
    int record_count;
    
public:
    CAIMemory(int max_size = 1000)
    {
        max_records = max_size;
        memory_file = "Memory\\trading_memory.json";
        total_error = 0;
        record_count = 0;
        ArrayResize(memory, 0);
        LoadMemory();
    }
    
    void StoreState(datetime time, double price, double prediction)
    {
        if(ArraySize(memory) >= max_records)
            ArrayRemove(memory, 0, 1);
            
        int size = ArraySize(memory);
        ArrayResize(memory, size + 1);
        
        memory[size].time = time;
        memory[size].price = price;
        memory[size].prediction = prediction;
        memory[size].actual = 0;
        memory[size].error = 0;
        memory[size].success = false;
        
        SaveMemory();
    }
    
    void GetRecentData(datetime& times[], double& prices[], int count)
    {
        int size = MathMin(count, ArraySize(memory));
        ArrayResize(times, size);
        ArrayResize(prices, size);
        
        for(int i = 0; i < size; i++)
        {
            times[i] = memory[ArraySize(memory) - size + i].time;
            prices[i] = memory[ArraySize(memory) - size + i].price;
        }
    }

private:
    void LoadMemory()
    {
        if(FileIsExist(memory_file))
        {
            int handle = FileOpen(memory_file, FILE_READ|FILE_TXT);
            if(handle != INVALID_HANDLE)
            {
                while(!FileIsEnding(handle))
                {
                    string line = FileReadString(handle);
                    ParseAndAddRecord(line);
                }
                FileClose(handle);
            }
        }
    }
    
    void SaveMemory()
    {
        int handle = FileOpen(memory_file, FILE_WRITE|FILE_TXT);
        if(handle != INVALID_HANDLE)
        {
            for(int i = 0; i < ArraySize(memory); i++)
            {
                string record_json = RecordToJson(memory[i]);
                FileWriteString(handle, record_json + "\n");
            }
            FileClose(handle);
        }
    }
    
    string RecordToJson(MemoryRecord &record)
    {
        string json = "{";
        json += "\"time\":\"" + TimeToString(record.time) + "\",";
        json += "\"price\":" + DoubleToString(record.price, 8) + ",";
        json += "\"prediction\":" + DoubleToString(record.prediction, 8) + ",";
        json += "\"actual\":" + DoubleToString(record.actual, 8) + ",";
        json += "\"error\":" + DoubleToString(record.error, 8) + ",";
        json += "\"success\":" + (record.success ? "true" : "false");
        json += "}";
        return json;
    }
    
    void ParseAndAddRecord(string json)
    {
        if(StringLen(json) < 10) return;
        
        MemoryRecord record;
        record.time = StringToTime(ExtractValue(json, "time"));
        record.price = StringToDouble(ExtractValue(json, "price"));
        record.prediction = StringToDouble(ExtractValue(json, "prediction"));
        record.actual = StringToDouble(ExtractValue(json, "actual"));
        record.error = StringToDouble(ExtractValue(json, "error"));
        record.success = StringFind(json, "\"success\":true") >= 0;
        
        int size = ArraySize(memory);
        ArrayResize(memory, size + 1);
        memory[size] = record;
    }
    
    string ExtractValue(string json, string key)
    {
        string search = "\"" + key + "\":";
        int pos = StringFind(json, search);
        if(pos >= 0)
        {
            int start = pos + StringLen(search);
            int end = StringFind(json, ",", start);
            if(end < 0) end = StringFind(json, "}", start);
            if(end < 0) return "";
            
            string value = StringSubstr(json, start, end - start);
            StringTrimLeft(value);
            StringTrimRight(value);
            return value;
        }
        return "";
    }
};