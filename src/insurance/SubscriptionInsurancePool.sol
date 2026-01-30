// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionInsurancePool {
    struct InsurancePool {
        uint256 totalFunds;
        uint256 totalCoverage;
        uint256 premiumRate;
        uint256 claimsPaid;
        bool active;
    }

    struct Policy {
        address holder;
        uint256 coverage;
        uint256 premium;
        uint256 startTime;
        uint256 duration;
        bool active;
        uint256 claimCount;
    }

    mapping(bytes32 => InsurancePool) public pools;
    mapping(bytes32 => Policy) public policies;
    mapping(address => bytes32[]) public userPolicies;
    mapping(bytes32 => bytes32[]) public poolPolicies;

    event PoolCreated(bytes32 indexed poolId, uint256 premiumRate);
    event PolicyPurchased(bytes32 indexed policyId, address holder, uint256 coverage);
    event ClaimPaid(bytes32 indexed policyId, uint256 amount);

    function createInsurancePool(
        bytes32 poolId,
        uint256 premiumRate
    ) external payable {
        pools[poolId] = InsurancePool({
            totalFunds: msg.value,
            totalCoverage: 0,
            premiumRate: premiumRate,
            claimsPaid: 0,
            active: true
        });

        emit PoolCreated(poolId, premiumRate);
    }

    function purchasePolicy(
        bytes32 poolId,
        uint256 coverage,
        uint256 duration
    ) external payable returns (bytes32 policyId) {
        InsurancePool storage pool = pools[poolId];
        require(pool.active, "Pool not active");

        uint256 premium = (coverage * pool.premiumRate * duration) / (365 days * 10000);
        require(msg.value >= premium, "Insufficient premium");

        policyId = keccak256(abi.encodePacked(msg.sender, poolId, block.timestamp));
        
        policies[policyId] = Policy({
            holder: msg.sender,
            coverage: coverage,
            premium: premium,
            startTime: block.timestamp,
            duration: duration,
            active: true,
            claimCount: 0
        });

        pool.totalFunds += premium;
        pool.totalCoverage += coverage;
        
        userPolicies[msg.sender].push(policyId);
        poolPolicies[poolId].push(policyId);

        emit PolicyPurchased(policyId, msg.sender, coverage);
    }

    function fileClaim(bytes32 policyId, uint256 claimAmount, string memory reason) external {
        Policy storage policy = policies[policyId];
        require(policy.holder == msg.sender, "Not policy holder");
        require(policy.active, "Policy not active");
        require(claimAmount <= policy.coverage, "Exceeds coverage");
        require(
            block.timestamp <= policy.startTime + policy.duration,
            "Policy expired"
        );

        // Simplified claim processing
        policy.claimCount++;
        
        // Find the pool and pay claim
        bytes32 poolId = findPolicyPool(policyId);
        InsurancePool storage pool = pools[poolId];
        require(pool.totalFunds >= claimAmount, "Insufficient pool funds");

        pool.totalFunds -= claimAmount;
        pool.claimsPaid += claimAmount;

        (bool success, ) = payable(msg.sender).call{value: claimAmount}("");
        require(success, "Claim payment failed");

        emit ClaimPaid(policyId, claimAmount);
    }

    function addFundsToPool(bytes32 poolId) external payable {
        InsurancePool storage pool = pools[poolId];
        require(pool.active, "Pool not active");
        
        pool.totalFunds += msg.value;
    }

    function findPolicyPool(bytes32 policyId) internal view returns (bytes32) {
        // Simplified - would implement proper lookup
        return bytes32(0);
    }

    function getPoolInfo(bytes32 poolId) external view returns (InsurancePool memory) {
        return pools[poolId];
    }

    function getPolicyInfo(bytes32 policyId) external view returns (Policy memory) {
        return policies[policyId];
    }
}
