// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionDerivatives {
    enum DerivativeType { CALL, PUT, FORWARD }

    struct Derivative {
        DerivativeType derivativeType;
        address creator;
        address buyer;
        uint256 subscriptionId;
        uint256 strikePrice;
        uint256 premium;
        uint256 expiryTime;
        bool exercised;
        bool settled;
    }

    mapping(bytes32 => Derivative) public derivatives;
    mapping(address => bytes32[]) public userDerivatives;

    event DerivativeCreated(bytes32 indexed derivativeId, DerivativeType derivativeType, uint256 strikePrice);
    event DerivativeExercised(bytes32 indexed derivativeId, address exerciser);

    function createDerivative(
        DerivativeType derivativeType,
        uint256 subscriptionId,
        uint256 strikePrice,
        uint256 premium,
        uint256 duration
    ) external returns (bytes32 derivativeId) {
        derivativeId = keccak256(abi.encodePacked(
            msg.sender, 
            derivativeType, 
            subscriptionId, 
            block.timestamp
        ));
        
        derivatives[derivativeId] = Derivative({
            derivativeType: derivativeType,
            creator: msg.sender,
            buyer: address(0),
            subscriptionId: subscriptionId,
            strikePrice: strikePrice,
            premium: premium,
            expiryTime: block.timestamp + duration,
            exercised: false,
            settled: false
        });

        userDerivatives[msg.sender].push(derivativeId);
        emit DerivativeCreated(derivativeId, derivativeType, strikePrice);
    }

    function buyDerivative(bytes32 derivativeId) external payable {
        Derivative storage derivative = derivatives[derivativeId];
        require(derivative.buyer == address(0), "Already sold");
        require(msg.value >= derivative.premium, "Insufficient premium");
        require(block.timestamp < derivative.expiryTime, "Expired");

        derivative.buyer = msg.sender;
        userDerivatives[msg.sender].push(derivativeId);

        // Transfer premium to creator
        (bool success, ) = payable(derivative.creator).call{value: msg.value}("");
        require(success, "Premium transfer failed");
    }

    function exerciseDerivative(bytes32 derivativeId) external payable {
        Derivative storage derivative = derivatives[derivativeId];
        require(derivative.buyer == msg.sender, "Not buyer");
        require(block.timestamp <= derivative.expiryTime, "Expired");
        require(!derivative.exercised, "Already exercised");

        derivative.exercised = true;

        if (derivative.derivativeType == DerivativeType.CALL) {
            require(msg.value >= derivative.strikePrice, "Insufficient payment");
            // Transfer strike price to creator, subscription to buyer
        } else if (derivative.derivativeType == DerivativeType.PUT) {
            // Creator must buy subscription at strike price
        }

        emit DerivativeExercised(derivativeId, msg.sender);
    }

    function settleDerivative(bytes32 derivativeId) external {
        Derivative storage derivative = derivatives[derivativeId];
        require(block.timestamp > derivative.expiryTime, "Not expired");
        require(!derivative.settled, "Already settled");

        derivative.settled = true;
        // Settlement logic based on derivative type
    }

    function getDerivative(bytes32 derivativeId) external view returns (Derivative memory) {
        return derivatives[derivativeId];
    }

    function getUserDerivatives(address user) external view returns (bytes32[] memory) {
        return userDerivatives[user];
    }
}
