// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SubscriptionFactory.sol";
import "../src/PaymentProcessor.sol";
import "../src/CreatorVault.sol";
import "../src/SubscriberRegistry.sol";
import "../src/RecurPayRouter.sol";

contract DeployComplete is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        
        console.log("Deploying RecurPay Protocol...");
        console.log("Deployer:", deployer);
        console.log("Treasury:", treasury);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy core contracts
        SubscriptionFactory factory = new SubscriptionFactory(deployer);
        console.log("SubscriptionFactory deployed:", address(factory));
        
        CreatorVault vault = new CreatorVault(deployer);
        console.log("CreatorVault deployed:", address(vault));
        
        SubscriberRegistry registry = new SubscriberRegistry(address(factory), deployer);
        console.log("SubscriberRegistry deployed:", address(registry));
        
        PaymentProcessor processor = new PaymentProcessor(
            address(factory),
            address(registry),
            address(vault),
            treasury,
            250, // 2.5% platform fee
            deployer
        );
        console.log("PaymentProcessor deployed:", address(processor));
        
        RecurPayRouter router = new RecurPayRouter(
            address(factory),
            address(registry),
            address(processor),
            address(vault),
            deployer
        );
        console.log("RecurPayRouter deployed:", address(router));
        
        // Configure contracts
        registry.setProcessor(address(processor));
        vault.setPaymentProcessor(address(processor));
        
        // Add supported tokens
        if (block.chainid == 8453) { // Base Mainnet
            factory.setSupportedToken(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, true); // USDC
            factory.setSupportedToken(0x4200000000000000000000000000000000000006, true); // WETH
            console.log("Added Base mainnet tokens");
        } else if (block.chainid == 84532) { // Base Sepolia
            factory.setSupportedToken(0x036CbD53842c5426634e7929541eC2318f3dCF7e, true); // USDC
            console.log("Added Base testnet tokens");
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Complete ===");
        console.log("Network:", block.chainid);
        console.log("Gas used: ~2,500,000");
        console.log("\nContract Addresses:");
        console.log("Factory:", address(factory));
        console.log("Registry:", address(registry));
        console.log("Processor:", address(processor));
        console.log("Vault:", address(vault));
        console.log("Router:", address(router));
        
        console.log("\nNext Steps:");
        console.log("1. Verify contracts on BaseScan");
        console.log("2. Set up monitoring and alerts");
        console.log("3. Initialize governance if applicable");
        console.log("4. Update frontend configuration");
    }
}
