#property copyright "Advanced AI Trading System"
#property version   "2.00"

// Neural Network Interface
class CNeuralNetwork
{
protected:
    int input_size;
    int hidden_size;
    int output_size;
    double learning_rate;
    double m_momentum;  // renamed to avoid conflicts
    double dropout_rate;
    
public:
    CNeuralNetwork(int inputs, int hidden, int outputs): 
        input_size(inputs), 
        hidden_size(hidden), 
        output_size(outputs),
        learning_rate(0.01),
        m_momentum(0.9),
        dropout_rate(0.2) {}
        
    virtual void InitializeWeights(void) = 0;
    virtual double PredictDirection(void) = 0;
    virtual double PredictVolatility(void) = 0;
    virtual void Train(double &inputs[], double &outputs[]) = 0;
    virtual void SaveModel(string filename) = 0;
    virtual bool LoadModel(string filename) = 0;
    
    void SetLearningRate(double rate) { learning_rate = rate; }
    double GetLearningRate(void) { return learning_rate; }
    void SetMomentum(double m) { m_momentum = m; }
    void SetDropoutRate(double rate) { dropout_rate = rate; }
};

// Tensor Operations Interface
class CTensor
{
protected:
    double m_data[];
    int m_dimensions[];
    bool m_is_normalized;
    
public:
    CTensor(void): m_is_normalized(false) {}
    
    virtual void CreateFeatureMatrix(double &features[]) = 0;
    virtual void ProcessData(double &input_data[]) = 0;
    virtual double GetValue(int index) = 0;
    virtual void Normalize(void) = 0;
    virtual void Reshape(int &new_dimensions[]) = 0;
    
    bool IsNormalized(void) { return m_is_normalized; }
    int GetDimension(int index) { return m_dimensions[index]; }
};

// Market Sentiment Analysis Interface
class CSentiment
{
protected:
    double sentiment_data[];
    int window_size;
    double threshold;
    double weight_price;
    double weight_volume;
    double weight_momentum;
    
public:
    CSentiment(void): 
        window_size(14),
        threshold(0.5),
        weight_price(0.4),
        weight_volume(0.3),
        weight_momentum(0.3) {}
        
    virtual double AnalyzeMarketSentiment(void) = 0;
    virtual void UpdateSentimentData(void) = 0;
    virtual double GetMarketTrend(void) = 0;
    virtual double GetVolatilityIndex(void) = 0;
    
    void SetWindowSize(int size) { window_size = size; }
    int GetWindowSize(void) { return window_size; }
    void SetThreshold(double value) { threshold = value; }
    void SetWeights(double price, double volume, double momentum)
    {
        weight_price = price;
        weight_volume = volume;
        weight_momentum = momentum;
    }
};