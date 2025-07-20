import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'services.dart';
import 'main.dart'; // Import for CustomIcon and RobotIconPainter
import 'bot_builder.dart'; // Import for Visual Bot Builder
import 'dart:async'; // Added for Timer

// --- User Search Screen with Enhanced Functionality ---

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchController = TextEditingController();
  List<AppUser> _users = [];
  List<Bot> _bots = [];
  bool _isLoading = false;
  bool _showBots = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Check if we should show @bots interface
    _checkForBotsCreation();
  }

  void _checkForBotsCreation() {
    // If user searches for "@bots", show bot creation interface
    if (_searchController.text.trim().toLowerCase() == '@bots') {
      _showBotCreationInterface();
    }
  }

  void _showBotCreationInterface() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const VisualBotBuilderScreen()),
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    // Special case for @bots - show in results but also allow navigation
    if (query.toLowerCase() == '@bots') {
      setState(() {
        _users = [];
        _bots = [];
        _currentQuery = query;
        _showBots = true;
      });
      return;
    }

    // Check if user is trying to join a group
    if (query.startsWith('@') && query.length > 1) {
      final groupUsername = query.substring(1);
      _tryJoinGroup(groupUsername);
    }

    if (query.isEmpty) {
      setState(() {
        _users = [];
        _bots = [];
        _currentQuery = '';
      });
      return;
    }

    _currentQuery = query;
    _performSearch();
  }

  Future<void> _performSearch() async {
    if (_currentQuery.isEmpty) return;

    setState(() => _isLoading = true);

    // Enhanced search: search both users and bots regardless of @ symbol
    final users = await SupabaseService.searchUsers(_currentQuery);
    final bots = await SupabaseService.searchBots(_currentQuery);

    setState(() {
      _users = users;
      _bots = bots;
      _showBots = _currentQuery.startsWith('@') || _currentQuery.toLowerCase().contains('bot');
    });

    setState(() => _isLoading = false);
  }

  Future<void> _startChatWithUser(AppUser user) async {
    final chatId = await SupabaseService.createDirectChat(user.id, user.username);
    if (chatId != null && mounted) {
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(chatId: chatId, chatName: user.fullName),
        ),
      );
    }
  }

  Future<void> _startChatWithBot(Bot bot) async {
    final chatId = await SupabaseService.createBotChat(bot.id);
    if (chatId != null && mounted) {
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(chatId: chatId, chatName: bot.name, bot: bot),
        ),
      );
    }
  }

  Future<void> _tryJoinGroup(String groupUsername) async {
    try {
      final chat = await SupabaseService.joinGroupByUsername(groupUsername);
      if (chat != null && mounted) {
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chat.id, 
              chatName: chat.displayName,
              chat: chat,
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined group: ${chat.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not join group: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: const Text('Create Group', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users, bots, or @groupname to join...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onSubmitted: (value) {
                if (value.toLowerCase() == '@bots') {
                  _showBotCreationInterface();
                } else if (value.startsWith('@') && value.length > 1) {
                  final groupUsername = value.substring(1);
                  _tryJoinGroup(groupUsername);
                }
              },
            ),
          ),
          if (_currentQuery.toLowerCase() == '@bots')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIcon(
                      painter: RobotIconPainter(color: Colors.white),
                      size: 20,
                    ),
                  ),
                  title: const Text('Create New Bot (@bots)'),
                  subtitle: const Text('Tap to create your own bot like BotFather'),
                  onTap: _showBotCreationInterface,
                ),
              ),
            ),
          // Add group creation card when no search query
          if (_currentQuery.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.group_add, color: Colors.white, size: 20),
                  ),
                  title: const Text('Create Group'),
                  subtitle: const Text('Start a group conversation with multiple users'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Card(
                color: Colors.green.withOpacity(0.1),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.group, color: Colors.white, size: 20),
                  ),
                  title: const Text('Join Group'),
                  subtitle: const Text('Type @groupname to join an existing group'),
                  onTap: () {
                    _searchController.text = '@';
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _searchController.text.length),
                    );
                  },
                ),
              ),
            ),
          ],
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  if (_bots.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Bots',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    ..._bots.map((bot) => _buildBotTile(bot)),
                  ],
                  if (_users.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Users',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    ..._users.map((user) => _buildUserTile(user)),
                  ],
                  if (_users.isEmpty && _bots.isEmpty && _currentQuery.isNotEmpty && !_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No results found',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserTile(AppUser user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(user.fullName),
      subtitle: Text('@${user.username}'),
      onTap: () => _startChatWithUser(user),
    );
  }

  Widget _buildBotTile(Bot bot) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Container(
          padding: const EdgeInsets.all(4),
          child: CustomIcon(
            painter: RobotIconPainter(color: Colors.white),
            size: 20,
          ),
        ),
      ),
      title: Text(bot.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('@${bot.username}'),
          if (bot.description != null)
            Text(
              bot.description!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      onTap: () => _startChatWithBot(bot),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// --- Chat Detail Screen with Fixed Bot Response ---

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final Bot? bot;
  final Chat? chat;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.bot,
    this.chat,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  Bot? _bot;
  Chat? _currentChat;
  Timer? _typingTimer;
  List<String> _typingUsers = [];
  bool _isTyping = false;
  Map<String, dynamic>? _userStatus;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<List<String>>? _typingSubscription;

  @override
  void initState() {
    super.initState();
    _bot = widget.bot;
    _currentChat = widget.chat;
    _loadMessages();
    _setupRealTimeListeners();
    _controller.addListener(_onTextChanged);
    if (_bot == null && widget.bot != null) {
      _loadBotInfo();
    }
    if (_currentChat == null) {
      _loadChatInfo();
    }
    _loadUserStatus();
    SupabaseService.setOnlineStatus(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force refresh messages when returning to this screen to ensure latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMessages();
    });
  }

  Future<void> _refreshMessages() async {
    final messages = await SupabaseService.getChatMessages(widget.chatId);
    if (mounted) {
      setState(() {
        _messages = messages;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _setupRealTimeListeners() {
    // Cancel existing subscriptions
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();

    // Listen for new messages with immediate UI update and silent refresh
    _messageSubscription = SupabaseService.getMessageStream(widget.chatId).listen(
      (newMessage) {
        if (mounted) {
          // Check if message already exists to avoid duplicates
          final existingIndex = _messages.indexWhere((m) => m.id == newMessage.id);
          setState(() {
            if (existingIndex == -1) {
              _messages.add(newMessage);
            } else {
              _messages[existingIndex] = newMessage; // Update existing message
            }
            // Sort messages by timestamp to ensure correct order
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });
          // Immediate scroll to bottom for better UX (silent, no loading indicator)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToBottom();
              // Silent refresh completed - no visual feedback needed
            }
          });
        }
      },
      onError: (error) => print('Message stream error: $error'),
    );

    // Listen for typing indicators
    _typingSubscription = SupabaseService.getTypingUsers(widget.chatId).listen(
      (typingUsers) {
        if (mounted) {
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          setState(() {
            _typingUsers = typingUsers.where((id) => id != currentUserId).toList();
          });
        }
      },
      onError: (error) => print('Typing stream error: $error'),
    );
  }

  void _onTextChanged() {
    if (_controller.text.trim().isNotEmpty && !_isTyping) {
      _isTyping = true;
      SupabaseService.setTyping(widget.chatId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        SupabaseService.setTyping(widget.chatId, false);
      }
    });
  }

  Future<void> _loadBotInfo() async {
    if (widget.bot != null) {
      setState(() {
        _bot = widget.bot;
      });
    }
  }

  Future<void> _loadChatInfo() async {
    try {
      final chatResponse = await SupabaseService.client
          .from('chats')
          .select()
          .eq('id', widget.chatId)
          .single();
      
      setState(() {
        _currentChat = Chat.fromJson(chatResponse);
      });
    } catch (e) {
      print('Error loading chat info: $e');
    }
  }

  Future<void> _loadMessages() async {
    final messages = await SupabaseService.getChatMessages(widget.chatId);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _controller.text.trim();
    if (messageText.isEmpty) return;

    _controller.clear();

    // Stop typing indicator
    if (_isTyping) {
      _isTyping = false;
      SupabaseService.setTyping(widget.chatId, false);
    }

    final message = await SupabaseService.sendMessage(widget.chatId, messageText);
    if (message != null && mounted) {
      // Immediately add message to UI for instant feedback
      setState(() {
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }
      });
      
      // Scroll to bottom immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });

      // If this is a bot chat, send bot response
      if (_bot != null) {
        _sendBotResponse(messageText);
      }
    }
  }

  Future<void> _sendBotResponse(String userMessage) async {
    if (_bot == null) return;

    try {
      // Show typing indicator for bot
      setState(() {
        _typingUsers = ['bot'];
      });

      // Add small delay to simulate bot thinking
      await Future.delayed(const Duration(milliseconds: 500));

      // Fixed bot response handling with proper async/await
      final response = await BotEngine.processBotMessage(_bot!, userMessage, widget.chatId);
      
      // Clear typing indicator
      setState(() {
        _typingUsers = [];
      });

      // Validate response is not empty or invalid
      if (response.isEmpty || response == '{}' || response == 'null' || response == 'undefined') {
        final defaultResponse = 'Bot processed your message but provided no response.';
        final botMessage = await SupabaseService.sendMessage(
          widget.chatId, 
          defaultResponse, 
          messageType: 'bot_response'
        );
        
        if (botMessage != null && mounted) {
          // Immediately add bot message to UI
          setState(() {
            if (!_messages.any((m) => m.id == botMessage.id)) {
              _messages.add(botMessage);
              _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            }
          });
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToBottom();
          });
        }
        return;
      }
      
      // Send bot response as a system message
      final botMessage = await SupabaseService.sendMessage(
        widget.chatId, 
        response, 
        messageType: 'bot_response'
      );
      
      if (botMessage != null && mounted) {
        // Immediately add bot message to UI
        setState(() {
          if (!_messages.any((m) => m.id == botMessage.id)) {
            _messages.add(botMessage);
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          }
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToBottom();
        });
      }
    } catch (e) {
      print('Bot response error: $e');
      
      // Clear typing indicator on error
      setState(() {
        _typingUsers = [];
      });
      
      // Send more user-friendly error message
      final errorMessage = await SupabaseService.sendMessage(
        widget.chatId, 
        'Sorry, I encountered an error processing your message. Please try again.', 
        messageType: 'bot_response'
      );
      
      if (errorMessage != null && mounted) {
        // Immediately add error message to UI
        setState(() {
          if (!_messages.any((m) => m.id == errorMessage.id)) {
            _messages.add(errorMessage);
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          }
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToBottom();
        });
      }
    }
  }

  Future<void> _loadUserStatus() async {
    if (_bot != null) return; // Don't load status for bots
    
    try {
      // Get chat info to find the other user
      final chatResponse = await SupabaseService.client
          .from('chats')
          .select('participant_ids, participant_usernames')
          .eq('id', widget.chatId)
          .single();
      
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final participantIds = List<String>.from(chatResponse['participant_ids'] ?? []);
      
      // Find the other user's ID
      final otherUserId = participantIds.firstWhere(
        (id) => id != currentUserId, 
        orElse: () => '',
      );
      
      if (otherUserId.isNotEmpty) {
        final status = await SupabaseService.getUserStatus(otherUserId);
        if (mounted) {
          setState(() {
            _userStatus = status;
          });
        }
        
        // Set up periodic status updates
        Timer.periodic(const Duration(seconds: 30), (timer) async {
          if (!mounted) {
            timer.cancel();
            return;
          }
          final updatedStatus = await SupabaseService.getUserStatus(otherUserId);
          if (mounted) {
            setState(() {
              _userStatus = updatedStatus;
            });
          }
        });
      }
    } catch (e) {
      print('Error loading user status: $e');
    }
  }

  String _formatLastSeen(String? lastSeenStr) {
    if (lastSeenStr == null) return 'last seen recently';
    
    try {
      final lastSeen = DateTime.parse(lastSeenStr);
      final now = DateTime.now();
      final difference = now.difference(lastSeen);
      
      if (difference.inMinutes < 1) {
        return 'last seen just now';
      } else if (difference.inMinutes < 60) {
        return 'last seen ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'last seen ${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return 'last seen ${difference.inDays}d ago';
      } else {
        return 'last seen recently';
      }
    } catch (e) {
      return 'last seen recently';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            if (_bot != null) 
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomIcon(
                  painter: RobotIconPainter(color: Colors.white),
                  size: 20,
                ),
              ),
            if (_bot != null) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_bot != null)
                    Text(
                      'Bot • Always available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    )
                  else if (_typingUsers.isNotEmpty)
                    Text(
                      'typing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  else if (_userStatus != null)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _userStatus!['is_online'] == true 
                                ? Colors.green 
                                : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _userStatus!['is_online'] == true 
                              ? 'online' 
                              : _formatLastSeen(_userStatus!['last_seen']),
                          style: TextStyle(
                            fontSize: 12,
                            color: _userStatus!['is_online'] == true 
                                ? Colors.green 
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_currentChat?.type == 'group')
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupInfoScreen(chat: _currentChat!),
                  ),
                );
              },
            ),
          if (_bot == null && _currentChat?.type != 'group') // Only show call actions for direct chats
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () {},
            ),
          if (_bot == null && _currentChat?.type != 'group')
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {},
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_typingUsers.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _typingUsers.isNotEmpty) {
                        // Typing indicator
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 10,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildTypingDot(0),
                                          _buildTypingDot(1),
                                          _buildTypingDot(2),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final message = _messages[index];
                      final isCurrentUser = message.senderId == Supabase.instance.client.auth.currentUser?.id;
                      final isBot = message.messageType == 'bot_response';
                      final isGroup = _currentChat?.type == 'group';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isCurrentUser && isBot)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: CustomIcon(
                                  painter: RobotIconPainter(color: Colors.white),
                                  size: 16,
                                ),
                              ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isCurrentUser 
                                      ? Theme.of(context).primaryColor 
                                      : isBot 
                                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                                          : const Color(0xFF393E46),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (!isCurrentUser && isGroup && !isBot && message.senderUsername != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          message.senderUsername!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      message.content,
                                      style: TextStyle(
                                        color: isCurrentUser ? Colors.white : const Color(0xFFEEEEEE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
                      Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor, // Use theme background color
              ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF393E46) 
                          : const Color(0xFFF5F5F5), // Theme-aware fill color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[500],
        shape: BoxShape.circle,
      ),
    );
  }
}

// --- Bot Management Screen ---

class BotManagementScreen extends StatefulWidget {
  const BotManagementScreen({super.key});

  @override
  State<BotManagementScreen> createState() => _BotManagementScreenState();
}

class _BotManagementScreenState extends State<BotManagementScreen> {
  List<Bot> _userBots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserBots();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload bots when returning to this screen
    _loadUserBots();
  }

  Future<void> _loadUserBots() async {
    final bots = await SupabaseService.getUserBots();
    setState(() {
      _userBots = bots;
      _isLoading = false;
    });
  }

  Future<void> _deleteBot(Bot bot) async {
    final success = await SupabaseService.deleteBot(bot.id);
    if (success) {
      setState(() {
        _userBots.removeWhere((b) => b.id == bot.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bot deleted successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete bot')),
        );
      }
    }
  }

  void _showDeleteConfirmation(Bot bot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bot'),
        content: Text('Are you sure you want to delete "${bot.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteBot(bot);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // @bots creation card
                Card(
                  margin: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIcon(
                        painter: RobotIconPainter(color: Colors.white),
                        size: 24,
                      ),
                    ),
                    title: const Text('Create New Bot (@bots)'),
                    subtitle: const Text('Search "@bots" or tap here to create like BotFather'),
                    onTap: () {
                              Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VisualBotBuilderScreen()),
        ).then((_) => _loadUserBots());
                    },
                  ),
                ),
                Expanded(
                  child: _userBots.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIcon(
                        painter: RobotIconPainter(color: Colors.grey),
                        size: 64,
                      ),
                              SizedBox(height: 16),
                              Text(
                                'No bots yet',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Create your first bot above!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _userBots.length,
                          itemBuilder: (context, index) {
                            final bot = _userBots[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: CustomIcon(
                                      painter: RobotIconPainter(color: Colors.white),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                title: Text(bot.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('@${bot.username}'),
                                    if (bot.description != null)
                                      Text(
                                        bot.description!,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                                            Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisualBotBuilderScreen(editBot: bot),
                        ),
                      ).then((_) => _loadUserBots());
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmation(bot);
                                    }
                                  },
                                ),
                                onTap: () {
                                  // Start chat with bot
                                  SupabaseService.createBotChat(bot.id).then((chatId) {
                                    if (chatId != null && mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatDetailScreen(
                                            chatId: chatId,
                                            chatName: bot.name,
                                            bot: bot,
                                          ),
                                        ),
                                      );
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}



// --- Create Group Screen ---

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<AppUser> _selectedUsers = [];
  List<AppUser> _availableUsers = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
  }

  Future<void> _loadAvailableUsers() async {
    setState(() {
      _isSearching = true;
    });

    final users = await SupabaseService.searchUsers('');
    setState(() {
      _availableUsers = users;
      _isSearching = false;
    });
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group username')),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final participantIds = _selectedUsers.map((user) => user.id).toList();
      final groupId = await SupabaseService.createGroup(
        _nameController.text.trim(),
        _usernameController.text.trim(),
        participantIds,
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        isPrivate: _isPrivate,
      );

      setState(() {
        _isLoading = false;
      });

      if (groupId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create group')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create', style: TextStyle(color: Color(0xFF00ADB5))),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    filled: true,
                    fillColor: const Color(0xFF393E46),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Group Username',
                    prefixText: '@',
                    filled: true,
                    fillColor: const Color(0xFF393E46),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    filled: true,
                    fillColor: const Color(0xFF393E46),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Switch(
                      value: _isPrivate,
                      onChanged: (value) => setState(() => _isPrivate = value),
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Private Group', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            _isPrivate 
                                ? 'Only admins can add members'
                                : 'Anyone can join using @${_usernameController.text.trim()}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedUsers.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Members (${_selectedUsers.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _selectedUsers.map((user) => Chip(
                            label: Text(user.username),
                            deleteIcon: const Icon(Icons.close),
                            onDeleted: () {
                              setState(() {
                                _selectedUsers.remove(user);
                              });
                            },
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = _availableUsers[index];
                      final isSelected = _selectedUsers.contains(user);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(user.fullName),
                        subtitle: Text('@${user.username}'),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.add_circle_outline,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUsers.remove(user);
                            } else {
                              _selectedUsers.add(user);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}



// --- Other Required Screens ---

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List<Chat> _chats = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  StreamSubscription<List<Chat>>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealTimeListener();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _setupRealTimeListener() {
    // First load chats immediately
    _loadChats();
    
    // Then set up real-time listener
    _chatSubscription = SupabaseService.getChatListStream().listen(
      (chats) {
        if (mounted) {
          setState(() {
            _chats = chats;
            _isLoading = false;
            _hasError = false;
          });
        }
      },
      onError: (error) {
        print('Chat list stream error: $error');
        // If stream fails, fall back to manual loading
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Real-time connection failed: ${error.toString()}';
          });
        }
        _loadChats();
      },
    );
  }

  Future<void> _loadChats() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      final chats = await SupabaseService.getUserChats();
      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      print('Error loading chats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _togglePin(Chat chat) async {
    final success = await SupabaseService.pinChat(chat.id, !chat.isPinned);
    if (success) {
      // Real-time listener will update the UI automatically
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chat.isPinned ? 'Chat unpinned' : 'Chat pinned'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showChatOptions(Chat chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(chat.isPinned ? 'Unpin Chat' : 'Pin Chat'),
              onTap: () {
                Navigator.pop(context);
                _togglePin(chat);
              },
            ),
            if (chat.type == 'group')
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Group Info'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupInfoScreen(chat: chat),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Chat chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete this chat with ${chat.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete chat functionality
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView(
                    children: [
                      const SizedBox(height: 200),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text(
                              'Failed to load chats',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadChats,
                              child: const Text('Retry'),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Or pull down to refresh',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
              onRefresh: _loadChats,
              child: _chats.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No chats yet',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start a conversation with someone!',
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Pull down to refresh',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: chat.type == 'bot' 
                                ? Theme.of(context).primaryColor 
                                : chat.type == 'group'
                                    ? Colors.purple[400]
                                    : Colors.grey[600],
                            child: chat.type == 'bot'
                                ? Container(
                                    padding: const EdgeInsets.all(4),
                                    child: CustomIcon(
                                      painter: RobotIconPainter(color: Colors.white),
                                      size: 20,
                                    ),
                                  )
                                : chat.type == 'group'
                                    ? const Icon(Icons.group, color: Colors.white, size: 20)
                                    : Text(
                                        chat.displayName.isNotEmpty ? chat.displayName[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                          ),
                          if (chat.isPinned)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.push_pin,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.displayName,
                              style: TextStyle(
                                fontWeight: chat.isPinned ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (chat.type == 'group' && chat.username != null)
                            Text(
                              '@${chat.username}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          if (chat.type == 'group' && chat.isPrivate)
                            const Icon(Icons.lock, size: 12, color: Colors.grey),
                          if (chat.type == 'group' && chat.isPrivate)
                            const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              chat.lastMessage ?? 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              chatId: chat.id,
                              chatName: chat.displayName,
                              chat: chat,
                            ),
                          ),
                        );
                      },
                      onLongPress: () => _showChatOptions(chat),
                    );
                  },
                ),
            ),
    );
  }
}

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Calls',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Call feature coming soon!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _appLock = false;
  bool _screenshotProtection = false;
  bool _sealedSender = false;
  bool _metadataObfuscation = false;
  bool _relayCalls = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Checkup',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a guided tour of your key privacy settings to make sure they are right for you.',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Checkup'),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Core Controls',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        _PrivacySwitchTile(
          icon: Icons.fingerprint,
          title: 'App Lock',
          subtitle: 'Require fingerprint or Face ID to unlock the app.',
          value: _appLock,
          onChanged: (val) => setState(() => _appLock = val),
        ),
        _PrivacyControlTile(
          icon: Icons.timer_off_outlined,
          title: 'Default Message Timer',
          subtitle: 'Set a timer for new chats to disappear automatically',
          onTap: () {},
        ),
        const SizedBox(height: 24),
        Text(
          'Advanced Protection',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        _PrivacySwitchTile(
          icon: Icons.screenshot_monitor,
          title: 'Screenshot Protection',
          subtitle: 'Block screenshots and screen recording in chats.',
          value: _screenshotProtection,
          onChanged: (val) => setState(() => _screenshotProtection = val),
        ),
        _PrivacySwitchTile(
          icon: Icons.visibility_off_outlined,
          title: 'Sealed Sender',
          subtitle: 'Conceal sender identity from the server to protect metadata.',
          value: _sealedSender,
          onChanged: (val) => setState(() => _sealedSender = val),
        ),
        _PrivacySwitchTile(
          icon: Icons.lan_outlined,
          title: 'Metadata Obfuscation',
          subtitle: 'Strip identifying data from messages and files you send.',
          value: _metadataObfuscation,
          onChanged: (val) => setState(() => _metadataObfuscation = val),
        ),
        _PrivacySwitchTile(
          icon: Icons.alt_route_outlined,
          title: 'Relay Calls',
          subtitle: 'Route calls through Secume servers to hide your IP address.',
          value: _relayCalls,
          onChanged: (val) => setState(() => _relayCalls = val),
        ),
      ],
    );
  }
}

class _PrivacyControlTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrivacyControlTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      leading: Icon(icon, size: 30, color: Colors.grey[400]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500])),
      onTap: onTap,
    );
  }
}

class _PrivacySwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacySwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      secondary: Icon(icon, size: 30, color: Colors.grey[400]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500])),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }
}

// --- Group Info Screen ---

class GroupInfoScreen extends StatefulWidget {
  final Chat chat;

  const GroupInfoScreen({super.key, required this.chat});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  List<AppUser> _members = [];
  bool _isLoading = true;
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('id, full_name, username, email, created_at')
          .inFilter('id', widget.chat.participantIds);

      final members = response.map<AppUser>((json) => AppUser.fromJson(json)).toList();
      
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading members: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get isCurrentUserAdmin {
    return widget.chat.isUserAdmin(currentUserId ?? '');
  }

  void _showEditGroupDialog() {
    final nameController = TextEditingController(text: widget.chat.name);
    final usernameController = TextEditingController(text: widget.chat.username);
    bool isPrivate = widget.chat.isPrivate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: isPrivate,
                    onChanged: (value) => setDialogState(() => isPrivate = value),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text('Private Group'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final success = await SupabaseService.updateGroupInfo(
                  widget.chat.id,
                  name: nameController.text.trim(),
                  username: usernameController.text.trim(),
                  isPrivate: isPrivate,
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group updated successfully')),
                  );
                  Navigator.pop(context); // Go back to refresh
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update group')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberOptions(AppUser member) {
    if (!isCurrentUserAdmin || member.id == currentUserId) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF393E46),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.chat.creatorId == currentUserId)
              ListTile(
                leading: Icon(
                  widget.chat.adminIds?.contains(member.id) == true
                      ? Icons.admin_panel_settings_outlined
                      : Icons.admin_panel_settings,
                ),
                title: Text(
                  widget.chat.adminIds?.contains(member.id) == true
                      ? 'Remove Admin'
                      : 'Make Admin',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleAdminStatus(member);
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.red),
              title: const Text('Remove from Group', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _removeMember(member);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAdminStatus(AppUser member) async {
    final isAdmin = widget.chat.adminIds?.contains(member.id) == true;
    final success = isAdmin
        ? await SupabaseService.removeAdmin(widget.chat.id, member.id)
        : await SupabaseService.makeAdmin(widget.chat.id, member.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAdmin 
              ? '${member.fullName} is no longer an admin'
              : '${member.fullName} is now an admin'),
        ),
      );
      Navigator.pop(context); // Refresh by going back
    }
  }

  Future<void> _removeMember(AppUser member) async {
    final success = await SupabaseService.removeFromGroup(widget.chat.id, member.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.fullName} removed from group')),
      );
      Navigator.pop(context); // Refresh by going back
    }
  }

  void _showDeleteGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${widget.chat.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await SupabaseService.deleteGroup(widget.chat.id);
              if (success && mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to chat list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        actions: [
          if (isCurrentUserAdmin)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Group'),
                    ],
                  ),
                ),
                if (widget.chat.creatorId == currentUserId)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Group', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditGroupDialog();
                } else if (value == 'delete') {
                  _showDeleteGroupDialog();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.purple[400],
                          child: const Icon(Icons.group, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.chat.name ?? 'Unknown Group',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (widget.chat.username != null)
                          Text(
                            '@${widget.chat.username}',
                            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.chat.isPrivate)
                              const Icon(Icons.lock, size: 16, color: Colors.grey),
                            if (widget.chat.isPrivate)
                              const SizedBox(width: 4),
                            Text(
                              widget.chat.isPrivate ? 'Private Group' : 'Public Group',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Group Statistics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${_members.length}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const Text('Members', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${widget.chat.adminIds?.length ?? 1}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const Text('Admins', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Members List
                  Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isAdmin = widget.chat.adminIds?.contains(member.id) == true;
                      final isCreator = widget.chat.creatorId == member.id;
                      final isCurrentUser = member.id == currentUserId;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(member.fullName)),
                              if (isCreator)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Creator',
                                    style: TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                )
                              else if (isAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text('@${member.username}'),
                          onTap: isCurrentUserAdmin && !isCurrentUser 
                              ? () => _showMemberOptions(member)
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}