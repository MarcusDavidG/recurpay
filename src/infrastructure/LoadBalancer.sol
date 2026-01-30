// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract LoadBalancer {
    struct Server {
        address serverAddress;
        uint256 weight;
        uint256 currentLoad;
        bool active;
        uint256 responseTime;
    }

    mapping(bytes32 => Server) public servers;
    bytes32[] public serverList;
    uint256 public totalWeight;

    event ServerAdded(bytes32 indexed serverId, address serverAddress, uint256 weight);
    event LoadDistributed(bytes32 indexed serverId, uint256 load);

    function addServer(bytes32 serverId, address serverAddress, uint256 weight) external {
        require(!servers[serverId].active, "Server already exists");
        
        servers[serverId] = Server({
            serverAddress: serverAddress,
            weight: weight,
            currentLoad: 0,
            active: true,
            responseTime: 0
        });

        serverList.push(serverId);
        totalWeight += weight;

        emit ServerAdded(serverId, serverAddress, weight);
    }

    function distributeLoad(uint256 requestLoad) external returns (bytes32 selectedServer) {
        require(serverList.length > 0, "No servers available");
        
        // Weighted round-robin selection
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % totalWeight;
        uint256 currentWeight = 0;

        for (uint256 i = 0; i < serverList.length; i++) {
            bytes32 serverId = serverList[i];
            Server storage server = servers[serverId];
            
            if (!server.active) continue;
            
            currentWeight += server.weight;
            if (randomValue < currentWeight) {
                server.currentLoad += requestLoad;
                emit LoadDistributed(serverId, requestLoad);
                return serverId;
            }
        }

        // Fallback to first active server
        for (uint256 i = 0; i < serverList.length; i++) {
            if (servers[serverList[i]].active) {
                servers[serverList[i]].currentLoad += requestLoad;
                return serverList[i];
            }
        }

        revert("No active servers");
    }

    function updateServerLoad(bytes32 serverId, uint256 newLoad, uint256 responseTime) external {
        Server storage server = servers[serverId];
        require(server.active, "Server not active");
        
        server.currentLoad = newLoad;
        server.responseTime = responseTime;
    }

    function deactivateServer(bytes32 serverId) external {
        servers[serverId].active = false;
        totalWeight -= servers[serverId].weight;
    }

    function getOptimalServer() external view returns (bytes32) {
        bytes32 bestServer;
        uint256 lowestLoad = type(uint256).max;

        for (uint256 i = 0; i < serverList.length; i++) {
            bytes32 serverId = serverList[i];
            Server memory server = servers[serverId];
            
            if (server.active && server.currentLoad < lowestLoad) {
                lowestLoad = server.currentLoad;
                bestServer = serverId;
            }
        }

        return bestServer;
    }
}
