// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/extensions/SubscriptionTiers.sol";
import "../src/extensions/DiscountManager.sol";
import "../src/extensions/ReferralSystem.sol";

contract ExtensionsTest is Test {
    SubscriptionTiers tiers;
    DiscountManager discounts;
    ReferralSystem referrals;
    
    address creator = address(0x1);
    address user = address(0x2);
    address referrer = address(0x3);
    
    function setUp() public {
        tiers = new SubscriptionTiers();
        discounts = new DiscountManager();
        referrals = new ReferralSystem();
    }
    
    function testCreateTier() public {
        vm.prank(creator);
        string[] memory benefits = new string[](2);
        benefits[0] = "Feature 1";
        benefits[1] = "Feature 2";
        
        uint256 tierId = tiers.createTier(
            "Premium",
            1 ether,
            30 days,
            benefits,
            100
        );
        
        assertEq(tierId, 0);
        
        SubscriptionTiers.Tier memory tier = tiers.getTier(creator, tierId);
        assertEq(tier.price, 1 ether);
        assertEq(tier.name, "Premium");
    }
    
    function testCreateDiscount() public {
        vm.prank(creator);
        bytes32 discountId = discounts.createDiscount(
            "SAVE20",
            2000, // 20%
            block.timestamp + 30 days,
            100
        );
        
        assertNotEq(discountId, bytes32(0));
    }
    
    function testReferralSystem() public {
        vm.prank(referrer);
        referrals.activateReferrer();
        
        vm.prank(user);
        referrals.registerReferral(referrer);
        
        ReferralSystem.ReferralData memory data = referrals.getReferralData(referrer);
        assertEq(data.totalReferred, 1);
        assertTrue(data.isActive);
    }
    
    function testDiscountApplication() public {
        vm.prank(creator);
        bytes32 discountId = discounts.createDiscount(
            "SAVE20",
            2000, // 20%
            block.timestamp + 30 days,
            100
        );
        
        vm.prank(address(this));
        uint256 discountPercentage = discounts.applyDiscount(discountId, user);
        assertEq(discountPercentage, 2000);
        
        uint256 discountedPrice = discounts.calculateDiscountedPrice(1 ether, discountPercentage);
        assertEq(discountedPrice, 0.8 ether);
    }
}
