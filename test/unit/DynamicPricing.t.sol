// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/pricing/DynamicPricing.sol";

contract DynamicPricingTest is Test {
    DynamicPricing pricing;
    bytes32 ruleId = keccak256("test-rule");

    function setUp() public {
        pricing = new DynamicPricing();
    }

    function testCreatePricingRule() public {
        pricing.createPricingRule(ruleId, 100, 10, 200, 50);
        
        (uint256 basePrice, uint256 demandMultiplier, uint256 maxPrice, uint256 minPrice, bool active) = pricing.pricingRules(ruleId);
        assertEq(basePrice, 100);
        assertEq(demandMultiplier, 10);
        assertEq(maxPrice, 200);
        assertEq(minPrice, 50);
        assertTrue(active);
    }

    function testDynamicPricing() public {
        pricing.createPricingRule(ruleId, 100, 10, 200, 50);
        
        // Test with no demand
        uint256 price = pricing.getCurrentPrice(ruleId);
        assertEq(price, 100);
        
        // Test with demand
        pricing.updateDemand(ruleId, 5);
        price = pricing.getCurrentPrice(ruleId);
        assertEq(price, 150); // 100 + (5 * 10)
        
        // Test max price cap
        pricing.updateDemand(ruleId, 20);
        price = pricing.getCurrentPrice(ruleId);
        assertEq(price, 200); // Capped at max
    }

    function testMinPriceCap() public {
        pricing.createPricingRule(ruleId, 100, 10, 200, 80);
        
        // This would result in price below min
        pricing.updateDemand(ruleId, 0);
        uint256 price = pricing.getCurrentPrice(ruleId);
        assertEq(price, 100); // Base price, above min
    }
}
