import 'package:flutter/material.dart';
import 'dart:convert';
import 'services.dart';
import 'models.dart';
import 'main.dart'; // For CustomIcon

// --- Visual Bot Builder ---

class VisualBotBuilderScreen extends StatefulWidget {
  final Bot? editBot; // For editing existing bots

  const VisualBotBuilderScreen({super.key, this.editBot});

  @override
  State<VisualBotBuilderScreen> createState() => _VisualBotBuilderScreenState();
}

class _VisualBotBuilderScreenState extends State<VisualBotBuilderScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _defaultResponseController = TextEditingController();
  
  List<BotRule> _rules = [];
  bool _isLoading = false;
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    if (widget.editBot != null) {
      _loadExistingBot();
    } else {
      _loadDefaultTemplate();
    }
  }

  void _loadExistingBot() {
    final bot = widget.editBot!;
    _nameController.text = bot.name;
    _usernameController.text = bot.username;
    _descriptionController.text = bot.description ?? '';
    _isPublic = bot.isPublic;

    try {
      final config = json.decode(bot.jsonConfig);
      _defaultResponseController.text = config['default_response'] ?? '';
      
      final rules = config['rules'] as List<dynamic>? ?? [];
      _rules = rules.map((rule) => BotRule.fromJson(rule)).toList();
    } catch (e) {
      print('Error loading bot config: $e');
      _loadDefaultTemplate();
    }
  }

  void _loadDefaultTemplate() {
    _defaultResponseController.text = 'You said: "{user_message}" 💬\n\nTry saying "help" to see what I can do!';
    _rules = [
      BotRule(
        id: 'greeting',
        name: 'Greeting',
        triggers: ['hello', 'hi', 'hey'],
        type: TriggerType.contains,
        response: 'Hello! 👋 How can I help you today?',
      ),
    ];
  }

  String _generateBotConfig() {
    final config = {
      'type': 'visual_bot',
      'version': '1.0',
      'rules': _rules.map((rule) => rule.toJson()).toList(),
      'default_response': _defaultResponseController.text.trim(),
    };
    return json.encode(config);
  }

  Future<void> _saveBot() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bot name')),
      );
      return;
    }

    if (widget.editBot == null && _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final jsonConfig = _generateBotConfig();
      
      Bot? result;
      if (widget.editBot != null) {
        // Update existing bot
        result = await SupabaseService.updateBot(
          widget.editBot!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          jsonConfig: jsonConfig,
          isPublic: _isPublic,
        );
      } else {
        // Create new bot
        result = await SupabaseService.createBot(
          _nameController.text.trim(),
          _usernameController.text.trim(),
          jsonConfig,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          isPublic: _isPublic,
        );
      }

      setState(() => _isLoading = false);

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bot ${widget.editBot != null ? 'updated' : 'created'} successfully!')),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${widget.editBot != null ? 'update' : 'create'} bot')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _addRule() {
    setState(() {
      _rules.add(BotRule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Rule',
        triggers: [''],
        type: TriggerType.contains,
        response: 'Response text here',
      ));
    });
  }

  void _deleteRule(int index) {
    setState(() {
      _rules.removeAt(index);
    });
  }

  void _showTemplateDialog() {
    final templates = BotEngine.getBotTemplates();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final templateKey = templates.keys.elementAt(index);
              final template = templates[templateKey]!;
              
              return ListTile(
                title: Text(template['name'] as String),
                subtitle: Text(template['description'] as String),
                onTap: () {
                  Navigator.pop(context);
                  _loadTemplate(template['config'] as Map<String, dynamic>);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _loadTemplate(Map<String, dynamic> config) {
    setState(() {
      _defaultResponseController.text = config['default_response'] ?? '';
      final rules = config['rules'] as List<dynamic>? ?? [];
      _rules = rules.map((rule) => BotRule.fromJson(rule)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editBot != null ? 'Edit Bot' : 'Visual Bot Builder'),
        actions: [
          if (widget.editBot == null)
            IconButton(
              icon: const Icon(Icons.template_icon),
              onPressed: _showTemplateDialog,
              tooltip: 'Load Template',
            ),
          TextButton(
            onPressed: _isLoading ? null : _saveBot,
            child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.editBot != null ? 'Update' : 'Create',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomIcon(
                          painter: RobotIconPainter(color: Theme.of(context).primaryColor),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Visual Bot Builder',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create powerful bots visually without coding! Add rules for different triggers and responses.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Basic Information
            Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _nameController,
              label: 'Bot Name *',
              hint: 'My Awesome Bot',
            ),
            const SizedBox(height: 16),
            
            if (widget.editBot == null) ...[
              _buildTextField(
                controller: _usernameController,
                label: 'Username *',
                hint: 'myawesomebot',
                prefix: '@',
              ),
              const SizedBox(height: 16),
            ],
            
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'What does your bot do?',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Switch(
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
                  activeColor: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Make bot public (others can find and use it)'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Rules Section
            Row(
              children: [
                Text(
                  'Bot Rules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addRule,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Rule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_rules.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.rule, size: 48, color: Colors.grey[500]),
                        const SizedBox(height: 16),
                        const Text(
                          'No rules yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add rules to define how your bot responds to messages',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rules.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final rule = _rules.removeAt(oldIndex);
                    _rules.insert(newIndex, rule);
                  });
                },
                itemBuilder: (context, index) {
                  return BotRuleCard(
                    key: ValueKey(_rules[index].id),
                    rule: _rules[index],
                    index: index,
                    onUpdate: (updatedRule) {
                      setState(() {
                        _rules[index] = updatedRule;
                      });
                    },
                    onDelete: () => _deleteRule(index),
                  );
                },
              ),
            
            const SizedBox(height: 32),

            // Default Response
            Text(
              'Default Response',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This response is used when no rules match the user\'s message',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _defaultResponseController,
                decoration: const InputDecoration(
                  hintText: 'Enter default response...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: 3,
              ),
            ),

            const SizedBox(height: 24),
            
            // Available Placeholders
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Available Placeholders:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• {user_message} - The user\'s original message\n'
                      '• {time} - Current time (HH:MM:SS)\n'
                      '• {date} - Current date (YYYY-MM-DD)\n'
                      '• {timestamp} - Unix timestamp',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefix,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            filled: true,
            fillColor: isDark ? const Color(0xFF393E46) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          maxLines: maxLines,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    _defaultResponseController.dispose();
    super.dispose();
  }
}

// --- Bot Rule Model ---

enum TriggerType { exact, contains, starts_with, ends_with }

class BotRule {
  String id;
  String name;
  List<String> triggers;
  TriggerType type;
  String response;

  BotRule({
    required this.id,
    required this.name,
    required this.triggers,
    required this.type,
    required this.response,
  });

  factory BotRule.fromJson(Map<String, dynamic> json) {
    return BotRule(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Unnamed Rule',
      triggers: List<String>.from(json['triggers'] ?? []),
      type: TriggerType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] ?? 'contains'),
        orElse: () => TriggerType.contains,
      ),
      response: json['response'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'triggers': triggers,
      'type': type.toString().split('.').last,
      'response': response,
    };
  }
}

// --- Bot Rule Card Widget ---

class BotRuleCard extends StatefulWidget {
  final BotRule rule;
  final int index;
  final Function(BotRule) onUpdate;
  final VoidCallback onDelete;

  const BotRuleCard({
    super.key,
    required this.rule,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<BotRuleCard> createState() => _BotRuleCardState();
}

class _BotRuleCardState extends State<BotRuleCard> {
  late TextEditingController _nameController;
  late TextEditingController _responseController;
  late List<TextEditingController> _triggerControllers;
  late TriggerType _triggerType;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule.name);
    _responseController = TextEditingController(text: widget.rule.response);
    _triggerType = widget.rule.type;
    _updateTriggerControllers();
  }

  void _updateTriggerControllers() {
    _triggerControllers = widget.rule.triggers
        .map((trigger) => TextEditingController(text: trigger))
        .toList();
  }

  void _addTrigger() {
    setState(() {
      widget.rule.triggers.add('');
      _triggerControllers.add(TextEditingController());
    });
    _updateRule();
  }

  void _removeTrigger(int index) {
    if (widget.rule.triggers.length <= 1) return;
    
    setState(() {
      widget.rule.triggers.removeAt(index);
      _triggerControllers[index].dispose();
      _triggerControllers.removeAt(index);
    });
    _updateRule();
  }

  void _updateRule() {
    final updatedRule = BotRule(
      id: widget.rule.id,
      name: _nameController.text.trim(),
      triggers: _triggerControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      type: _triggerType,
      response: _responseController.text.trim(),
    );
    widget.onUpdate(updatedRule);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text('${widget.index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(widget.rule.name.isNotEmpty ? widget.rule.name : 'Rule ${widget.index + 1}'),
            subtitle: Text('Triggers: ${widget.rule.triggers.join(', ')}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rule Name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Rule Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateRule(),
                  ),
                  const SizedBox(height: 16),

                  // Trigger Type
                  DropdownButtonFormField<TriggerType>(
                    value: _triggerType,
                    decoration: const InputDecoration(
                      labelText: 'Trigger Type',
                      border: OutlineInputBorder(),
                    ),
                    items: TriggerType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getTriggerTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _triggerType = value!);
                      _updateRule();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Triggers
                  Row(
                    children: [
                      const Text('Triggers', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addTrigger,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  for (int i = 0; i < _triggerControllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _triggerControllers[i],
                              decoration: InputDecoration(
                                hintText: 'Enter trigger word/phrase',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                fillColor: isDark ? const Color(0xFF393E46) : const Color(0xFFF5F5F5),
                                filled: true,
                              ),
                              onChanged: (_) => _updateRule(),
                            ),
                          ),
                          if (_triggerControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.red),
                              onPressed: () => _removeTrigger(i),
                            ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),

                  // Response
                  TextField(
                    controller: _responseController,
                    decoration: const InputDecoration(
                      labelText: 'Response',
                      hintText: 'Enter bot response...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (_) => _updateRule(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getTriggerTypeLabel(TriggerType type) {
    switch (type) {
      case TriggerType.exact:
        return 'Exact Match';
      case TriggerType.contains:
        return 'Contains';
      case TriggerType.starts_with:
        return 'Starts With';
      case TriggerType.ends_with:
        return 'Ends With';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _responseController.dispose();
    for (final controller in _triggerControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}