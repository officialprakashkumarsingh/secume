import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_js/flutter_js.dart';
import 'dart:convert';
import 'dart:async';
import 'models.dart';

// --- Supabase Service ---

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Expose client for direct access when needed
  static SupabaseClient get client => _client;

  // Authentication
  static Future<AppUser?> signUp(String email, String password, String username, String fullName) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        // Create user profile
        await _client.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'username': username,
          'full_name': fullName,
          'created_at': DateTime.now().toIso8601String(),
        });

        return AppUser(
          id: response.user!.id,
          email: email,
          username: username,
          fullName: fullName,
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      print('Sign up error: $e');
    }
    return null;
  }

  static Future<AppUser?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userProfile = await _client
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return AppUser.fromJson(userProfile);
      }
    } catch (e) {
      print('Sign in error: $e');
    }
    return null;
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // User search - enhanced to work without @ symbol
  static Future<List<AppUser>> searchUsers(String query) async {
    try {
      // Remove @ symbol if present for user search
      final cleanQuery = query.startsWith('@') ? query.substring(1) : query;

      final response = await _client
          .from('users')
          .select()
          .or('username.ilike.%$cleanQuery%,full_name.ilike.%$cleanQuery%')
          .limit(20);

      return response.map<AppUser>((json) => AppUser.fromJson(json)).toList();
    } catch (e) {
      print('Search users error: $e');
      return [];
    }
  }

  // Bot search - enhanced to work without @ symbol
  static Future<List<Bot>> searchBots(String query) async {
    try {
      // Remove @ symbol if present for bot search
      final cleanQuery = query.startsWith('@') ? query.substring(1) : query;

      final response = await _client
          .from('bots')
          .select()
          .eq('is_public', true)
          .or('username.ilike.%$cleanQuery%,name.ilike.%$cleanQuery%')
          .limit(20);

      return response.map<Bot>((json) => Bot.fromJson(json)).toList();
    } catch (e) {
      print('Search bots error: $e');
      return [];
    }
  }

  // Chat management
  static Future<String?> createDirectChat(String otherUserId, String otherUsername) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return null;

      // Check if chat already exists
      final existingChat = await _client
          .from('chats')
          .select('id')
          .eq('type', 'direct')
          .contains('participant_ids', [currentUser.id, otherUserId])
          .maybeSingle();

      if (existingChat != null) {
        return existingChat['id'];
      }

      // Get current user info
      final currentUserProfile = await _client
          .from('users')
          .select('username')
          .eq('id', currentUser.id)
          .single();

      // Create new chat
      final chatResponse = await _client.from('chats').insert({
        'type': 'direct',
        'participant_ids': [currentUser.id, otherUserId],
        'participant_usernames': {
          currentUser.id: currentUserProfile['username'],
          otherUserId: otherUsername,
        },
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return chatResponse['id'];
    } catch (e) {
      print('Create direct chat error: $e');
      return null;
    }
  }

  static Future<String?> createBotChat(String botId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return null;

      // Check if chat already exists
      final existingChats = await _client
          .from('chats')
          .select()
          .eq('type', 'bot')
          .eq('bot_id', botId)
          .contains('participant_ids', [currentUser.id]);

      if (existingChats.isNotEmpty) {
        return existingChats.first['id'];
      }

      // Get bot info
      final bot = await getBotById(botId);
      if (bot == null) return null;

      // Create new bot chat
      final response = await _client.from('chats').insert({
        'type': 'bot',
        'bot_id': botId,
        'participant_ids': [currentUser.id],
        'participant_usernames': {currentUser.id: bot.username},
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return response['id'];
    } catch (e) {
      print('Create bot chat error: $e');
      return null;
    }
  }

  // Group creation and management functions
  static Future<String?> createGroup(String groupName, String groupUsername, List<String> participantIds, {String? description, bool isPrivate = false}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return null;

      // Check if group username already exists
      final existingGroup = await _client
          .from('chats')
          .select('id')
          .eq('username', groupUsername)
          .eq('type', 'group')
          .maybeSingle();

      if (existingGroup != null) {
        throw Exception('Group username already exists');
      }

      // Add current user to participants if not already included
      final allParticipants = Set<String>.from(participantIds);
      allParticipants.add(currentUser.id);

      // Get usernames for all participants
      final userResponse = await _client
          .from('users')
          .select('id, username')
          .inFilter('id', allParticipants.toList());

      final participantUsernames = <String, String>{};
      for (var user in userResponse) {
        participantUsernames[user['id']] = user['username'];
      }

      // Create the group chat
      final response = await _client.from('chats').insert({
        'name': groupName,
        'username': groupUsername,
        'type': 'group',
        'participant_ids': allParticipants.toList(),
        'participant_usernames': participantUsernames,
        'creator_id': currentUser.id,
        'admin_ids': [currentUser.id], // Creator is initial admin
        'is_private': isPrivate,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return response['id'];
    } catch (e) {
      print('Create group error: $e');
      return null;
    }
  }

  static Future<bool> addToGroup(String chatId, List<String> userIds) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Get current chat
      final chatResponse = await _client
          .from('chats')
          .select()
          .eq('id', chatId)
          .eq('type', 'group')
          .single();

      final currentParticipants = List<String>.from(chatResponse['participant_ids']);
      final currentUsernames = Map<String, String>.from(chatResponse['participant_usernames']);

      // Add new participants
      final newParticipants = Set<String>.from(currentParticipants);
      newParticipants.addAll(userIds);

      // Get usernames for new users
      final userResponse = await _client
          .from('users')
          .select('id, username')
          .inFilter('id', userIds);

      for (var user in userResponse) {
        currentUsernames[user['id']] = user['username'];
      }

      // Update the chat
      await _client.from('chats').update({
        'participant_ids': newParticipants.toList(),
        'participant_usernames': currentUsernames,
      }).eq('id', chatId);

      return true;
    } catch (e) {
      print('Add to group error: $e');
      return false;
    }
  }

  static Future<bool> removeFromGroup(String chatId, String userId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Get current chat
      final chatResponse = await _client
          .from('chats')
          .select()
          .eq('id', chatId)
          .eq('type', 'group')
          .single();

      final currentParticipants = List<String>.from(chatResponse['participant_ids']);
      final currentUsernames = Map<String, String>.from(chatResponse['participant_usernames']);
      final adminIds = List<String>.from(chatResponse['admin_ids'] ?? []);

      // Check if current user is admin
      if (!adminIds.contains(currentUser.id) && chatResponse['creator_id'] != currentUser.id) {
        return false; // Only admins can remove members
      }

      // Remove participant
      currentParticipants.remove(userId);
      currentUsernames.remove(userId);
      adminIds.remove(userId); // Remove from admins if they were admin

      // Update the chat
      await _client.from('chats').update({
        'participant_ids': currentParticipants,
        'participant_usernames': currentUsernames,
        'admin_ids': adminIds,
      }).eq('id', chatId);

      return true;
    } catch (e) {
      print('Remove from group error: $e');
      return false;
    }
  }

  static Future<bool> makeAdmin(String chatId, String userId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Get current chat
      final chatResponse = await _client
          .from('chats')
          .select()
          .eq('id', chatId)
          .eq('type', 'group')
          .single();

      // Only creator can make new admins
      if (chatResponse['creator_id'] != currentUser.id) {
        return false;
      }

      final adminIds = List<String>.from(chatResponse['admin_ids'] ?? []);
      if (!adminIds.contains(userId)) {
        adminIds.add(userId);
      }

      // Update the chat
      await _client.from('chats').update({
        'admin_ids': adminIds,
      }).eq('id', chatId);

      return true;
    } catch (e) {
      print('Make admin error: $e');
      return false;
    }
  }

  static Future<bool> removeAdmin(String chatId, String userId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Get current chat
      final chatResponse = await _client
          .from('chats')
          .select()
          .eq('id', chatId)
          .eq('type', 'group')
          .single();

      // Only creator can remove admins
      if (chatResponse['creator_id'] != currentUser.id) {
        return false;
      }

      final adminIds = List<String>.from(chatResponse['admin_ids'] ?? []);
      adminIds.remove(userId);

      // Update the chat
      await _client.from('chats').update({
        'admin_ids': adminIds,
      }).eq('id', chatId);

      return true;
    } catch (e) {
      print('Remove admin error: $e');
      return false;
    }
  }

  static Future<bool> deleteGroup(String chatId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Get current chat
      final chatResponse = await _client
          .from('chats')
          .select()
          .eq('id', chatId)
          .eq('type', 'group')
          .single();

      // Only creator can delete group
      if (chatResponse['creator_id'] != currentUser.id) {
        return false;
      }

      // Delete all messages first
      await _client.from('messages').delete().eq('chat_id', chatId);
      
      // Delete the group
      await _client.from('chats').delete().eq('id', chatId);

      return true;
    } catch (e) {
      print('Delete group error: $e');
      return false;
    }
  }

  static Future<bool> updateGroupInfo(String chatId, {String? name, String? username, bool? isPrivate}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Get current chat
      final chatResponse = await _client
          .from('chats')
          .select()
          .eq('id', chatId)
          .eq('type', 'group')
          .single();

      final adminIds = List<String>.from(chatResponse['admin_ids'] ?? []);
      
      // Check if current user is admin
      if (!adminIds.contains(currentUser.id) && chatResponse['creator_id'] != currentUser.id) {
        return false;
      }

      // Check if new username is unique (if provided)
      if (username != null && username != chatResponse['username']) {
        final existingGroup = await _client
            .from('chats')
            .select('id')
            .eq('username', username)
            .eq('type', 'group')
            .neq('id', chatId)
            .maybeSingle();

        if (existingGroup != null) {
          throw Exception('Group username already exists');
        }
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (username != null) updateData['username'] = username;
      if (isPrivate != null) updateData['is_private'] = isPrivate;

      // Update the chat
      await _client.from('chats').update(updateData).eq('id', chatId);

      return true;
    } catch (e) {
      print('Update group info error: $e');
      return false;
    }
  }

  static Future<Chat?> joinGroupByUsername(String groupUsername) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return null;

      // Find the group
      final groupResponse = await _client
          .from('chats')
          .select()
          .eq('username', groupUsername)
          .eq('type', 'group')
          .eq('is_private', false) // Only allow joining public groups
          .maybeSingle();

      if (groupResponse == null) {
        throw Exception('Group not found or is private');
      }

      final currentParticipants = List<String>.from(groupResponse['participant_ids']);
      final currentUsernames = Map<String, String>.from(groupResponse['participant_usernames']);

      // Check if user is already in group
      if (currentParticipants.contains(currentUser.id)) {
        return Chat.fromJson(groupResponse);
      }

      // Get current user info
      final userProfile = await _client
          .from('users')
          .select('username')
          .eq('id', currentUser.id)
          .single();

      // Add user to group
      currentParticipants.add(currentUser.id);
      currentUsernames[currentUser.id] = userProfile['username'];

      // Update the chat
      await _client.from('chats').update({
        'participant_ids': currentParticipants,
        'participant_usernames': currentUsernames,
      }).eq('id', groupResponse['id']);

      // Return updated chat
      final updatedResponse = await _client
          .from('chats')
          .select()
          .eq('id', groupResponse['id'])
          .single();

      return Chat.fromJson(updatedResponse);
    } catch (e) {
      print('Join group error: $e');
      return null;
    }
  }

  static Future<bool> pinChat(String chatId, bool isPinned) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Update the chat pin status for this user
      await _client.from('user_chat_preferences').upsert({
        'user_id': currentUser.id,
        'chat_id': chatId,
        'is_pinned': isPinned,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Pin chat error: $e');
      return false;
    }
  }

  static Future<List<Chat>> getUserChats() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('Loading chats for user: ${currentUser.id}');

      final response = await _client
          .from('chats')
          .select()
          .contains('participant_ids', [currentUser.id])
          .order('last_message_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      print('Retrieved ${response.length} chats from database');

      final chats = response.map<Chat>((json) => Chat.fromJson(json)).toList();

      // Get pinned status for each chat
      try {
        final pinnedResponse = await _client
            .from('user_chat_preferences')
            .select('chat_id, is_pinned')
            .eq('user_id', currentUser.id)
            .eq('is_pinned', true)
            .timeout(const Duration(seconds: 5));

        final pinnedChatIds = Set<String>.from(
          pinnedResponse.map<String>((row) => row['chat_id'] as String)
        );

        // Update pinned status
        for (int i = 0; i < chats.length; i++) {
          final chat = chats[i];
          chats[i] = Chat(
            id: chat.id,
            name: chat.name,
            username: chat.username,
            type: chat.type,
            participantIds: chat.participantIds,
            participantUsernames: chat.participantUsernames,
            botId: chat.botId,
            creatorId: chat.creatorId,
            adminIds: chat.adminIds,
            isPrivate: chat.isPrivate,
            createdAt: chat.createdAt,
            lastMessageAt: chat.lastMessageAt,
            lastMessage: chat.lastMessage,
            isPinned: pinnedChatIds.contains(chat.id),
          );
        }

        // Sort with pinned chats first
        chats.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          
          // If both are pinned or both are unpinned, sort by last message time
          final aTime = a.lastMessageAt ?? a.createdAt;
          final bTime = b.lastMessageAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
      } catch (e) {
        print('Error loading pinned status (table might not exist): $e');
        // If pinning table doesn't exist, just sort by last message time
        chats.sort((a, b) {
          final aTime = a.lastMessageAt ?? a.createdAt;
          final bTime = b.lastMessageAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
      }

      print('Successfully processed ${chats.length} chats');
      return chats;
    } catch (e) {
      print('Get user chats error: $e');
      return [];
    }
  }

  // Real-time chat list streaming
  static Stream<List<Chat>> getChatListStream() {
    final controller = StreamController<List<Chat>>.broadcast();
    final currentUser = _client.auth.currentUser;
    
    if (currentUser == null) {
      controller.addError('User not authenticated');
      controller.close();
      return controller.stream;
    }

    // Set up real-time listener for chat updates
    final channel = _client.channel('public:chats');

    void fetchAndPush() async {
      try {
        final chats = await getUserChats();
        if (!controller.isClosed) {
          controller.add(chats);
        }
      } catch (e) {
        print('Error fetching chats: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Load initial data immediately
    fetchAndPush();

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'chats',
      callback: (payload) {
        // Check if this change affects the current user
        final newRecord = payload.newRecord;
        final oldRecord = payload.oldRecord;
        
        bool affectsUser = false;
        
        if (newRecord != null && newRecord['participant_ids'] != null) {
          try {
            final participantIds = List<String>.from(newRecord['participant_ids']);
            affectsUser = participantIds.contains(currentUser.id);
          } catch (e) {
            print('Error parsing participant_ids from newRecord: $e');
          }
        }
        
        if (!affectsUser && oldRecord != null && oldRecord['participant_ids'] != null) {
          try {
            final participantIds = List<String>.from(oldRecord['participant_ids']);
            affectsUser = participantIds.contains(currentUser.id);
          } catch (e) {
            print('Error parsing participant_ids from oldRecord: $e');
          }
        }
        
        if (affectsUser) {
          fetchAndPush();
        }
      },
    ).subscribe((status, [error]) {
      print('Chat list subscription status: $status');
      if (error != null) {
        print('Chat list subscription error: $error');
      }
      
      if (status == 'SUBSCRIBED') {
        print('Successfully subscribed to chat list updates');
        // Data already loaded initially, no need to fetch again
      } else if (status == 'CHANNEL_ERROR' || status == 'TIMED_OUT') {
        print('Chat list subscription failed, using polling fallback');
        // Fall back to periodic updates if real-time fails
        Timer.periodic(const Duration(seconds: 10), (timer) {
          if (controller.isClosed) {
            timer.cancel();
            return;
          }
          fetchAndPush();
        });
      }
    });

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  // Message management
  static Future<Message?> sendMessage(String chatId, String content, {String messageType = 'text'}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return null;

      final userProfile = await _client
          .from('users')
          .select('username')
          .eq('id', currentUser.id)
          .single();

      final messageResponse = await _client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUser.id,
        'sender_username': userProfile['username'],
        'content': content,
        'message_type': messageType,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      // Update chat's last message
      await _client.from('chats').update({
        'last_message_at': DateTime.now().toIso8601String(),
        'last_message': content,
      }).eq('id', chatId);

      return Message.fromJson(messageResponse);
    } catch (e) {
      print('Send message error: $e');
      return null;
    }
  }

  static Future<List<Message>> getChatMessages(String chatId) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      return response.map<Message>((json) => Message.fromJson(json)).toList();
    } catch (e) {
      print('Get chat messages error: $e');
      return [];
    }
  }

  // Real-time message streaming
  static Stream<Message> getMessageStream(String chatId) {
    final controller = StreamController<Message>.broadcast();
    final channel = _client.channel('public:messages:chat_id=eq.$chatId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_id',
        value: chatId,
      ),
      callback: (payload) {
        final newMessage = Message.fromJson(payload.newRecord);
        if (!controller.isClosed) {
          controller.add(newMessage);
        }
      },
    ).subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  // Typing indicator functions
  static Future<void> setTyping(String chatId, bool isTyping) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return;

      if (isTyping) {
        await _client.from('typing_indicators').upsert({
          'chat_id': chatId,
          'user_id': currentUser.id,
          'is_typing': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _client
            .from('typing_indicators')
            .delete()
            .eq('chat_id', chatId)
            .eq('user_id', currentUser.id);
      }
    } catch (e) {
      print('Set typing error: $e');
    }
  }

  static Stream<List<String>> getTypingUsers(String chatId) {
    final controller = StreamController<List<String>>.broadcast();
    final channel = _client.channel('public:typing_indicators:chat_id=eq.$chatId');

    Future<void> fetchAndPush() async {
      try {
        final response = await _client
            .from('typing_indicators')
            .select('user_id')
            .eq('chat_id', chatId)
            .eq('is_typing', true);
        final userIds = response.map<String>((row) => row['user_id'] as String).toList();
        if (!controller.isClosed) {
          controller.add(userIds);
        }
      } catch (e) {
        print('Error fetching typing users: $e');
      }
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'typing_indicators',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_id',
        value: chatId,
      ),
      callback: (payload) {
        fetchAndPush();
      },
    ).subscribe((status, [error]) {
      if (status == 'SUBSCRIBED') {
        fetchAndPush();
      }
    });

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  // Online status functions
  static Future<void> setOnlineStatus(bool isOnline) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return;

      await _client.from('user_status').upsert({
        'user_id': currentUser.id,
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Set online status error: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserStatus(String userId) async {
    try {
      final response = await _client
          .from('user_status')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Get user status error: $e');
      return null;
    }
  }

  // Bot management
  static Future<Bot?> createBot(String name, String username, String jsCode, {String? description, bool isPublic = true}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return null;

      final botResponse = await _client.from('bots').insert({
        'name': name,
        'username': username,
        'description': description,
        'creator_id': currentUser.id,
        'js_code': jsCode,
        'is_public': isPublic,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return Bot.fromJson(botResponse);
    } catch (e) {
      print('Create bot error: $e');
      return null;
    }
  }

  static Future<List<Bot>> getUserBots() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _client
          .from('bots')
          .select()
          .eq('creator_id', currentUser.id)
          .order('created_at', ascending: false);

      return response.map<Bot>((json) => Bot.fromJson(json)).toList();
    } catch (e) {
      print('Get user bots error: $e');
      return [];
    }
  }

  static Future<Bot?> updateBot(String botId, {String? name, String? description, String? jsCode, bool? isPublic}) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (jsCode != null) updateData['js_code'] = jsCode;
      if (isPublic != null) updateData['is_public'] = isPublic;

      final response = await _client
          .from('bots')
          .update(updateData)
          .eq('id', botId)
          .select()
          .single();

      return Bot.fromJson(response);
    } catch (e) {
      print('Update bot error: $e');
      return null;
    }
  }

  static Future<bool> deleteBot(String botId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        print('Delete bot error: No authenticated user');
        return false;
      }

      // First check if the bot exists and belongs to the user
      final existingBot = await _client
          .from('bots')
          .select('id, creator_id')
          .eq('id', botId)
          .eq('creator_id', currentUser.id)
          .maybeSingle();

      if (existingBot == null) {
        print('Delete bot error: Bot not found or not owned by user');
        return false;
      }

      // Delete the bot
      final result = await _client
          .from('bots')
          .delete()
          .eq('id', botId)
          .eq('creator_id', currentUser.id);

      print('Delete bot successful for bot: $botId');
      return true;
    } catch (e) {
      print('Delete bot error: $e');
      return false;
    }
  }

  static Future<Bot?> getBotById(String botId) async {
    try {
      final response = await _client
          .from('bots')
          .select()
          .eq('id', botId)
          .single();

      return Bot.fromJson(response);
    } catch (e) {
      print('Get bot by ID error: $e');
      return null;
    }
  }
}

// --- Bot JavaScript Engine ---

class BotEngine {
  static final JavascriptRuntime _jsRuntime = getJavascriptRuntime();

  static Future<String> processBotMessage(Bot bot, String userMessage, String chatId) async {
    try {
      // Properly encode UTF-8 content
      final utf8Message = utf8.encode(userMessage);
      final encodedMessage = utf8.decode(utf8Message);

      // Enhanced JavaScript context with async support
      final jsCode = '''
        ${bot.jsCode}
        
        // Enhanced context for bot execution
        var context = {
          chatId: '$chatId',
          timestamp: ${DateTime.now().millisecondsSinceEpoch},
          userMessage: ${json.encode(encodedMessage)}
        };
        
        // Execute bot logic with better error handling
        var result;
        try {
          if (typeof processMessage === 'function') {
            result = processMessage(context.userMessage, context.chatId, context);
          } else {
            result = 'Bot error: processMessage function not found. Please check your bot code.';
          }
        } catch (botError) {
          result = 'Bot runtime error: ' + botError.toString();
        }
        
        // Ensure proper result formatting
        if (result === null || result === undefined) {
          'Bot processed your message but returned no response.';
        } else if (typeof result === 'object') {
          try {
            JSON.stringify(result);
          } catch (jsonError) {
            'Bot returned an object that could not be converted to text.';
          }
        } else {
          String(result);
        }
      ''';

      final result = await _jsRuntime.evaluateAsync(jsCode);

      if (result.isError) {
        return 'Bot execution failed: ${result.rawResult}';
      }

      String response = result.stringResult;

      // Handle problematic responses
      if (response.isEmpty || 
          response == 'null' || 
          response == 'undefined' ||
          response == '{}' ||
          response.trim().isEmpty) {
        return 'Hello! I received your message but I\'m not sure how to respond. Could you try asking me something else?';
      }

      // Clean up response
      response = response.trim();

      // Ensure UTF-8 compatibility for response
      try {
        final utf8Response = utf8.encode(response);
        response = utf8.decode(utf8Response);
      } catch (e) {
        // If UTF-8 encoding fails, keep original response
      }

      return response;
    } catch (e) {
      return 'I encountered an error: ${e.toString()}. Please try again or contact the bot creator.';
    }
  }

  // Enhanced bot creation with default templates
  static String getDefaultBotCode() {
    return '''
function processMessage(userMessage, chatId, context) {
  // Enhanced bot template with UTF-8 support
  const message = userMessage.toLowerCase();
  
  if (message.includes('hello') || message.includes('hi')) {
    return 'Hello! 👋 How can I help you today?';
  }
  
  if (message.includes('time')) {
    const now = new Date(context.timestamp);
    return 'Current time: ' + now.toLocaleTimeString() + ' 🕒';
  }
  
  if (message.includes('date')) {
    const now = new Date(context.timestamp);
    return 'Today is: ' + now.toLocaleDateString() + ' 📅';
  }
  
  if (message.includes('calculator') || message.includes('calculate')) {
    return 'I can help with calculations! Try: "calculate 2+2" 🧮';
  }
  
  if (message.includes('calculate ')) {
    try {
      const expression = message.replace('calculate ', '');
      // Simple math evaluation (safe for basic operations)
      const result = eval(expression.replace(/[^0-9+\\-*/.() ]/g, ''));
      return 'Result: ' + result + ' ✨';
    } catch (e) {
      return 'Sorry, I couldn\\'t calculate that. Try simple math like "2+2" 🤔';
    }
  }
  
  // Echo response with emoji
  return 'You said: "' + userMessage + '" 💬';
}
''';
  }
}
