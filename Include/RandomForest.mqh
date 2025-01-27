class CRandomForest
{
public:
    bool IsActive();
    double GetAccuracy();
    void RebalanceTrees();
    void PruneWeakTrees();
    double GetEnsemblePrediction();
    bool NeedsRebalancing();
};