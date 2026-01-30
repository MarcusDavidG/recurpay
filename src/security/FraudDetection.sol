// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FraudDetection {
    struct FraudScore {
        uint256 score;
        uint256 lastUpdated;
        string[] riskFactors;
        bool flagged;
    }

    struct SuspiciousActivity {
        address user;
        string activityType;
        uint256 timestamp;
        uint256 riskLevel;
        bool investigated;
    }

    mapping(address => FraudScore) public userFraudScores;
    mapping(bytes32 => SuspiciousActivity) public suspiciousActivities;
    mapping(address => uint256) public userActivityCount;

    event FraudDetected(address indexed user, uint256 score, string[] riskFactors);
    event SuspiciousActivityLogged(bytes32 indexed activityId, address indexed user, string activityType);

    function updateFraudScore(address user, uint256 newScore, string[] memory riskFactors) external {
        userFraudScores[user] = FraudScore({
            score: newScore,
            lastUpdated: block.timestamp,
            riskFactors: riskFactors,
            flagged: newScore > 700 // Flag if score > 70%
        });

        if (newScore > 700) {
            emit FraudDetected(user, newScore, riskFactors);
        }
    }

    function logSuspiciousActivity(
        address user,
        string memory activityType,
        uint256 riskLevel
    ) external returns (bytes32 activityId) {
        activityId = keccak256(abi.encodePacked(user, activityType, block.timestamp));
        
        suspiciousActivities[activityId] = SuspiciousActivity({
            user: user,
            activityType: activityType,
            timestamp: block.timestamp,
            riskLevel: riskLevel,
            investigated: false
        });

        userActivityCount[user]++;
        emit SuspiciousActivityLogged(activityId, user, activityType);
    }

    function isUserFlagged(address user) external view returns (bool) {
        return userFraudScores[user].flagged;
    }
}
