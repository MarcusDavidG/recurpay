// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SubscriptionFactory.sol";
import "../src/PaymentProcessor.sol";
import "../src/CreatorVault.sol";
import "../src/SubscriberRegistry.sol";

contract DeployMainnet is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy contracts with mainnet configuration
        SubscriptionFactory factory = new SubscriptionFactory(deployer);
        CreatorVault vault = new CreatorVault(deployer);
        SubscriberRegistry registry = new SubscriberRegistry(address(factory), deployer);
        
        PaymentProcessor processor = new PaymentProcessor(
            address(factory),
            address(registry),
            address(vault),
            0x742d35Cc6634C0532925a3b8D4C9db96c4b4d8b6, // Base treasury
            250, // 2.5% fee for mainnet
            deployer
        );
        
        // Configure contracts
        registry.setProcessor(address(processor));
        vault.setPaymentProcessor(address(processor));
        
        // Add supported tokens (USDC, WETH, etc.)
        factory.setSupportedToken(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, true); // USDC on Base
        factory.setSupportedToken(0x4200000000000000000000000000000000000006, true); // WETH on Base
        
        vm.stopBroadcast();
        
        console.log("SubscriptionFactory deployed to:", address(factory));
        console.log("PaymentProcessor deployed to:", address(processor));
        console.log("CreatorVault deployed to:", address(vault));
        console.log("SubscriberRegistry deployed to:", address(registry));
    }
}
