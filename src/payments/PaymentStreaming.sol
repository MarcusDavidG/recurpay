// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PaymentStreaming {
    struct Stream {
        address sender;
        address recipient;
        uint256 totalAmount;
        uint256 startTime;
        uint256 duration;
        uint256 withdrawn;
        bool active;
    }

    mapping(bytes32 => Stream) public streams;
    mapping(address => bytes32[]) public userStreams;

    event StreamCreated(bytes32 indexed streamId, address sender, address recipient, uint256 amount);
    event StreamWithdrawn(bytes32 indexed streamId, uint256 amount);

    function createStream(
        address recipient,
        uint256 duration
    ) external payable returns (bytes32 streamId) {
        streamId = keccak256(abi.encodePacked(msg.sender, recipient, block.timestamp));
        
        streams[streamId] = Stream({
            sender: msg.sender,
            recipient: recipient,
            totalAmount: msg.value,
            startTime: block.timestamp,
            duration: duration,
            withdrawn: 0,
            active: true
        });

        userStreams[recipient].push(streamId);
        emit StreamCreated(streamId, msg.sender, recipient, msg.value);
    }

    function withdrawFromStream(bytes32 streamId) external {
        Stream storage stream = streams[streamId];
        require(stream.recipient == msg.sender, "Not recipient");
        require(stream.active, "Stream not active");

        uint256 available = getAvailableAmount(streamId);
        require(available > 0, "No funds available");

        stream.withdrawn += available;
        (bool success, ) = payable(msg.sender).call{value: available}("");
        require(success, "Transfer failed");

        emit StreamWithdrawn(streamId, available);
    }

    function getAvailableAmount(bytes32 streamId) public view returns (uint256) {
        Stream memory stream = streams[streamId];
        if (!stream.active) return 0;

        uint256 elapsed = block.timestamp - stream.startTime;
        if (elapsed >= stream.duration) {
            return stream.totalAmount - stream.withdrawn;
        }

        uint256 totalAvailable = (stream.totalAmount * elapsed) / stream.duration;
        return totalAvailable - stream.withdrawn;
    }
}
