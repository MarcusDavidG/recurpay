// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PredictiveAnalytics {
    struct PredictionModel {
        uint256[] historicalData;
        uint256 accuracy;
        uint256 lastUpdate;
        bool active;
    }

    mapping(address => mapping(string => PredictionModel)) public models;
    mapping(address => string[]) public creatorModels;

    event ModelCreated(address indexed creator, string modelType);
    event PredictionMade(address indexed creator, string modelType, uint256 prediction);

    function createModel(string memory modelType) external {
        models[msg.sender][modelType] = PredictionModel({
            historicalData: new uint256[](0),
            accuracy: 0,
            lastUpdate: block.timestamp,
            active: true
        });

        creatorModels[msg.sender].push(modelType);
        emit ModelCreated(msg.sender, modelType);
    }

    function updateModel(string memory modelType, uint256[] memory newData) external {
        PredictionModel storage model = models[msg.sender][modelType];
        require(model.active, "Model not active");

        for (uint256 i = 0; i < newData.length; i++) {
            model.historicalData.push(newData[i]);
        }
        model.lastUpdate = block.timestamp;
    }

    function makePrediction(string memory modelType, uint256 periods) external view returns (uint256) {
        PredictionModel storage model = models[msg.sender][modelType];
        require(model.active, "Model not active");
        require(model.historicalData.length >= 3, "Insufficient data");

        // Simple linear regression prediction
        uint256 dataLength = model.historicalData.length;
        uint256 recent = model.historicalData[dataLength - 1];
        uint256 previous = model.historicalData[dataLength - 2];
        
        if (recent > previous) {
            uint256 growth = recent - previous;
            return recent + (growth * periods);
        } else {
            uint256 decline = previous - recent;
            return recent > decline * periods ? recent - (decline * periods) : 0;
        }
    }

    function getModelAccuracy(address creator, string memory modelType) external view returns (uint256) {
        return models[creator][modelType].accuracy;
    }
}
