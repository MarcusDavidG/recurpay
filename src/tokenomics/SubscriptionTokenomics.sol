// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionTokenomics {
    uint256 public totalSupply = 1000000 * 10**18;
    uint256 public stakingRewards = 100000 * 10**18;
    uint256 public liquidityIncentives = 50000 * 10**18;
    uint256 public teamAllocation = 150000 * 10**18;
    uint256 public communityTreasury = 200000 * 10**18;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakingBalances;

    function stake(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        stakingBalances[msg.sender] += amount;
    }

    function unstake(uint256 amount) external {
        require(stakingBalances[msg.sender] >= amount, "Insufficient staked");
        stakingBalances[msg.sender] -= amount;
        balances[msg.sender] += amount;
    }

    function calculateRewards(address user) external view returns (uint256) {
        return (stakingBalances[user] * 500) / 10000; // 5% APY
    }
}
