// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionUtils {
    function encodeSubscriptionData(
        address creator,
        uint256 price,
        uint256 duration,
        string memory name
    ) external pure returns (bytes memory) {
        return abi.encode(creator, price, duration, name);
    }

    function decodeSubscriptionData(bytes memory data) external pure returns (
        address creator,
        uint256 price,
        uint256 duration,
        string memory name
    ) {
        return abi.decode(data, (address, uint256, uint256, string));
    }

    function hashSubscriptionData(
        address creator,
        uint256 price,
        uint256 duration
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(creator, price, duration));
    }

    function verifySignature(
        bytes32 hash,
        bytes memory signature,
        address signer
    ) external pure returns (bool) {
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        
        if (signature.length != 65) return false;
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        if (v < 27) v += 27;
        
        return ecrecover(ethSignedMessageHash, v, r, s) == signer;
    }

    function calculateSubscriptionHash(
        address subscriber,
        uint256 planId,
        uint256 startTime
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(subscriber, planId, startTime));
    }

    function isValidAddress(address addr) external pure returns (bool) {
        return addr != address(0);
    }

    function formatAmount(uint256 amount, uint8 decimals) external pure returns (string memory) {
        if (decimals == 0) return toString(amount);
        
        uint256 divisor = 10 ** decimals;
        uint256 whole = amount / divisor;
        uint256 fraction = amount % divisor;
        
        return string(abi.encodePacked(toString(whole), ".", toString(fraction)));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
        uint256 temp = value;
        uint256 digits;
        
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
}
