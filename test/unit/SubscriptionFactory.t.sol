// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract SubscriptionFactoryTest is Test {
    SubscriptionFactory public factory;
    MockERC20 public token;

    address public owner = address(this);
    address public creator = address(0x1);
    address public user = address(0x2);

    uint256 public constant PRICE = 10 ether;
    uint32 public constant BILLING_PERIOD = 30 days;
    uint32 public constant GRACE_PERIOD = 3 days;

    function setUp() public {
        factory = new SubscriptionFactory(owner);
        token = new MockERC20("Test Token", "TEST", 18);
        
        // Add token to supported list
        factory.setSupportedToken(address(token), true);
    }

    function _createDefaultPlanConfig() internal view returns (ISubscriptionFactory.PlanConfig memory) {
        return ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: GRACE_PERIOD,
            maxSubscribers: 0,
            active: true
        });
    }

    function _createDefaultPlanMetadata() internal pure returns (ISubscriptionFactory.PlanMetadata memory) {
        return ISubscriptionFactory.PlanMetadata({
            name: "Test Plan",
            description: "A test subscription plan",
            metadataURI: "ipfs://test"
        });
    }
}
