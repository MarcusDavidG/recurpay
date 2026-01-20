// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

contract VerifyContracts is Script {
    function run() public view {
        console.log("Contract Verification Commands for Base Mainnet:");
        console.log("");
        console.log("Run these commands after deployment:");
        console.log("");
        console.log("1. SubscriptionFactory:");
        console.log("   forge verify-contract <FACTORY_ADDRESS> src/SubscriptionFactory.sol:SubscriptionFactory --chain base --constructor-args $(cast abi-encode 'constructor(address)' <OWNER>)");
        console.log("");
        console.log("2. SubscriberRegistry:");
        console.log("   forge verify-contract <REGISTRY_ADDRESS> src/SubscriberRegistry.sol:SubscriberRegistry --chain base --constructor-args $(cast abi-encode 'constructor(address,address)' <FACTORY> <OWNER>)");
        console.log("");
        console.log("3. CreatorVault:");
        console.log("   forge verify-contract <VAULT_ADDRESS> src/CreatorVault.sol:CreatorVault --chain base --constructor-args $(cast abi-encode 'constructor(address)' <OWNER>)");
        console.log("");
        console.log("4. PaymentProcessor:");
        console.log("   forge verify-contract <PROCESSOR_ADDRESS> src/PaymentProcessor.sol:PaymentProcessor --chain base --constructor-args $(cast abi-encode 'constructor(address,address,address,address,uint16,address)' <FACTORY> <REGISTRY> <VAULT> <TREASURY> <FEE_BPS> <OWNER>)");
        console.log("");
        console.log("5. RecurPayRouter:");
        console.log("   forge verify-contract <ROUTER_ADDRESS> src/RecurPayRouter.sol:RecurPayRouter --chain base --constructor-args $(cast abi-encode 'constructor(address,address,address,address,address)' <FACTORY> <REGISTRY> <PROCESSOR> <VAULT> <OWNER>)");
    }
}
