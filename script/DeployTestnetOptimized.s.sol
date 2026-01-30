// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SubscriptionFactory.sol";
import "../src/PaymentProcessor.sol";
import "../src/CreatorVault.sol";
import "../src/SubscriberRegistry.sol";

contract DeployTestnetOptimized is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying to testnet with optimizations...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy with minimal gas usage
        SubscriptionFactory factory = new SubscriptionFactory{salt: keccak256("factory")}(deployer);
        CreatorVault vault = new CreatorVault{salt: keccak256("vault")}(deployer);
        SubscriberRegistry registry = new SubscriberRegistry{salt: keccak256("registry")}(address(factory), deployer);
        
        PaymentProcessor processor = new PaymentProcessor{salt: keccak256("processor")}(
            address(factory),
            address(registry),
            address(vault),
            deployer, // Use deployer as treasury for testnet
            100, // 1% fee for testnet
            deployer
        );
        
        // Configure contracts
        registry.setProcessor(address(processor));
        vault.setPaymentProcessor(address(processor));
        
        // Add testnet tokens
        if (block.chainid == 84532) { // Base Sepolia
            factory.setSupportedToken(0x036CbD53842c5426634e7929541eC2318f3dCF7e, true); // USDC
        }
        
        vm.stopBroadcast();
        
        console.log("Testnet deployment completed:");
        console.log("Factory:", address(factory));
        console.log("Registry:", address(registry));
        console.log("Processor:", address(processor));
        console.log("Vault:", address(vault));
    }
}
