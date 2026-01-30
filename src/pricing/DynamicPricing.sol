// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DynamicPricing {
    struct PricingRule {
        uint256 basePrice;
        uint256 demandMultiplier;
        uint256 maxPrice;
        uint256 minPrice;
        bool active;
    }

    mapping(bytes32 => PricingRule) public pricingRules;
    mapping(bytes32 => uint256) public currentDemand;

    event PriceUpdated(bytes32 indexed ruleId, uint256 newPrice);

    function createPricingRule(
        bytes32 ruleId,
        uint256 basePrice,
        uint256 demandMultiplier,
        uint256 maxPrice,
        uint256 minPrice
    ) external {
        pricingRules[ruleId] = PricingRule({
            basePrice: basePrice,
            demandMultiplier: demandMultiplier,
            maxPrice: maxPrice,
            minPrice: minPrice,
            active: true
        });
    }

    function updateDemand(bytes32 ruleId, uint256 demand) external {
        currentDemand[ruleId] = demand;
    }

    function getCurrentPrice(bytes32 ruleId) external view returns (uint256) {
        PricingRule memory rule = pricingRules[ruleId];
        if (!rule.active) return rule.basePrice;

        uint256 dynamicPrice = rule.basePrice + (currentDemand[ruleId] * rule.demandMultiplier);
        
        if (dynamicPrice > rule.maxPrice) return rule.maxPrice;
        if (dynamicPrice < rule.minPrice) return rule.minPrice;
        
        return dynamicPrice;
    }
}
