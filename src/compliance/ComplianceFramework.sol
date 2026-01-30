// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ComplianceFramework {
    struct ComplianceRule {
        string ruleName;
        string jurisdiction;
        bool mandatory;
        uint256 implementationDeadline;
        bool implemented;
        address implementer;
    }

    struct AuditRecord {
        address auditor;
        uint256 timestamp;
        string findings;
        bool passed;
        string recommendations;
    }

    mapping(bytes32 => ComplianceRule) public complianceRules;
    mapping(address => AuditRecord[]) public auditHistory;
    mapping(address => bool) public authorizedAuditors;

    event ComplianceRuleAdded(bytes32 indexed ruleId, string ruleName, string jurisdiction);
    event AuditCompleted(address indexed entity, address indexed auditor, bool passed);

    function addComplianceRule(
        string memory ruleName,
        string memory jurisdiction,
        bool mandatory,
        uint256 implementationDeadline
    ) external returns (bytes32 ruleId) {
        ruleId = keccak256(abi.encodePacked(ruleName, jurisdiction));
        
        complianceRules[ruleId] = ComplianceRule({
            ruleName: ruleName,
            jurisdiction: jurisdiction,
            mandatory: mandatory,
            implementationDeadline: implementationDeadline,
            implemented: false,
            implementer: address(0)
        });

        emit ComplianceRuleAdded(ruleId, ruleName, jurisdiction);
    }

    function markRuleImplemented(bytes32 ruleId) external {
        ComplianceRule storage rule = complianceRules[ruleId];
        rule.implemented = true;
        rule.implementer = msg.sender;
    }

    function conductAudit(
        address entity,
        string memory findings,
        bool passed,
        string memory recommendations
    ) external {
        require(authorizedAuditors[msg.sender], "Not authorized auditor");
        
        auditHistory[entity].push(AuditRecord({
            auditor: msg.sender,
            timestamp: block.timestamp,
            findings: findings,
            passed: passed,
            recommendations: recommendations
        }));

        emit AuditCompleted(entity, msg.sender, passed);
    }

    function authorizeAuditor(address auditor) external {
        authorizedAuditors[auditor] = true;
    }
}
