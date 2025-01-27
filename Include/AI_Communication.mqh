#property copyright "Advanced AI Trading System"
#property version   "2.00"

class CAICommunication
{
private:
    bool enabled;
    int last_message_time;
    string logFile;
    
    void ExecuteCommand(string command)
    {
        string parts[];
        StringSplit(command, ' ', parts);
        
        if(ArraySize(parts) < 1) return;
        
        if(parts[0] == "LEARN")
        {
            SendMessage("Starting learning process...", 1);
            LogSystemEvent("LEARNING", "Manual learning initiated");
        }
        else if(parts[0] == "STATUS")
        {
            SendMessage("AI System Status: Active", 1);
            LogSystemEvent("STATUS", "Status check requested");
        }
        else if(parts[0] == "STOP")
        {
            SendMessage("Stopping AI operations...", 2);
            LogSystemEvent("SYSTEM", "Stop command received");
            enabled = false;
        }
        else if(parts[0] == "START")
        {
            enabled = true;
            SendMessage("AI operations resumed", 2);
            LogSystemEvent("SYSTEM", "Start command received");
        }
        else
        {
            SendMessage("Unknown command: " + command, 1);
            LogSystemEvent("ERROR", "Unknown command received: " + command);
        }
    }

public:
    CAICommunication() 
    { 
        enabled = true;
        logFile = "Memory\\system_log.txt";
    }
    
    void Initialize()
    {
        enabled = true;
        last_message_time = 0;
    }
    
    void SendMessage(string message, int priority)
    {
        if(!enabled) return;
        
        string prefix = "";
        switch(priority)
        {
            case 1: prefix = "[INFO] "; break;
            case 2: prefix = "[WARN] "; break;
            case 3: prefix = "[ERROR] "; break;
            default: prefix = "[DEBUG] ";
        }
        
        Print(prefix, message);
        
        if(priority >= 2)
            SendNotification(prefix + message);
    }
    
    void LogSystemEvent(string event_type, string details)
    {
        if(!enabled) return;
        
        string timestamp = TimeToString(TimeCurrent());
        string logEntry = StringFormat("%s [%s] %s", timestamp, event_type, details);
        
        int handle = FileOpen(logFile, FILE_WRITE|FILE_TXT|FILE_ANSI);
        if(handle != INVALID_HANDLE)
        {
            FileSeek(handle, 0, SEEK_END);
            FileWriteString(handle, logEntry + "\n");
            FileClose(handle);
        }
    }
    
    void EnableMessages(bool enable) { enabled = enable; }
};