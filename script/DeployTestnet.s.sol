// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DeployConfig} from "./DeployConfig.s.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {SubscriberRegistry} from "src/SubscriberRegistry.sol";
import {CreatorVault} from "src/CreatorVault.sol";
import {PaymentProcessor} from "src/PaymentProcessor.sol";
import {RecurPayRouter} from "src/RecurPayRouter.sol";

contract DeployTestnet is Script, DeployConfig {
    function run() public {
        NetworkConfig memory config = getConfig();

        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        
        // Use deployer as treasury for testnet if not set
        address treasury = config.treasury == address(0) ? deployer : config.treasury;

        console.log("Deploying to chain:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Treasury:", treasury);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Deploy contracts
        SubscriptionFactory factory = new SubscriptionFactory(deployer);
        console.log("Factory:", address(factory));

        SubscriberRegistry registry = new SubscriberRegistry(address(factory), deployer);
        console.log("Registry:", address(registry));

        CreatorVault vault = new CreatorVault(deployer);
        console.log("Vault:", address(vault));

        PaymentProcessor processor = new PaymentProcessor(
            address(factory),
            address(registry),
            address(vault),
            treasury,
            config.protocolFeeBps,
            deployer
        );
        console.log("Processor:", address(processor));

        RecurPayRouter router = new RecurPayRouter(
            address(factory),
            address(registry),
            address(processor),
            address(vault),
            deployer
        );
        console.log("Router:", address(router));

        // Configure
        registry.setProcessor(address(processor));
        vault.setPaymentProcessor(address(processor));

        // Add supported tokens
        for (uint256 i = 0; i < config.supportedTokens.length; i++) {
            factory.setSupportedToken(config.supportedTokens[i], true);
        }

        vm.stopBroadcast();

        console.log("\nDeployment complete!");
    }
}
