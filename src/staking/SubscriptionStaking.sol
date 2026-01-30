// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionStaking {
    struct StakeInfo {
        uint256 amount;
        uint256 stakedAt;
        uint256 lockPeriod;
        uint256 rewardRate;
        bool active;
    }

    mapping(address => StakeInfo) public stakes;
    mapping(address => uint256) public rewards;
    
    uint256 public totalStaked;
    uint256 public constant BASE_REWARD_RATE = 500; // 5% APY
    uint256 public constant LOCK_BONUS = 200; // 2% bonus for locking

    event Staked(address indexed user, uint256 amount, uint256 lockPeriod);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    function stake(uint256 lockPeriod) external payable {
        require(msg.value > 0, "Cannot stake 0");
        require(lockPeriod <= 365 days, "Lock period too long");

        StakeInfo storage stakeInfo = stakes[msg.sender];
        
        if (stakeInfo.active) {
            // Claim existing rewards before updating stake
            claimRewards();
        }

        uint256 rewardRate = BASE_REWARD_RATE;
        if (lockPeriod > 0) {
            rewardRate += LOCK_BONUS;
        }

        stakeInfo.amount += msg.value;
        stakeInfo.stakedAt = block.timestamp;
        stakeInfo.lockPeriod = lockPeriod;
        stakeInfo.rewardRate = rewardRate;
        stakeInfo.active = true;

        totalStaked += msg.value;
        emit Staked(msg.sender, msg.value, lockPeriod);
    }

    function unstake() external {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.active, "No active stake");
        require(
            block.timestamp >= stakeInfo.stakedAt + stakeInfo.lockPeriod,
            "Still locked"
        );

        claimRewards();

        uint256 amount = stakeInfo.amount;
        stakeInfo.amount = 0;
        stakeInfo.active = false;
        totalStaked -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() public {
        StakeInfo memory stakeInfo = stakes[msg.sender];
        require(stakeInfo.active, "No active stake");

        uint256 stakingDuration = block.timestamp - stakeInfo.stakedAt;
        uint256 reward = (stakeInfo.amount * stakeInfo.rewardRate * stakingDuration) / (365 days * 10000);

        if (reward > 0) {
            rewards[msg.sender] += reward;
            stakes[msg.sender].stakedAt = block.timestamp; // Reset reward calculation
            emit RewardsClaimed(msg.sender, reward);
        }
    }

    function getStakeInfo(address user) external view returns (StakeInfo memory) {
        return stakes[user];
    }

    function calculatePendingRewards(address user) external view returns (uint256) {
        StakeInfo memory stakeInfo = stakes[user];
        if (!stakeInfo.active) return 0;

        uint256 stakingDuration = block.timestamp - stakeInfo.stakedAt;
        return (stakeInfo.amount * stakeInfo.rewardRate * stakingDuration) / (365 days * 10000);
    }
}
