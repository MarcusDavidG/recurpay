// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library GasOptimizer {
    // Pack multiple boolean values into a single storage slot
    struct PackedBools {
        uint256 data;
    }

    function setBool(PackedBools storage packed, uint256 index, bool value) internal {
        require(index < 256, "Index out of bounds");
        
        if (value) {
            packed.data |= (1 << index);
        } else {
            packed.data &= ~(1 << index);
        }
    }

    function getBool(PackedBools storage packed, uint256 index) internal view returns (bool) {
        require(index < 256, "Index out of bounds");
        return (packed.data >> index) & 1 == 1;
    }

    // Pack multiple uint8 values into a single storage slot
    struct PackedUint8s {
        uint256 data;
    }

    function setUint8(PackedUint8s storage packed, uint256 index, uint8 value) internal {
        require(index < 32, "Index out of bounds");
        
        uint256 shift = index * 8;
        uint256 mask = 0xFF << shift;
        
        packed.data = (packed.data & ~mask) | (uint256(value) << shift);
    }

    function getUint8(PackedUint8s storage packed, uint256 index) internal view returns (uint8) {
        require(index < 32, "Index out of bounds");
        
        uint256 shift = index * 8;
        return uint8((packed.data >> shift) & 0xFF);
    }

    // Efficient array operations
    function efficientRemove(uint256[] storage array, uint256 index) internal {
        require(index < array.length, "Index out of bounds");
        
        array[index] = array[array.length - 1];
        array.pop();
    }

    function efficientRemove(address[] storage array, uint256 index) internal {
        require(index < array.length, "Index out of bounds");
        
        array[index] = array[array.length - 1];
        array.pop();
    }

    // Gas-efficient string comparison
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    // Batch operations helper
    function batchCall(
        address[] memory targets,
        bytes[] memory data
    ) internal returns (bool[] memory results) {
        require(targets.length == data.length, "Array length mismatch");
        
        results = new bool[](targets.length);
        
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call(data[i]);
            results[i] = success;
        }
    }

    // Efficient percentage calculation
    function calculatePercentage(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        return (amount * percentage) / 10000;
    }

    // Gas-efficient event emission
    event BatchEvent(bytes32 indexed batchId, uint256 count);
    
    function emitBatchEvent(bytes32 batchId, uint256 count) internal {
        emit BatchEvent(batchId, count);
    }
}
