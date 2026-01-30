// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract LoyaltyRewards {
    struct LoyaltyTier {
        string name;
        uint256 minPoints;
        uint256 rewardMultiplier;
        uint256 discountPercentage;
        string[] benefits;
    }

    struct UserLoyalty {
        uint256 totalPoints;
        uint256 currentTier;
        uint256 lifetimeSpent;
        uint256 consecutiveMonths;
        uint256 lastActivityTime;
        mapping(uint256 => uint256) monthlyPoints;
    }

    mapping(address => mapping(address => UserLoyalty)) public userLoyalty; // subscriber => creator => loyalty
    mapping(address => LoyaltyTier[]) public loyaltyTiers; // creator => tiers
    mapping(address => uint256) public pointsPerDollar; // creator => points rate
    
    uint256 public constant DEFAULT_POINTS_PER_DOLLAR = 10;

    event PointsEarned(address indexed subscriber, address indexed creator, uint256 points);
    event TierUpgraded(address indexed subscriber, address indexed creator, uint256 newTier);
    event RewardRedeemed(address indexed subscriber, address indexed creator, uint256 points, string reward);

    function setupLoyaltyTiers(
        string[] memory names,
        uint256[] memory minPoints,
        uint256[] memory rewardMultipliers,
        uint256[] memory discountPercentages
    ) external {
        require(names.length == minPoints.length, "Array length mismatch");
        
        delete loyaltyTiers[msg.sender];
        
        for (uint256 i = 0; i < names.length; i++) {
            loyaltyTiers[msg.sender].push(LoyaltyTier({
                name: names[i],
                minPoints: minPoints[i],
                rewardMultiplier: rewardMultipliers[i],
                discountPercentage: discountPercentages[i],
                benefits: new string[](0)
            }));
        }
    }

    function earnPoints(address subscriber, address creator, uint256 paymentAmount) external {
        uint256 pointsRate = pointsPerDollar[creator] > 0 ? pointsPerDollar[creator] : DEFAULT_POINTS_PER_DOLLAR;
        uint256 basePoints = (paymentAmount * pointsRate) / 1e18;
        
        UserLoyalty storage loyalty = userLoyalty[subscriber][creator];
        
        // Apply tier multiplier
        uint256 multiplier = getCurrentTierMultiplier(subscriber, creator);
        uint256 totalPoints = (basePoints * multiplier) / 100;
        
        // Consecutive month bonus
        if (isConsecutiveMonth(subscriber, creator)) {
            loyalty.consecutiveMonths++;
            if (loyalty.consecutiveMonths >= 3) {
                totalPoints = (totalPoints * 110) / 100; // 10% bonus for 3+ consecutive months
            }
        } else {
            loyalty.consecutiveMonths = 1;
        }
        
        loyalty.totalPoints += totalPoints;
        loyalty.lifetimeSpent += paymentAmount;
        loyalty.lastActivityTime = block.timestamp;
        loyalty.monthlyPoints[getCurrentMonth()] += totalPoints;
        
        // Check for tier upgrade
        uint256 newTier = calculateTier(subscriber, creator);
        if (newTier > loyalty.currentTier) {
            loyalty.currentTier = newTier;
            emit TierUpgraded(subscriber, creator, newTier);
        }
        
        emit PointsEarned(subscriber, creator, totalPoints);
    }

    function redeemPoints(address creator, uint256 points, string memory reward) external {
        UserLoyalty storage loyalty = userLoyalty[msg.sender][creator];
        require(loyalty.totalPoints >= points, "Insufficient points");
        
        loyalty.totalPoints -= points;
        emit RewardRedeemed(msg.sender, creator, points, reward);
    }

    function getCurrentTierMultiplier(address subscriber, address creator) public view returns (uint256) {
        UserLoyalty storage loyalty = userLoyalty[subscriber][creator];
        LoyaltyTier[] memory tiers = loyaltyTiers[creator];
        
        if (tiers.length == 0 || loyalty.currentTier >= tiers.length) {
            return 100; // 1x multiplier
        }
        
        return tiers[loyalty.currentTier].rewardMultiplier;
    }

    function calculateTier(address subscriber, address creator) public view returns (uint256) {
        UserLoyalty storage loyalty = userLoyalty[subscriber][creator];
        LoyaltyTier[] memory tiers = loyaltyTiers[creator];
        
        for (uint256 i = tiers.length; i > 0; i--) {
            if (loyalty.totalPoints >= tiers[i - 1].minPoints) {
                return i - 1;
            }
        }
        
        return 0;
    }

    function isConsecutiveMonth(address subscriber, address creator) internal view returns (bool) {
        UserLoyalty storage loyalty = userLoyalty[subscriber][creator];
        uint256 currentMonth = getCurrentMonth();
        uint256 lastMonth = currentMonth - 1;
        
        return loyalty.monthlyPoints[lastMonth] > 0;
    }

    function getCurrentMonth() internal view returns (uint256) {
        return block.timestamp / 30 days;
    }

    function getUserLoyaltyInfo(address subscriber, address creator) external view returns (
        uint256 totalPoints,
        uint256 currentTier,
        uint256 lifetimeSpent,
        uint256 consecutiveMonths,
        string memory tierName
    ) {
        UserLoyalty storage loyalty = userLoyalty[subscriber][creator];
        LoyaltyTier[] memory tiers = loyaltyTiers[creator];
        
        totalPoints = loyalty.totalPoints;
        currentTier = loyalty.currentTier;
        lifetimeSpent = loyalty.lifetimeSpent;
        consecutiveMonths = loyalty.consecutiveMonths;
        
        if (tiers.length > 0 && currentTier < tiers.length) {
            tierName = tiers[currentTier].name;
        } else {
            tierName = "No Tier";
        }
    }

    function getAvailableDiscount(address subscriber, address creator) external view returns (uint256) {
        UserLoyalty storage loyalty = userLoyalty[subscriber][creator];
        LoyaltyTier[] memory tiers = loyaltyTiers[creator];
        
        if (tiers.length == 0 || loyalty.currentTier >= tiers.length) {
            return 0;
        }
        
        return tiers[loyalty.currentTier].discountPercentage;
    }

    function setPointsPerDollar(uint256 rate) external {
        require(rate > 0 && rate <= 1000, "Invalid rate");
        pointsPerDollar[msg.sender] = rate;
    }

    function getLoyaltyTiers(address creator) external view returns (LoyaltyTier[] memory) {
        return loyaltyTiers[creator];
    }

    function getMonthlyPoints(address subscriber, address creator, uint256 month) external view returns (uint256) {
        return userLoyalty[subscriber][creator].monthlyPoints[month];
    }
}
