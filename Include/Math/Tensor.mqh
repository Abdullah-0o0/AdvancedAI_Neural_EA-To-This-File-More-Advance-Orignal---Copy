#property copyright "Advanced AI Trading System"
#property version   "2.00"

#include "../AI/Interfaces.mqh"

enum ENUM_TENSOR_ACTIVATION
{
    TA_TANH,
    TA_RELU,
    TA_SIGMOID
};

class CTensorImpl : public CTensor
{
private:
    int matrix_size;
    double feature_matrix[];
    double mean[];
    double std_dev[];
    
    void StandardizeData()
    {
        ArrayResize(mean, m_dimensions[0]);
        ArrayResize(std_dev, m_dimensions[0]);
        
        for(int feature = 0; feature < m_dimensions[0]; feature++)
        {
            double sum = 0, sum_sq = 0;
            for(int i = 0; i < m_dimensions[1]; i++)
            {
                int idx = i * m_dimensions[0] + feature;
                sum += feature_matrix[idx];
                sum_sq += feature_matrix[idx] * feature_matrix[idx];
            }
            
            mean[feature] = sum / m_dimensions[1];
            std_dev[feature] = MathSqrt(sum_sq/m_dimensions[1] - mean[feature]*mean[feature]);
            
            for(int i = 0; i < m_dimensions[1]; i++)
            {
                int idx = i * m_dimensions[0] + feature;
                if(std_dev[feature] > 0)
                    feature_matrix[idx] = (feature_matrix[idx] - mean[feature]) / std_dev[feature];
            }
        }
    }
    
    void ApplyActivation(double &arr[], ENUM_TENSOR_ACTIVATION func)
    {
        int size = ArraySize(arr);
        for(int i = 0; i < size; i++)
        {
            switch(func)
            {
                case TA_TANH:
                    arr[i] = MathTanh(arr[i]);
                    break;
                case TA_RELU:
                    arr[i] = MathMax(0, arr[i]);
                    break;
                case TA_SIGMOID:
                    arr[i] = 1.0 / (1.0 + MathExp(-arr[i]));
                    break;
            }
        }
    }

public:
    CTensorImpl(): CTensor()
    {
        matrix_size = 0;
        ArrayResize(m_dimensions, 3);
        m_dimensions[0] = 10;  // Features
        m_dimensions[1] = 20;  // Time steps
        m_dimensions[2] = 1;   // Batch size
    }
    
    void CreateFeatureMatrix(double &features[]) override
    {
        matrix_size = ArraySize(features);
        ArrayResize(feature_matrix, matrix_size);
        ArrayCopy(feature_matrix, features);
        StandardizeData();
    }
    
    void ProcessData(double &input_data[]) override
    {
        int size = ArraySize(input_data);
        ArrayResize(m_data, size);
        ArrayCopy(m_data, input_data);
        
        for(int i = 0; i < m_dimensions[0] && i < size; i++)
        {
            if(std_dev[i] > 0)
                m_data[i] = (m_data[i] - mean[i]) / std_dev[i];
        }
        
        ApplyActivation(m_data, TA_TANH);
    }
    
    void Normalize() override
    {
        StandardizeData();
        m_is_normalized = true;
    }
    
    void Reshape(int& new_dimensions[]) override
    {
        if(ArraySize(new_dimensions) >= 3)
        {
            Reshape(new_dimensions[0], new_dimensions[1], new_dimensions[2]);
        }
    }
    
    double GetValue(int index) override
    {
        if(index >= 0 && index < ArraySize(m_data))
            return m_data[index];
        return 0.0;
    }
    
    double GetFeatureValue(int index)
    {
        if(index >= 0 && index < matrix_size)
            return feature_matrix[index];
        return 0.0;
    }
    
    void Reshape(int features, int timesteps, int batch_size)
    {
        m_dimensions[0] = features;
        m_dimensions[1] = timesteps;
        m_dimensions[2] = batch_size;
        matrix_size = features * timesteps * batch_size;
        ArrayResize(feature_matrix, matrix_size);
    }
};

// Factory function
CTensor* new_CTensor(void)
{
    return new CTensorImpl();
}