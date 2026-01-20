// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

abstract contract DeployConfig is Script {
    // Network IDs
    uint256 constant BASE_MAINNET = 8453;
    uint256 constant BASE_SEPOLIA = 84532;

    // Configuration struct
    struct NetworkConfig {
        address treasury;
        uint16 protocolFeeBps;
        address[] supportedTokens;
    }

    function getConfig() public view returns (NetworkConfig memory) {
        if (block.chainid == BASE_MAINNET) {
            return getBaseMainnetConfig();
        } else if (block.chainid == BASE_SEPOLIA) {
            return getBaseSepoliaConfig();
        } else {
            return getLocalConfig();
        }
    }

    function getBaseMainnetConfig() internal pure returns (NetworkConfig memory) {
        address[] memory tokens = new address[](2);
        tokens[0] = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC on Base
        tokens[1] = 0x4200000000000000000000000000000000000006; // WETH on Base

        return NetworkConfig({
            treasury: address(0), // Set before deployment
            protocolFeeBps: 100, // 1%
            supportedTokens: tokens
        });
    }

    function getBaseSepoliaConfig() internal pure returns (NetworkConfig memory) {
        address[] memory tokens = new address[](0);

        return NetworkConfig({
            treasury: address(0), // Set before deployment
            protocolFeeBps: 100,
            supportedTokens: tokens
        });
    }

    function getLocalConfig() internal pure returns (NetworkConfig memory) {
        address[] memory tokens = new address[](0);

        return NetworkConfig({
            treasury: address(1), // Placeholder
            protocolFeeBps: 100,
            supportedTokens: tokens
        });
    }
}
