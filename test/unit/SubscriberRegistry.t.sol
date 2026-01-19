// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {SubscriberRegistry} from "src/SubscriberRegistry.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract SubscriberRegistryTest is Test {
    SubscriptionFactory public factory;
    SubscriberRegistry public registry;
    MockERC20 public token;

    address public owner = address(this);
    address public creator = address(0x1);
    address public subscriber = address(0x2);
    address public processor = address(0x3);

    uint256 public constant PRICE = 10 ether;
    uint32 public constant BILLING_PERIOD = 30 days;
    uint32 public constant GRACE_PERIOD = 3 days;

    uint256 public planId;

    function setUp() public {
        factory = new SubscriptionFactory(owner);
        registry = new SubscriberRegistry(address(factory), owner);
        token = new MockERC20("Test Token", "TEST", 18);

        factory.setSupportedToken(address(token), true);
        registry.setProcessor(processor);

        // Create a default plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: GRACE_PERIOD,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Test Plan",
            description: "",
            metadataURI: ""
        });

        planId = factory.createPlan(config, metadata);
    }
}
