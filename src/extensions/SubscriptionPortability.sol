// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionPortability {
    struct ExportData {
        bytes32 exportId;
        address creator;
        address subscriber;
        uint256 createdAt;
        uint256 expiresAt;
        bytes encryptedData;
        bool used;
        string dataHash;
    }

    struct ImportRequest {
        bytes32 importId;
        address newCreator;
        address subscriber;
        bytes32 originalExportId;
        uint256 requestedAt;
        bool approved;
        bool processed;
        string migrationReason;
    }

    mapping(bytes32 => ExportData) public exports;
    mapping(bytes32 => ImportRequest) public importRequests;
    mapping(address => bytes32[]) public userExports;
    mapping(address => bytes32[]) public creatorImports;
    
    uint256 public exportCounter;
    uint256 public importCounter;
    uint256 public constant EXPORT_VALIDITY_PERIOD = 30 days;

    event DataExported(bytes32 indexed exportId, address indexed creator, address indexed subscriber);
    event ImportRequested(bytes32 indexed importId, address indexed newCreator, bytes32 indexed exportId);
    event ImportApproved(bytes32 indexed importId, address indexed subscriber);
    event MigrationCompleted(bytes32 indexed importId, address indexed oldCreator, address indexed newCreator);

    function exportSubscriptionData(
        address subscriber,
        bytes memory encryptedData,
        string memory dataHash
    ) external returns (bytes32 exportId) {
        exportId = keccak256(abi.encodePacked(
            msg.sender,
            subscriber,
            block.timestamp,
            exportCounter++
        ));

        exports[exportId] = ExportData({
            exportId: exportId,
            creator: msg.sender,
            subscriber: subscriber,
            createdAt: block.timestamp,
            expiresAt: block.timestamp + EXPORT_VALIDITY_PERIOD,
            encryptedData: encryptedData,
            used: false,
            dataHash: dataHash
        });

        userExports[subscriber].push(exportId);

        emit DataExported(exportId, msg.sender, subscriber);
    }

    function requestImport(
        bytes32 exportId,
        string memory migrationReason
    ) external returns (bytes32 importId) {
        ExportData memory exportData = exports[exportId];
        require(exportData.creator != address(0), "Export not found");
        require(block.timestamp <= exportData.expiresAt, "Export expired");
        require(!exportData.used, "Export already used");

        importId = keccak256(abi.encodePacked(
            msg.sender,
            exportId,
            block.timestamp,
            importCounter++
        ));

        importRequests[importId] = ImportRequest({
            importId: importId,
            newCreator: msg.sender,
            subscriber: exportData.subscriber,
            originalExportId: exportId,
            requestedAt: block.timestamp,
            approved: false,
            processed: false,
            migrationReason: migrationReason
        });

        creatorImports[msg.sender].push(importId);

        emit ImportRequested(importId, msg.sender, exportId);
    }

    function approveImport(bytes32 importId) external {
        ImportRequest storage importReq = importRequests[importId];
        require(importReq.subscriber == msg.sender, "Not your subscription");
        require(!importReq.approved, "Already approved");
        require(!importReq.processed, "Already processed");

        importReq.approved = true;

        emit ImportApproved(importId, msg.sender);
    }

    function processImport(bytes32 importId) external {
        ImportRequest storage importReq = importRequests[importId];
        require(importReq.newCreator == msg.sender, "Not your import request");
        require(importReq.approved, "Not approved by subscriber");
        require(!importReq.processed, "Already processed");

        ExportData storage exportData = exports[importReq.originalExportId];
        require(!exportData.used, "Export already used");

        // Mark as processed and used
        importReq.processed = true;
        exportData.used = true;

        emit MigrationCompleted(importId, exportData.creator, msg.sender);
    }

    function batchExport(
        address[] memory subscribers,
        bytes[] memory encryptedDataArray,
        string[] memory dataHashes
    ) external returns (bytes32[] memory exportIds) {
        require(subscribers.length == encryptedDataArray.length, "Array length mismatch");
        require(subscribers.length == dataHashes.length, "Array length mismatch");

        exportIds = new bytes32[](subscribers.length);

        for (uint256 i = 0; i < subscribers.length; i++) {
            exportIds[i] = exportSubscriptionData(
                subscribers[i],
                encryptedDataArray[i],
                dataHashes[i]
            );
        }
    }

    function getExportData(bytes32 exportId) external view returns (ExportData memory) {
        return exports[exportId];
    }

    function getImportRequest(bytes32 importId) external view returns (ImportRequest memory) {
        return importRequests[importId];
    }

    function getUserExports(address user) external view returns (bytes32[] memory) {
        return userExports[user];
    }

    function getCreatorImports(address creator) external view returns (bytes32[] memory) {
        return creatorImports[creator];
    }

    function isExportValid(bytes32 exportId) external view returns (bool) {
        ExportData memory exportData = exports[exportId];
        return exportData.creator != address(0) &&
               !exportData.used &&
               block.timestamp <= exportData.expiresAt;
    }

    function getPendingImports(address creator) external view returns (bytes32[] memory pending) {
        bytes32[] memory allImports = creatorImports[creator];
        uint256 pendingCount = 0;

        // Count pending imports
        for (uint256 i = 0; i < allImports.length; i++) {
            ImportRequest memory importReq = importRequests[allImports[i]];
            if (importReq.approved && !importReq.processed) {
                pendingCount++;
            }
        }

        // Create array of pending imports
        pending = new bytes32[](pendingCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allImports.length; i++) {
            ImportRequest memory importReq = importRequests[allImports[i]];
            if (importReq.approved && !importReq.processed) {
                pending[index] = allImports[i];
                index++;
            }
        }
    }

    function getSubscriberPendingApprovals(address subscriber) external view returns (bytes32[] memory pending) {
        // This would return all import requests waiting for subscriber approval
        // Simplified implementation
        bytes32[] memory pendingApprovals = new bytes32[](0);
        return pendingApprovals;
    }

    function extendExportValidity(bytes32 exportId, uint256 additionalTime) external {
        ExportData storage exportData = exports[exportId];
        require(exportData.creator == msg.sender, "Not your export");
        require(!exportData.used, "Export already used");
        require(additionalTime <= 30 days, "Extension too long");

        exportData.expiresAt += additionalTime;
    }

    function revokeExport(bytes32 exportId) external {
        ExportData storage exportData = exports[exportId];
        require(exportData.creator == msg.sender, "Not your export");
        require(!exportData.used, "Export already used");

        exportData.used = true; // Mark as used to prevent usage
    }
}
