// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {SubscriberRegistry} from "src/SubscriberRegistry.sol";
import {CreatorVault} from "src/CreatorVault.sol";
import {PaymentProcessor} from "src/PaymentProcessor.sol";
import {RecurPayRouter} from "src/RecurPayRouter.sol";

contract DeployRecurPay is Script {
    // Deployment configuration
    address public deployer;
    address public treasury;
    uint16 public protocolFeeBps;

    // Deployed contracts
    SubscriptionFactory public factory;
    SubscriberRegistry public registry;
    CreatorVault public vault;
    PaymentProcessor public processor;
    RecurPayRouter public router;

    function setUp() public {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        treasury = vm.envAddress("TREASURY_ADDRESS");
        protocolFeeBps = uint16(vm.envUint("PROTOCOL_FEE_BPS"));
    }

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // 1. Deploy SubscriptionFactory
        factory = new SubscriptionFactory(deployer);
        console.log("SubscriptionFactory deployed at:", address(factory));

        // 2. Deploy SubscriberRegistry
        registry = new SubscriberRegistry(address(factory), deployer);
        console.log("SubscriberRegistry deployed at:", address(registry));

        // 3. Deploy CreatorVault
        vault = new CreatorVault(deployer);
        console.log("CreatorVault deployed at:", address(vault));

        // 4. Deploy PaymentProcessor
        processor = new PaymentProcessor(
            address(factory),
            address(registry),
            address(vault),
            treasury,
            protocolFeeBps,
            deployer
        );
        console.log("PaymentProcessor deployed at:", address(processor));

        // 5. Deploy RecurPayRouter
        router = new RecurPayRouter(
            address(factory),
            address(registry),
            address(processor),
            address(vault),
            deployer
        );
        console.log("RecurPayRouter deployed at:", address(router));

        // 6. Configure contracts
        registry.setProcessor(address(processor));
        vault.setPaymentProcessor(address(processor));

        console.log("Configuration complete!");

        vm.stopBroadcast();

        // Log summary
        console.log("\n=== Deployment Summary ===");
        console.log("Factory:", address(factory));
        console.log("Registry:", address(registry));
        console.log("Vault:", address(vault));
        console.log("Processor:", address(processor));
        console.log("Router:", address(router));
        console.log("Treasury:", treasury);
        console.log("Protocol Fee:", protocolFeeBps, "bps");
    }
}