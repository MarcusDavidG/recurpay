// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionProfiler {
    struct ProfileData {
        string functionName;
        uint256 gasUsed;
        uint256 executionTime;
        uint256 callCount;
        uint256 totalGas;
        uint256 avgGas;
    }

    mapping(string => ProfileData) public profiles;
    mapping(address => mapping(string => uint256)) public userCallCounts;
    string[] public profiledFunctions;

    event FunctionProfiled(string functionName, uint256 gasUsed, uint256 executionTime);

    function startProfiling(string memory functionName) external returns (uint256 startGas) {
        startGas = gasleft();
        // Store start gas for later calculation
    }

    function endProfiling(
        string memory functionName,
        uint256 startGas,
        uint256 startTime
    ) external {
        uint256 gasUsed = startGas - gasleft();
        uint256 executionTime = block.timestamp - startTime;
        
        ProfileData storage profile = profiles[functionName];
        
        if (profile.callCount == 0) {
            profiledFunctions.push(functionName);
            profile.functionName = functionName;
        }
        
        profile.gasUsed = gasUsed;
        profile.executionTime = executionTime;
        profile.callCount++;
        profile.totalGas += gasUsed;
        profile.avgGas = profile.totalGas / profile.callCount;
        
        userCallCounts[msg.sender][functionName]++;
        
        emit FunctionProfiled(functionName, gasUsed, executionTime);
    }

    function getProfile(string memory functionName) external view returns (ProfileData memory) {
        return profiles[functionName];
    }

    function getAllProfiles() external view returns (string[] memory) {
        return profiledFunctions;
    }

    function getUserCallCount(address user, string memory functionName) external view returns (uint256) {
        return userCallCounts[user][functionName];
    }

    function getTopGasConsumers(uint256 limit) external view returns (string[] memory) {
        string[] memory result = new string[](limit);
        uint256[] memory gasAmounts = new uint256[](limit);
        
        for (uint256 i = 0; i < profiledFunctions.length; i++) {
            string memory funcName = profiledFunctions[i];
            uint256 avgGas = profiles[funcName].avgGas;
            
            // Simple insertion sort for top consumers
            for (uint256 j = 0; j < limit; j++) {
                if (avgGas > gasAmounts[j]) {
                    // Shift elements
                    for (uint256 k = limit - 1; k > j; k--) {
                        gasAmounts[k] = gasAmounts[k-1];
                        result[k] = result[k-1];
                    }
                    gasAmounts[j] = avgGas;
                    result[j] = funcName;
                    break;
                }
            }
        }
        
        return result;
    }
}
