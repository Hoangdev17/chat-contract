// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Chat is ReentrancyGuard {
    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }

    mapping(bytes32 => Message[]) private conversations;
    mapping(address => bytes32[]) private userConversations;

    event Messagesent(address indexed sender, address indexed receiver, string content, uint timestamp);
    event MessageDeleted(address indexed sender, address indexed receiver, uint index);
    event ConversationCleared(address indexed user1, address indexed user2);

    modifier validAddress(address _addr){
        require(_addr != address(0), "Invalid address");
        _;
    }

    function _getConversationId(address user1, address user2) internal pure returns (bytes32){
        if(user1<user2){
            return keccak256(abi.encodePacked(user1, user2));
        } else {
            return keccak256(abi.encodePacked(user2, user1));
        }
    }

    function sendMessage(address receiver, string calldata content) external validAddress(receiver) nonReentrant {
        require(bytes(content).length > 0, "Message cannot be empty");
        bytes32 conversationId = _getConversationId(msg.sender, receiver);

        conversations[conversationId].push(Message({
            sender: msg.sender,
            content: content,
            timestamp: block.timestamp
        }));

        userConversations[msg.sender].push(conversationId);
        userConversations[receiver].push(conversationId);

        emit Messagesent(msg.sender, receiver, content, block.timestamp);
    }

    function getUserConversations(address user) external view returns (bytes32[] memory) {
        return userConversations[user];
    }

    function getConversation(address user) external view validAddress(user) returns (Message[] memory){
        bytes32 conversationId = _getConversationId(msg.sender, user);
        return conversations[conversationId];
    }

    function deleteMessage(address user, uint256 index) external validAddress(user) nonReentrant {
        bytes32 conversationId = _getConversationId(msg.sender, user);
        require(index < conversations[conversationId].length, "Invalid message index");
        Message memory msgToDelete = conversations[conversationId][index];
        require(msgToDelete.sender == msg.sender, "Can only delete own messages");

        uint256 lastIndex = conversations[conversationId].length -1;
        if(index != lastIndex){
            conversations[conversationId][index] = conversations[conversationId][lastIndex];
        }
        conversations[conversationId].pop();

        emit MessageDeleted(msg.sender, user, index);
    }

    function clearConversation(address user) external validAddress(user) nonReentrant {
        bytes32 conversationId = _getConversationId(msg.sender, user);
        uint256 length = conversations[conversationId].length;
        require(length > 0, "No conversation to clear");

        delete conversations[conversationId];

        emit ConversationCleared(msg.sender, user);
    }
}