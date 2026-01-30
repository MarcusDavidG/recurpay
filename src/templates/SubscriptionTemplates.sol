// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionTemplates {
    struct Template {
        string name;
        uint256 price;
        uint256 duration;
        string[] features;
        string category;
        bool isPublic;
        address creator;
        uint256 usageCount;
    }

    mapping(bytes32 => Template) public templates;
    mapping(address => bytes32[]) public creatorTemplates;
    mapping(string => bytes32[]) public categoryTemplates;
    
    uint256 public templateCounter;

    event TemplateCreated(bytes32 indexed templateId, address indexed creator, string name);
    event TemplateUsed(bytes32 indexed templateId, address indexed user);

    function createTemplate(
        string memory name,
        uint256 price,
        uint256 duration,
        string[] memory features,
        string memory category,
        bool isPublic
    ) external returns (bytes32 templateId) {
        templateId = keccak256(abi.encodePacked(msg.sender, name, templateCounter++));
        
        templates[templateId] = Template({
            name: name,
            price: price,
            duration: duration,
            features: features,
            category: category,
            isPublic: isPublic,
            creator: msg.sender,
            usageCount: 0
        });

        creatorTemplates[msg.sender].push(templateId);
        categoryTemplates[category].push(templateId);

        emit TemplateCreated(templateId, msg.sender, name);
    }

    function useTemplate(bytes32 templateId) external {
        Template storage template = templates[templateId];
        require(template.isPublic || template.creator == msg.sender, "Template not accessible");
        
        template.usageCount++;
        emit TemplateUsed(templateId, msg.sender);
    }

    function getTemplate(bytes32 templateId) external view returns (Template memory) {
        return templates[templateId];
    }

    function getTemplatesByCategory(string memory category) external view returns (bytes32[] memory) {
        return categoryTemplates[category];
    }
}
