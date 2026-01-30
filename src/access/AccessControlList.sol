// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AccessControlList {
    mapping(bytes32 => mapping(address => bool)) public permissions;
    mapping(bytes32 => address[]) public permissionHolders;
    mapping(address => bytes32[]) public userPermissions;

    event PermissionGranted(bytes32 indexed permission, address indexed user);
    event PermissionRevoked(bytes32 indexed permission, address indexed user);

    function grantPermission(bytes32 permission, address user) external {
        if (!permissions[permission][user]) {
            permissions[permission][user] = true;
            permissionHolders[permission].push(user);
            userPermissions[user].push(permission);
            
            emit PermissionGranted(permission, user);
        }
    }

    function revokePermission(bytes32 permission, address user) external {
        if (permissions[permission][user]) {
            permissions[permission][user] = false;
            
            // Remove from permissionHolders array
            address[] storage holders = permissionHolders[permission];
            for (uint256 i = 0; i < holders.length; i++) {
                if (holders[i] == user) {
                    holders[i] = holders[holders.length - 1];
                    holders.pop();
                    break;
                }
            }
            
            emit PermissionRevoked(permission, user);
        }
    }

    function hasPermission(bytes32 permission, address user) external view returns (bool) {
        return permissions[permission][user];
    }

    function getPermissionHolders(bytes32 permission) external view returns (address[] memory) {
        return permissionHolders[permission];
    }

    function getUserPermissions(address user) external view returns (bytes32[] memory) {
        return userPermissions[user];
    }
}
