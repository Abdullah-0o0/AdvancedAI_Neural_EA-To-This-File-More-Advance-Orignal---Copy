class CLSTM
{
public:
    bool IsActive();
    double GetAccuracy();
    void UpdateWeights(double& data[]);
    void ValidateAccuracy();
    bool NeedsUpdate();
    double GenerateSignal();
};