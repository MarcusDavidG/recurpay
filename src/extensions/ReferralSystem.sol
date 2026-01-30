// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ReferralSystem {
    struct ReferralData {
        address referrer;
        uint256 totalReferred;
        uint256 totalEarned;
        bool isActive;
    }

    mapping(address => ReferralData) public referrals;
    mapping(address => address) public referredBy;
    
    uint256 public referralRewardPercentage = 500; // 5%
    uint256 public constant MAX_REFERRAL_PERCENTAGE = 2000; // 20%

    event ReferralRegistered(address indexed referrer, address indexed referred);
    event ReferralRewardPaid(address indexed referrer, uint256 amount);

    function registerReferral(address referrer) external {
        require(referrer != msg.sender, "Cannot refer yourself");
        require(referredBy[msg.sender] == address(0), "Already referred");
        require(referrals[referrer].isActive, "Referrer not active");

        referredBy[msg.sender] = referrer;
        referrals[referrer].totalReferred++;

        emit ReferralRegistered(referrer, msg.sender);
    }

    function activateReferrer() external {
        referrals[msg.sender].isActive = true;
    }

    function processReferralReward(address subscriber, uint256 paymentAmount) external returns (uint256 reward) {
        address referrer = referredBy[subscriber];
        if (referrer == address(0)) return 0;

        reward = (paymentAmount * referralRewardPercentage) / 10000;
        referrals[referrer].totalEarned += reward;

        emit ReferralRewardPaid(referrer, reward);
    }

    function setReferralPercentage(uint256 newPercentage) external {
        require(newPercentage <= MAX_REFERRAL_PERCENTAGE, "Percentage too high");
        referralRewardPercentage = newPercentage;
    }

    function getReferralData(address user) external view returns (ReferralData memory) {
        return referrals[user];
    }
}
