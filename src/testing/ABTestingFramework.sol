// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ABTestingFramework {
    struct ABTest {
        string testName;
        address creator;
        uint256 startTime;
        uint256 endTime;
        uint256 variantACount;
        uint256 variantBCount;
        uint256 variantAConversions;
        uint256 variantBConversions;
        bool active;
        string hypothesis;
    }

    mapping(bytes32 => ABTest) public tests;
    mapping(bytes32 => mapping(address => bool)) public userAssignments; // testId => user => isVariantB
    mapping(address => bytes32[]) public creatorTests;

    event TestCreated(bytes32 indexed testId, address indexed creator, string testName);
    event UserAssigned(bytes32 indexed testId, address indexed user, bool isVariantB);
    event ConversionRecorded(bytes32 indexed testId, address indexed user, bool isVariantB);

    function createTest(
        string memory testName,
        uint256 duration,
        string memory hypothesis
    ) external returns (bytes32 testId) {
        testId = keccak256(abi.encodePacked(msg.sender, testName, block.timestamp));
        
        tests[testId] = ABTest({
            testName: testName,
            creator: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            variantACount: 0,
            variantBCount: 0,
            variantAConversions: 0,
            variantBConversions: 0,
            active: true,
            hypothesis: hypothesis
        });

        creatorTests[msg.sender].push(testId);
        emit TestCreated(testId, msg.sender, testName);
    }

    function assignUser(bytes32 testId, address user) external returns (bool isVariantB) {
        ABTest storage test = tests[testId];
        require(test.active && block.timestamp <= test.endTime, "Test not active");
        
        // Simple random assignment based on user address
        isVariantB = uint256(keccak256(abi.encodePacked(user, testId))) % 2 == 1;
        userAssignments[testId][user] = isVariantB;
        
        if (isVariantB) {
            test.variantBCount++;
        } else {
            test.variantACount++;
        }

        emit UserAssigned(testId, user, isVariantB);
    }

    function recordConversion(bytes32 testId, address user) external {
        ABTest storage test = tests[testId];
        require(test.creator == msg.sender, "Not test creator");
        
        bool isVariantB = userAssignments[testId][user];
        if (isVariantB) {
            test.variantBConversions++;
        } else {
            test.variantAConversions++;
        }

        emit ConversionRecorded(testId, user, isVariantB);
    }
}
