// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

contract VerifyContracts is Script {
    function run() external {
        address factory = vm.envAddress("FACTORY_ADDRESS");
        address registry = vm.envAddress("REGISTRY_ADDRESS");
        address processor = vm.envAddress("PROCESSOR_ADDRESS");
        address vault = vm.envAddress("VAULT_ADDRESS");
        
        console.log("Verifying contracts on BaseScan...");
        
        // Verify SubscriptionFactory
        string[] memory factoryCmd = new string[](7);
        factoryCmd[0] = "forge";
        factoryCmd[1] = "verify-contract";
        factoryCmd[2] = vm.toString(factory);
        factoryCmd[3] = "src/SubscriptionFactory.sol:SubscriptionFactory";
        factoryCmd[4] = "--chain";
        factoryCmd[5] = "base";
        factoryCmd[6] = "--watch";
        
        vm.ffi(factoryCmd);
        console.log("Factory verified");
        
        // Verify SubscriberRegistry
        string[] memory registryCmd = new string[](7);
        registryCmd[0] = "forge";
        registryCmd[1] = "verify-contract";
        registryCmd[2] = vm.toString(registry);
        registryCmd[3] = "src/SubscriberRegistry.sol:SubscriberRegistry";
        registryCmd[4] = "--chain";
        registryCmd[5] = "base";
        registryCmd[6] = "--watch";
        
        vm.ffi(registryCmd);
        console.log("Registry verified");
        
        // Verify PaymentProcessor
        string[] memory processorCmd = new string[](7);
        processorCmd[0] = "forge";
        processorCmd[1] = "verify-contract";
        processorCmd[2] = vm.toString(processor);
        processorCmd[3] = "src/PaymentProcessor.sol:PaymentProcessor";
        processorCmd[4] = "--chain";
        processorCmd[5] = "base";
        processorCmd[6] = "--watch";
        
        vm.ffi(processorCmd);
        console.log("Processor verified");
        
        // Verify CreatorVault
        string[] memory vaultCmd = new string[](7);
        vaultCmd[0] = "forge";
        vaultCmd[1] = "verify-contract";
        vaultCmd[2] = vm.toString(vault);
        vaultCmd[3] = "src/CreatorVault.sol:CreatorVault";
        vaultCmd[4] = "--chain";
        vaultCmd[5] = "base";
        vaultCmd[6] = "--watch";
        
        vm.ffi(vaultCmd);
        console.log("Vault verified");
        
        console.log("All contracts verified successfully!");
    }
}
