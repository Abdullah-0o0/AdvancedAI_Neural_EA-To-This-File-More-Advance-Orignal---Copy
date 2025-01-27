#property copyright "Advanced AI Trading System"
#property version   "2.00"

#include "../AI/Interfaces.mqh"
#include "../Math/Tensor.mqh"
#include "../Market/MarketState.mqh"

class CNetworkLayer
{
private:
    int neurons;
    int input_size;
    double weights[];
    double biases[];
    double activations[];
    double layer_inputs[];  // Renamed from inputs to avoid conflict
    
public:
    CNetworkLayer(int input_count, int size): neurons(size), input_size(input_count)
    {
        ArrayResize(weights, size * input_count);
        ArrayResize(biases, size);
        ArrayResize(activations, size);
        ArrayResize(layer_inputs, input_count);
    }
    
    void Initialize()
    {
        for(int i = 0; i < neurons * input_size; i++)
        {
            weights[i] = 0.1 * (MathRand() - 16383.5) / 16383.5;
        }
        for(int i = 0; i < neurons; i++)
        {
            biases[i] = 0.1 * (MathRand() - 16383.5) / 16383.5;
        }
    }
    
    void Forward(const double& in[], double& out[])
    {
        ArrayResize(out, neurons);
        ArrayCopy(layer_inputs, in);
        
        for(int i = 0; i < neurons; i++)
        {
            activations[i] = biases[i];
            for(int j = 0; j < input_size; j++)
            {
                activations[i] += in[j] * weights[i * input_size + j];
            }
            out[i] = activations[i];
        }
    }
    
    void UpdateWeights(const double learn_rate, const double& errors[])  // Renamed parameter
    {
        for(int i = 0; i < neurons; i++)
        {
            for(int j = 0; j < input_size; j++)
            {
                weights[i * input_size + j] += learn_rate * errors[i] * layer_inputs[j];
            }
            biases[i] += learn_rate * errors[i];
        }
    }
};

class CNetworkImpl : public CNeuralNetwork
{
private:
    CNetworkLayer* input_layer;
    CNetworkLayer* hidden_layer;
    CNetworkLayer* output_layer;
    
    double last_prediction;
    double prediction_threshold;
    double momentum;
    double hidden_outputs[];
    double final_outputs[];
    
    double Activate(double x)
    {
        return 1.0 / (1.0 + MathExp(-x));
    }
    
    double ActivateDerivative(double x)
    {
        double fx = Activate(x);
        return fx * (1.0 - fx);
    }
    
public:
    CNetworkImpl(int inputs, int hidden, int outputs): CNeuralNetwork(inputs, hidden, outputs)
    {
        input_layer = new CNetworkLayer(inputs, hidden);
        hidden_layer = new CNetworkLayer(hidden, hidden);
        output_layer = new CNetworkLayer(hidden, outputs);
        
        prediction_threshold = 0.5;
        momentum = 0.9;
        last_prediction = 0;
        
        ArrayResize(hidden_outputs, hidden);
        ArrayResize(final_outputs, outputs);
    }
    
    ~CNetworkImpl()
    {
        delete input_layer;
        delete hidden_layer;
        delete output_layer;
    }
    
    void InitializeWeights() override
    {
        input_layer.Initialize();
        hidden_layer.Initialize();
        output_layer.Initialize();
    }
    
    double PredictDirection() override
    {
        double market_data[];
        GetMarketData(market_data);
        
        input_layer.Forward(market_data, hidden_outputs);
        for(int i = 0; i < ArraySize(hidden_outputs); i++)
            hidden_outputs[i] = Activate(hidden_outputs[i]);
            
        output_layer.Forward(hidden_outputs, final_outputs);
        last_prediction = Activate(final_outputs[0]);
        
        return last_prediction;
    }
    
    void Train(double &inputs[], double &outputs[]) override
    {
        // Forward pass
        input_layer.Forward(inputs, hidden_outputs);
        for(int i = 0; i < ArraySize(hidden_outputs); i++)
            hidden_outputs[i] = Activate(hidden_outputs[i]);
            
        output_layer.Forward(hidden_outputs, final_outputs);
        double predicted = Activate(final_outputs[0]);
        
        // Backpropagation
        double output_errors[];
        double hidden_errors[];
        ArrayResize(output_errors, 1);
        ArrayResize(hidden_errors, ArraySize(hidden_outputs));
        
        output_errors[0] = (outputs[0] - predicted) * ActivateDerivative(predicted);
        
        for(int i = 0; i < ArraySize(hidden_outputs); i++)
        {
            hidden_errors[i] = output_errors[0] * ActivateDerivative(hidden_outputs[i]);
        }
        
        output_layer.UpdateWeights(learning_rate, output_errors);
        hidden_layer.UpdateWeights(learning_rate, hidden_errors);
        input_layer.UpdateWeights(learning_rate, hidden_errors);
        
        learning_rate *= momentum;
        learning_rate = MathMax(learning_rate, 0.001);
    }
    
private:
    void GetMarketData(double &data[])
    {
        ArrayResize(data, 5);
        data[0] = iClose(_Symbol, PERIOD_CURRENT, 0);
        data[1] = iOpen(_Symbol, PERIOD_CURRENT, 0);
        data[2] = iHigh(_Symbol, PERIOD_CURRENT, 0);
        data[3] = iLow(_Symbol, PERIOD_CURRENT, 0);
        data[4] = iVolume(_Symbol, PERIOD_CURRENT, 0);
    }
};