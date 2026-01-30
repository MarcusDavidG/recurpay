// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionWatchdog {
    struct WatchRule {
        string name;
        address target;
        bytes4 selector;
        uint256 threshold;
        uint256 window;
        uint256 count;
        uint256 lastReset;
        bool active;
    }

    mapping(bytes32 => WatchRule) public watchRules;
    mapping(address => bytes32[]) public targetRules;
    bytes32[] public allRules;

    event RuleTriggered(bytes32 indexed ruleId, string name, uint256 count);
    event RuleAdded(bytes32 indexed ruleId, string name, address target);

    function addWatchRule(
        string memory name,
        address target,
        bytes4 selector,
        uint256 threshold,
        uint256 window
    ) external returns (bytes32 ruleId) {
        ruleId = keccak256(abi.encodePacked(name, target, selector));
        
        watchRules[ruleId] = WatchRule({
            name: name,
            target: target,
            selector: selector,
            threshold: threshold,
            window: window,
            count: 0,
            lastReset: block.timestamp,
            active: true
        });

        targetRules[target].push(ruleId);
        allRules.push(ruleId);

        emit RuleAdded(ruleId, name, target);
    }

    function recordActivity(address target, bytes4 selector) external {
        bytes32[] memory rules = targetRules[target];
        
        for (uint256 i = 0; i < rules.length; i++) {
            WatchRule storage rule = watchRules[rules[i]];
            
            if (!rule.active || rule.selector != selector) continue;
            
            // Reset count if window expired
            if (block.timestamp >= rule.lastReset + rule.window) {
                rule.count = 0;
                rule.lastReset = block.timestamp;
            }
            
            rule.count++;
            
            if (rule.count >= rule.threshold) {
                emit RuleTriggered(rules[i], rule.name, rule.count);
                rule.count = 0; // Reset after trigger
                rule.lastReset = block.timestamp;
            }
        }
    }

    function deactivateRule(bytes32 ruleId) external {
        watchRules[ruleId].active = false;
    }

    function getRule(bytes32 ruleId) external view returns (WatchRule memory) {
        return watchRules[ruleId];
    }

    function getTargetRules(address target) external view returns (bytes32[] memory) {
        return targetRules[target];
    }
}
