// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionValidator {
    struct ValidationRule {
        string name;
        bytes ruleData;
        bool active;
        uint256 priority;
    }

    mapping(bytes32 => ValidationRule) public rules;
    mapping(string => bytes32[]) public rulesByType;
    bytes32[] public allRules;

    event RuleAdded(bytes32 indexed ruleId, string name);
    event ValidationFailed(bytes32 indexed ruleId, bytes data);

    function addRule(
        string memory name,
        string memory ruleType,
        bytes memory ruleData,
        uint256 priority
    ) external returns (bytes32 ruleId) {
        ruleId = keccak256(abi.encodePacked(name, ruleType, block.timestamp));
        
        rules[ruleId] = ValidationRule({
            name: name,
            ruleData: ruleData,
            active: true,
            priority: priority
        });

        rulesByType[ruleType].push(ruleId);
        allRules.push(ruleId);

        emit RuleAdded(ruleId, name);
    }

    function validateData(string memory ruleType, bytes memory data) external returns (bool) {
        bytes32[] memory typeRules = rulesByType[ruleType];
        
        for (uint256 i = 0; i < typeRules.length; i++) {
            ValidationRule memory rule = rules[typeRules[i]];
            if (!rule.active) continue;

            if (!executeValidation(rule, data)) {
                emit ValidationFailed(typeRules[i], data);
                return false;
            }
        }
        
        return true;
    }

    function executeValidation(ValidationRule memory rule, bytes memory data) internal pure returns (bool) {
        // Simplified validation logic
        return data.length > 0 && rule.ruleData.length > 0;
    }

    function deactivateRule(bytes32 ruleId) external {
        rules[ruleId].active = false;
    }
}
