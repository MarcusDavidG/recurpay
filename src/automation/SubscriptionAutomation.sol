// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionAutomation {
    struct AutomationRule {
        string trigger;
        string action;
        bytes parameters;
        bool active;
        uint256 executionCount;
        uint256 lastExecution;
    }

    mapping(bytes32 => AutomationRule) public automationRules;
    mapping(address => bytes32[]) public creatorRules;

    event RuleCreated(bytes32 indexed ruleId, address indexed creator, string trigger, string action);
    event RuleExecuted(bytes32 indexed ruleId, uint256 executionCount);

    function createAutomationRule(
        string memory trigger,
        string memory action,
        bytes memory parameters
    ) external returns (bytes32 ruleId) {
        ruleId = keccak256(abi.encodePacked(msg.sender, trigger, action, block.timestamp));
        
        automationRules[ruleId] = AutomationRule({
            trigger: trigger,
            action: action,
            parameters: parameters,
            active: true,
            executionCount: 0,
            lastExecution: 0
        });

        creatorRules[msg.sender].push(ruleId);
        emit RuleCreated(ruleId, msg.sender, trigger, action);
    }

    function executeRule(bytes32 ruleId) external {
        AutomationRule storage rule = automationRules[ruleId];
        require(rule.active, "Rule not active");

        rule.executionCount++;
        rule.lastExecution = block.timestamp;

        emit RuleExecuted(ruleId, rule.executionCount);
    }

    function toggleRule(bytes32 ruleId) external {
        automationRules[ruleId].active = !automationRules[ruleId].active;
    }
}
