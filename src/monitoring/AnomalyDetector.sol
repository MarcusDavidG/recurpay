// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AnomalyDetector {
    struct AnomalyThreshold {
        uint256 upperBound;
        uint256 lowerBound;
        uint256 sensitivity;
        bool active;
    }

    mapping(string => AnomalyThreshold) public thresholds;
    mapping(string => uint256[]) public dataPoints;
    mapping(string => uint256) public anomalyCount;

    event AnomalyDetected(string indexed metric, uint256 value, uint256 expectedRange);
    event ThresholdUpdated(string indexed metric, uint256 upper, uint256 lower);

    function setThreshold(
        string memory metric,
        uint256 upperBound,
        uint256 lowerBound,
        uint256 sensitivity
    ) external {
        thresholds[metric] = AnomalyThreshold({
            upperBound: upperBound,
            lowerBound: lowerBound,
            sensitivity: sensitivity,
            active: true
        });

        emit ThresholdUpdated(metric, upperBound, lowerBound);
    }

    function checkAnomaly(string memory metric, uint256 value) external returns (bool isAnomaly) {
        AnomalyThreshold memory threshold = thresholds[metric];
        require(threshold.active, "Threshold not set");

        dataPoints[metric].push(value);
        
        // Keep only last 50 data points
        if (dataPoints[metric].length > 50) {
            for (uint256 i = 0; i < 49; i++) {
                dataPoints[metric][i] = dataPoints[metric][i + 1];
            }
            dataPoints[metric].pop();
        }

        // Simple anomaly detection
        if (value > threshold.upperBound || value < threshold.lowerBound) {
            anomalyCount[metric]++;
            emit AnomalyDetected(metric, value, (threshold.upperBound + threshold.lowerBound) / 2);
            return true;
        }

        // Statistical anomaly detection using standard deviation
        if (dataPoints[metric].length >= 10) {
            uint256 mean = calculateMean(metric);
            uint256 stdDev = calculateStdDev(metric, mean);
            
            if (value > mean + (stdDev * threshold.sensitivity) || 
                value < mean - (stdDev * threshold.sensitivity)) {
                anomalyCount[metric]++;
                emit AnomalyDetected(metric, value, mean);
                return true;
            }
        }

        return false;
    }

    function calculateMean(string memory metric) internal view returns (uint256) {
        uint256[] memory points = dataPoints[metric];
        uint256 sum = 0;
        for (uint256 i = 0; i < points.length; i++) {
            sum += points[i];
        }
        return sum / points.length;
    }

    function calculateStdDev(string memory metric, uint256 mean) internal view returns (uint256) {
        uint256[] memory points = dataPoints[metric];
        uint256 sumSquaredDiff = 0;
        
        for (uint256 i = 0; i < points.length; i++) {
            uint256 diff = points[i] > mean ? points[i] - mean : mean - points[i];
            sumSquaredDiff += diff * diff;
        }
        
        return sqrt(sumSquaredDiff / points.length);
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function getAnomalyCount(string memory metric) external view returns (uint256) {
        return anomalyCount[metric];
    }
}
