import 'package:supabase_flutter/supabase_flutter.dart';

// --- Data Models for the App ---

class AppUser {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      fullName: json['full_name'],
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Bot {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final String? description;
  final String creatorId;
  final String jsonConfig;
  final bool isPublic;
  final DateTime createdAt;

  Bot({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.description,
    required this.creatorId,
    required this.jsonConfig,
    required this.isPublic,
    required this.createdAt,
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
    return Bot(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      description: json['description'],
      creatorId: json['creator_id'],
      jsonConfig: json['json_config'] ?? json['js_code'] ?? '{}', // Backward compatibility
      isPublic: json['is_public'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'avatar_url': avatarUrl,
      'description': description,
      'creator_id': creatorId,
      'json_config': jsonConfig,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderUsername;
  final String content;
  final DateTime timestamp;
  final String messageType; // 'text', 'bot_response'

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderUsername,
    required this.content,
    required this.timestamp,
    this.messageType = 'text',
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      senderUsername: json['sender_username'],
      content: json['content'],
      timestamp: DateTime.parse(json['created_at']),
      messageType: json['message_type'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_username': senderUsername,
      'content': content,
      'created_at': timestamp.toIso8601String(),
      'message_type': messageType,
    };
  }
}

class Chat {
  final String id;
  final String? name;
  final String? username; // Added for group username
  final String type; // 'direct', 'group', 'bot'
  final List<String> participantIds;
  final Map<String, String> participantUsernames;
  final String? botId;
  final String? creatorId; // Added to track group creator/admin
  final List<String>? adminIds; // Added for multiple admins
  final bool isPrivate; // Added for private/public groups
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final bool isPinned; // Added for pinning chats

  Chat({
    required this.id,
    this.name,
    this.username,
    required this.type,
    required this.participantIds,
    required this.participantUsernames,
    this.botId,
    this.creatorId,
    this.adminIds,
    this.isPrivate = false,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.isPinned = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    try {
      return Chat(
        id: json['id'] ?? '',
        name: json['name'],
        username: json['username'],
        type: json['type'] ?? 'direct',
        participantIds: json['participant_ids'] != null 
            ? List<String>.from(json['participant_ids']) 
            : [],
        participantUsernames: json['participant_usernames'] != null 
            ? Map<String, String>.from(json['participant_usernames']) 
            : {},
        botId: json['bot_id'],
        creatorId: json['creator_id'],
        adminIds: json['admin_ids'] != null 
            ? List<String>.from(json['admin_ids']) 
            : null,
        isPrivate: json['is_private'] ?? false,
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at']) 
            : DateTime.now(),
        lastMessageAt: json['last_message_at'] != null 
            ? DateTime.parse(json['last_message_at']) 
            : null,
        lastMessage: json['last_message'],
        isPinned: json['is_pinned'] ?? false,
      );
    } catch (e) {
      print('Error parsing chat JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  String get displayName {
    if (name != null) return name!;
    if (type == 'bot') return participantUsernames.values.first;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final otherUsernames = participantUsernames.entries
        .where((entry) => entry.key != currentUserId)
        .map((entry) => entry.value)
        .toList();
    return otherUsernames.isNotEmpty ? otherUsernames.join(', ') : 'Unknown';
  }

  bool isUserAdmin(String userId) {
    return creatorId == userId || (adminIds?.contains(userId) ?? false);
  }
}