// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionMetrics {
    mapping(string => uint256) public metrics;
    mapping(string => uint256[]) public historicalData;
    
    event MetricUpdated(string name, uint256 value);

    function updateMetric(string memory name, uint256 value) external {
        metrics[name] = value;
        historicalData[name].push(value);
        emit MetricUpdated(name, value);
    }

    function getMetric(string memory name) external view returns (uint256) {
        return metrics[name];
    }

    function getHistoricalData(string memory name) external view returns (uint256[] memory) {
        return historicalData[name];
    }
}
