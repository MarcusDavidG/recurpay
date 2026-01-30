// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionProxy {
    address public implementation;
    address public admin;
    
    mapping(bytes4 => address) public implementations;

    event ImplementationUpdated(address newImplementation);
    event FunctionRouted(bytes4 selector, address implementation);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    function updateImplementation(address newImplementation) external onlyAdmin {
        implementation = newImplementation;
        emit ImplementationUpdated(newImplementation);
    }

    function setFunctionImplementation(bytes4 selector, address impl) external onlyAdmin {
        implementations[selector] = impl;
        emit FunctionRouted(selector, impl);
    }

    fallback() external payable {
        address impl = implementations[msg.sig];
        if (impl == address(0)) {
            impl = implementation;
        }
        
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
