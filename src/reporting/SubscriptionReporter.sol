// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionReporter {
    struct Report {
        address reporter;
        address target;
        string reason;
        bytes evidence;
        uint256 timestamp;
        bool resolved;
    }

    mapping(bytes32 => Report) public reports;
    mapping(address => bytes32[]) public userReports;
    mapping(address => uint256) public reportCount;

    event ReportSubmitted(bytes32 indexed reportId, address reporter, address target);
    event ReportResolved(bytes32 indexed reportId, bool actionTaken);

    function submitReport(
        address target,
        string memory reason,
        bytes memory evidence
    ) external returns (bytes32 reportId) {
        reportId = keccak256(abi.encodePacked(msg.sender, target, reason, block.timestamp));
        
        reports[reportId] = Report({
            reporter: msg.sender,
            target: target,
            reason: reason,
            evidence: evidence,
            timestamp: block.timestamp,
            resolved: false
        });

        userReports[msg.sender].push(reportId);
        reportCount[target]++;

        emit ReportSubmitted(reportId, msg.sender, target);
    }

    function resolveReport(bytes32 reportId, bool actionTaken) external {
        Report storage report = reports[reportId];
        require(!report.resolved, "Already resolved");
        
        report.resolved = true;
        emit ReportResolved(reportId, actionTaken);
    }

    function getReport(bytes32 reportId) external view returns (Report memory) {
        return reports[reportId];
    }

    function getUserReports(address user) external view returns (bytes32[] memory) {
        return userReports[user];
    }
}
