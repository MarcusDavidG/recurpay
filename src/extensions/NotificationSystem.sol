// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract NotificationSystem {
    enum NotificationType {
        PAYMENT_DUE,
        PAYMENT_FAILED,
        SUBSCRIPTION_EXPIRING,
        SUBSCRIPTION_CANCELLED,
        TIER_UPGRADED,
        GIFT_RECEIVED,
        REFERRAL_REWARD
    }

    struct Notification {
        uint256 id;
        address recipient;
        NotificationType notificationType;
        string message;
        bytes data;
        uint256 createdAt;
        bool read;
        uint256 priority; // 1 = low, 2 = medium, 3 = high
    }

    mapping(address => uint256[]) public userNotifications;
    mapping(uint256 => Notification) public notifications;
    mapping(address => mapping(NotificationType => bool)) public notificationPreferences;
    
    uint256 public notificationCounter;

    event NotificationCreated(uint256 indexed notificationId, address indexed recipient, NotificationType notificationType);
    event NotificationRead(uint256 indexed notificationId, address indexed recipient);
    event PreferencesUpdated(address indexed user, NotificationType notificationType, bool enabled);

    function createNotification(
        address recipient,
        NotificationType notificationType,
        string memory message,
        bytes memory data,
        uint256 priority
    ) external returns (uint256 notificationId) {
        require(recipient != address(0), "Invalid recipient");
        require(priority >= 1 && priority <= 3, "Invalid priority");

        // Check if user has enabled this notification type
        if (!notificationPreferences[recipient][notificationType]) {
            return 0; // Don't create notification if disabled
        }

        notificationId = ++notificationCounter;

        notifications[notificationId] = Notification({
            id: notificationId,
            recipient: recipient,
            notificationType: notificationType,
            message: message,
            data: data,
            createdAt: block.timestamp,
            read: false,
            priority: priority
        });

        userNotifications[recipient].push(notificationId);

        emit NotificationCreated(notificationId, recipient, notificationType);
    }

    function markAsRead(uint256 notificationId) external {
        Notification storage notification = notifications[notificationId];
        require(notification.recipient == msg.sender, "Not your notification");
        require(!notification.read, "Already read");

        notification.read = true;
        emit NotificationRead(notificationId, msg.sender);
    }

    function markMultipleAsRead(uint256[] memory notificationIds) external {
        for (uint256 i = 0; i < notificationIds.length; i++) {
            Notification storage notification = notifications[notificationIds[i]];
            if (notification.recipient == msg.sender && !notification.read) {
                notification.read = true;
                emit NotificationRead(notificationIds[i], msg.sender);
            }
        }
    }

    function setNotificationPreference(NotificationType notificationType, bool enabled) external {
        notificationPreferences[msg.sender][notificationType] = enabled;
        emit PreferencesUpdated(msg.sender, notificationType, enabled);
    }

    function setMultiplePreferences(
        NotificationType[] memory notificationTypes,
        bool[] memory enabled
    ) external {
        require(notificationTypes.length == enabled.length, "Array length mismatch");
        
        for (uint256 i = 0; i < notificationTypes.length; i++) {
            notificationPreferences[msg.sender][notificationTypes[i]] = enabled[i];
            emit PreferencesUpdated(msg.sender, notificationTypes[i], enabled[i]);
        }
    }

    function getUserNotifications(address user) external view returns (uint256[] memory) {
        return userNotifications[user];
    }

    function getUnreadNotifications(address user) external view returns (uint256[] memory unread) {
        uint256[] memory allNotifications = userNotifications[user];
        uint256 unreadCount = 0;

        // Count unread notifications
        for (uint256 i = 0; i < allNotifications.length; i++) {
            if (!notifications[allNotifications[i]].read) {
                unreadCount++;
            }
        }

        // Create array of unread notifications
        unread = new uint256[](unreadCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allNotifications.length; i++) {
            if (!notifications[allNotifications[i]].read) {
                unread[index] = allNotifications[i];
                index++;
            }
        }
    }

    function getNotification(uint256 notificationId) external view returns (Notification memory) {
        return notifications[notificationId];
    }

    function getNotificationsByType(
        address user,
        NotificationType notificationType
    ) external view returns (uint256[] memory filtered) {
        uint256[] memory allNotifications = userNotifications[user];
        uint256 filteredCount = 0;

        // Count notifications of specific type
        for (uint256 i = 0; i < allNotifications.length; i++) {
            if (notifications[allNotifications[i]].notificationType == notificationType) {
                filteredCount++;
            }
        }

        // Create filtered array
        filtered = new uint256[](filteredCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allNotifications.length; i++) {
            if (notifications[allNotifications[i]].notificationType == notificationType) {
                filtered[index] = allNotifications[i];
                index++;
            }
        }
    }
}
