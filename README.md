# Secume - Advanced Messaging App with Visual Bot Builder

Secume is a modern Flutter messaging application with advanced features including visual bot creation, real-time messaging, group chats, and comprehensive theming support.

## ✨ Recent Updates & New Features

### 🤖 Visual Bot Builder (Replacing JavaScript Engine)
- **Completely removed Flutter JS dependency** - No more JavaScript execution issues
- **Visual drag-and-drop bot creation** - Create powerful bots without coding
- **JSON-based configuration** - Modern, secure, and reliable bot engine
- **Multiple trigger types**: Exact match, Contains, Starts with, Ends with
- **Dynamic placeholders**: `{user_message}`, `{time}`, `{date}`, `{timestamp}`
- **Pre-built templates**: Echo Bot, Info Bot, AI Chatbot templates
- **Advanced rule management**: Reorderable, expandable rule cards
- **Template system**: Quick-start templates for common bot types

### 🎨 Dynamic Theme System
- **Light & Dark theme support** - Automatic system theme detection
- **Seamless theme switching** - Follows system preferences
- **Consistent color schemes** - All components support both themes
- **Improved accessibility** - Better contrast ratios for both themes

### 💬 Enhanced Real-Time Messaging
- **Fixed message update issues** - Messages appear instantly during chat
- **Improved real-time synchronization** - No more delayed message display
- **Better error handling** - Robust message delivery system
- **Immediate UI feedback** - Messages show instantly before server confirmation
- **Enhanced bot responses** - Instant bot message delivery

### 🔧 Technical Improvements
- **Removed problematic dependencies** - No more flutter_js issues
- **Better performance** - JSON processing is faster than JS execution
- **Enhanced security** - No code execution vulnerabilities
- **Improved reliability** - Stable bot creation and execution

## 🗂️ Database Schema Updates

### Required SQL Commands for Supabase

```sql
-- Update bots table to use JSON configuration instead of JavaScript code
ALTER TABLE bots ADD COLUMN IF NOT EXISTS json_config TEXT;

-- For existing bots, you can set a default JSON config
UPDATE bots SET json_config = '{"type":"visual_bot","version":"1.0","rules":[],"default_response":"Bot is being updated to new format."}' WHERE json_config IS NULL;

-- Optional: Remove old js_code column after migration (CAREFUL - backup first!)
-- ALTER TABLE bots DROP COLUMN IF EXISTS js_code;

-- Ensure proper indexing for bot searches
CREATE INDEX IF NOT EXISTS idx_bots_username ON bots(username);
CREATE INDEX IF NOT EXISTS idx_bots_public ON bots(is_public);
CREATE INDEX IF NOT EXISTS idx_bots_creator ON bots(creator_id);

-- Add any missing columns for enhanced functionality
ALTER TABLE chats ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE chats ADD COLUMN IF NOT EXISTS last_message TEXT;

-- Create user preferences table for theme and settings
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    theme_mode TEXT DEFAULT 'system' CHECK (theme_mode IN ('light', 'dark', 'system')),
    notifications_enabled BOOLEAN DEFAULT true,
    sound_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create user status table for online/offline status
CREATE TABLE IF NOT EXISTS user_status (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    is_online BOOLEAN DEFAULT false,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create typing indicators table
CREATE TABLE IF NOT EXISTS typing_indicators (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT false,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(chat_id, user_id)
);

-- Create user chat preferences for pinning
CREATE TABLE IF NOT EXISTS user_chat_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    is_pinned BOOLEAN DEFAULT false,
    notifications_enabled BOOLEAN DEFAULT true,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, chat_id)
);

-- Add proper RLS (Row Level Security) policies
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_chat_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_preferences
CREATE POLICY "Users can view own preferences" ON user_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" ON user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for user_status
CREATE POLICY "Users can view all user status" ON user_status
    FOR SELECT USING (true);

CREATE POLICY "Users can update own status" ON user_status
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for typing_indicators
CREATE POLICY "Users can view typing in their chats" ON typing_indicators
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM chats 
            WHERE chats.id = typing_indicators.chat_id 
            AND auth.uid() = ANY(chats.participant_ids)
        )
    );

CREATE POLICY "Users can manage own typing indicators" ON typing_indicators
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for user_chat_preferences
CREATE POLICY "Users can manage own chat preferences" ON user_chat_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_status_online ON user_status(is_online);
CREATE INDEX IF NOT EXISTS idx_typing_indicators_chat ON typing_indicators(chat_id);
CREATE INDEX IF NOT EXISTS idx_user_chat_preferences_user ON user_chat_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_chat_preferences_pinned ON user_chat_preferences(user_id, is_pinned);

-- Update functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for automatic timestamp updates
DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON user_preferences;
CREATE TRIGGER update_user_preferences_updated_at 
    BEFORE UPDATE ON user_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_status_updated_at ON user_status;
CREATE TRIGGER update_user_status_updated_at 
    BEFORE UPDATE ON user_status 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_typing_indicators_updated_at ON typing_indicators;
CREATE TRIGGER update_typing_indicators_updated_at 
    BEFORE UPDATE ON typing_indicators 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_chat_preferences_updated_at ON user_chat_preferences;
CREATE TRIGGER update_user_chat_preferences_updated_at 
    BEFORE UPDATE ON user_chat_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## 📱 Features

### Core Messaging
- ✅ Real-time messaging with instant delivery
- ✅ Group chats with admin controls
- ✅ Direct messaging
- ✅ Message status indicators
- ✅ Typing indicators
- ✅ Online/offline status
- ✅ Chat pinning
- ✅ Message timestamps

### Bot System
- ✅ **Visual Bot Builder** - No coding required
- ✅ **Multiple trigger types** - Exact, Contains, Starts with, Ends with
- ✅ **Dynamic responses** - Placeholders for user input, time, date
- ✅ **Bot templates** - Pre-built bot configurations
- ✅ **Rule management** - Drag and drop rule reordering
- ✅ **Public/Private bots** - Share bots with community or keep private
- ✅ **Bot search and discovery** - Find bots created by other users

### User Interface
- ✅ **Dynamic theming** - Light/Dark mode with system detection
- ✅ **Modern Material Design** - Beautiful, consistent UI
- ✅ **Responsive design** - Works on all screen sizes
- ✅ **Smooth animations** - Polished user experience
- ✅ **Accessible design** - High contrast, readable fonts

### Security & Privacy
- ✅ **Row Level Security (RLS)** - Database-level security
- ✅ **Authenticated users only** - Secure user system
- ✅ **Privacy controls** - Granular privacy settings
- ✅ **Secure bot execution** - No code execution vulnerabilities

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Supabase account
- Android Studio / VS Code

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd secume
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Supabase**
   - Update the Supabase URL and anon key in `main.dart`
   - Run the SQL commands provided above in your Supabase SQL editor

4. **Run the app**
```bash
flutter run
```

## 🔧 Configuration

### Supabase Setup
1. Create a new Supabase project
2. Run all SQL commands from the "Database Schema Updates" section
3. Enable Row Level Security on all tables
4. Update the connection details in `main.dart`

### Environment Variables
Update these values in `main.dart`:
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

## 🤖 Bot Builder Guide

### Creating Your First Bot

1. **Access Bot Builder**
   - Search "@bots" in the user search
   - Or use the floating action button in the "My Bots" tab

2. **Choose a Template**
   - **Echo Bot**: Simple bot that repeats user messages
   - **Info Bot**: Provides time and date information
   - **AI Chatbot**: Advanced conversational template

3. **Add Rules**
   - Click "Add Rule" to create new response rules
   - Set triggers (words/phrases that activate the rule)
   - Choose trigger type (Exact, Contains, Starts with, Ends with)
   - Write the bot's response

4. **Use Placeholders**
   - `{user_message}` - The user's original message
   - `{time}` - Current time (HH:MM:SS)
   - `{date}` - Current date (YYYY-MM-DD)
   - `{timestamp}` - Unix timestamp

5. **Test Your Bot**
   - Save the bot and start a chat with it
   - Test different triggers and responses

### Bot Examples

#### Simple Greeting Bot
```json
{
  "type": "visual_bot",
  "version": "1.0",
  "rules": [
    {
      "id": "greeting",
      "name": "Greeting",
      "triggers": ["hello", "hi", "hey"],
      "type": "contains",
      "response": "Hello! 👋 How can I help you today?"
    }
  ],
  "default_response": "I didn't understand that. Try saying 'hello'!"
}
```

#### Information Bot
```json
{
  "type": "visual_bot",
  "version": "1.0",
  "rules": [
    {
      "id": "time",
      "name": "Time Request",
      "triggers": ["time", "what time"],
      "type": "contains",
      "response": "Current time: {time} 🕒"
    },
    {
      "id": "date",
      "name": "Date Request", 
      "triggers": ["date", "today"],
      "type": "contains",
      "response": "Today is: {date} 📅"
    }
  ],
  "default_response": "Ask me about time or date!"
}
```

## 🎨 Theming

The app automatically detects and follows your system theme preferences:

- **Light Theme**: Clean, bright interface with high contrast
- **Dark Theme**: Easy on the eyes with OLED-friendly colors
- **System Auto**: Automatically switches based on device settings

### Color Scheme
- **Primary Color**: `#00ADB5` (Teal)
- **Dark Background**: `#222831` (Dark Gray)
- **Light Background**: `#F8F9FA` (Light Gray)
- **Surface Dark**: `#393E46` (Medium Gray)
- **Surface Light**: `#FFFFFF` (White)

## 📞 Troubleshooting

### Common Issues

1. **Messages not updating in real-time**
   - Check internet connection
   - Verify Supabase connection
   - Restart the app

2. **Bot creation fails**
   - Ensure all required fields are filled
   - Check username uniqueness
   - Verify JSON configuration is valid

3. **Theme not switching**
   - Close and reopen the app
   - Check system theme settings
   - Verify device supports automatic theme switching

### Performance Tips

1. **Optimize bot rules**
   - Keep trigger lists short and specific
   - Avoid overlapping triggers
   - Use appropriate trigger types

2. **Chat performance**
   - Large group chats may load slowly
   - Consider archiving old conversations
   - Limit message history when possible

## 🔄 Migration Guide

### From JavaScript Bots to Visual Bots

If you have existing JavaScript-based bots, you'll need to recreate them using the visual builder:

1. **Export bot logic**: Note down your JavaScript bot's behavior
2. **Create new visual bot**: Use the visual builder to recreate the logic
3. **Test thoroughly**: Ensure the new bot behaves as expected
4. **Update references**: Update any saved bot references

### Database Migration

Run the provided SQL commands to update your database schema. The app maintains backward compatibility during the transition period.

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**: Follow the existing code style
4. **Test thoroughly**: Ensure all features work
5. **Commit changes**: `git commit -m 'Add amazing feature'`
6. **Push to branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**: Describe your changes

### Code Style

- Follow Dart/Flutter conventions
- Use meaningful variable names
- Add comments for complex logic
- Keep functions small and focused
- Use const constructors where possible

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

If you encounter any issues or have questions:

1. **Check the troubleshooting section** above
2. **Search existing issues** in the repository
3. **Create a new issue** with detailed information
4. **Include logs and screenshots** when reporting bugs

## 🗺️ Roadmap

### Upcoming Features

- 🔄 **Voice Messages**: Record and send voice notes
- 📁 **File Sharing**: Share documents, images, and files
- 🔐 **End-to-End Encryption**: Enhanced message security
- 📱 **Push Notifications**: Real-time message notifications
- 🌐 **Web Version**: Access Secume from any browser
- 🤖 **AI Integration**: Advanced AI-powered bots
- 📊 **Analytics Dashboard**: Bot performance metrics
- 🎮 **Interactive Bots**: Bots with buttons and rich interfaces

### Version History

- **v2.0.0**: Visual Bot Builder, Dynamic Themes, Enhanced Real-time Messaging
- **v1.0.0**: Initial release with basic messaging and JavaScript bots

---

**Made with ❤️ using Flutter and Supabase**