// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionFilters {
    function filterActiveSubscriptions(bytes32[] memory subscriptionIds, mapping(bytes32 => bool) storage activeStatus) 
        external 
        view 
        returns (bytes32[] memory) 
    {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < subscriptionIds.length; i++) {
            if (activeStatus[subscriptionIds[i]]) {
                activeCount++;
            }
        }

        bytes32[] memory activeSubscriptions = new bytes32[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < subscriptionIds.length; i++) {
            if (activeStatus[subscriptionIds[i]]) {
                activeSubscriptions[index] = subscriptionIds[i];
                index++;
            }
        }

        return activeSubscriptions;
    }

    function filterByPriceRange(uint256[] memory prices, uint256 minPrice, uint256 maxPrice) 
        external 
        pure 
        returns (uint256[] memory) 
    {
        uint256 validCount = 0;
        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i] >= minPrice && prices[i] <= maxPrice) {
                validCount++;
            }
        }

        uint256[] memory validPrices = new uint256[](validCount);
        uint256 index = 0;
        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i] >= minPrice && prices[i] <= maxPrice) {
                validPrices[index] = prices[i];
                index++;
            }
        }

        return validPrices;
    }
}
