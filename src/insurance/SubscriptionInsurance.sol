// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionInsurance {
    struct InsurancePolicy {
        address subscriber;
        address creator;
        uint256 premium;
        uint256 coverage;
        uint256 startTime;
        uint256 endTime;
        bool active;
        uint256 claimCount;
    }

    struct Claim {
        bytes32 policyId;
        address claimant;
        uint256 amount;
        string reason;
        bool approved;
        bool paid;
        uint256 timestamp;
    }

    mapping(bytes32 => InsurancePolicy) public policies;
    mapping(bytes32 => Claim) public claims;
    mapping(address => bytes32[]) public userPolicies;

    event PolicyCreated(bytes32 indexed policyId, address indexed subscriber, uint256 coverage);
    event ClaimFiled(bytes32 indexed claimId, bytes32 indexed policyId, uint256 amount);

    function createPolicy(
        address creator,
        uint256 coverage,
        uint256 duration
    ) external payable returns (bytes32 policyId) {
        uint256 premium = calculatePremium(coverage, duration);
        require(msg.value >= premium, "Insufficient premium");

        policyId = keccak256(abi.encodePacked(msg.sender, creator, block.timestamp));
        
        policies[policyId] = InsurancePolicy({
            subscriber: msg.sender,
            creator: creator,
            premium: premium,
            coverage: coverage,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            active: true,
            claimCount: 0
        });

        userPolicies[msg.sender].push(policyId);
        emit PolicyCreated(policyId, msg.sender, coverage);
    }

    function fileClaim(
        bytes32 policyId,
        uint256 amount,
        string memory reason
    ) external returns (bytes32 claimId) {
        InsurancePolicy storage policy = policies[policyId];
        require(policy.subscriber == msg.sender, "Not policy holder");
        require(policy.active, "Policy not active");
        require(amount <= policy.coverage, "Amount exceeds coverage");

        claimId = keccak256(abi.encodePacked(policyId, amount, block.timestamp));
        
        claims[claimId] = Claim({
            policyId: policyId,
            claimant: msg.sender,
            amount: amount,
            reason: reason,
            approved: false,
            paid: false,
            timestamp: block.timestamp
        });

        emit ClaimFiled(claimId, policyId, amount);
    }

    function calculatePremium(uint256 coverage, uint256 duration) internal pure returns (uint256) {
        return (coverage * duration) / (365 days * 100); // 1% of coverage per year
    }
}
