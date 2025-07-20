# Secume - Flutter Chat App with Bot Integration

A modern, secure Flutter chat application with advanced bot creation capabilities, inspired by Telegram's BotFather.

## 🗄️ Database Setup

Before running the app, you need to set up the required database tables and columns in your Supabase project. Execute the following SQL commands in your Supabase SQL editor:

### 1. Update Existing Tables

```sql
-- Add new columns to the chats table for group functionality
ALTER TABLE chats 
ADD COLUMN IF NOT EXISTS username TEXT,
ADD COLUMN IF NOT EXISTS creator_id UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS admin_ids JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Add unique constraint for group usernames
CREATE UNIQUE INDEX IF NOT EXISTS unique_group_username 
ON chats (username) 
WHERE username IS NOT NULL AND type = 'group';
```

### 2. Create New Tables

```sql
-- Create user_chat_preferences table for pinning functionality
CREATE TABLE IF NOT EXISTS user_chat_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    is_pinned BOOLEAN DEFAULT false,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, chat_id)
);

-- Create user_status table for online/offline status
CREATE TABLE IF NOT EXISTS user_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    is_online BOOLEAN DEFAULT false,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create typing_indicators table for real-time typing
CREATE TABLE IF NOT EXISTS typing_indicators (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT true,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(chat_id, user_id)
);
```

### 3. Set Up Row Level Security (RLS)

```sql
-- Enable RLS on new tables
ALTER TABLE user_chat_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_chat_preferences
CREATE POLICY "Users can manage their own chat preferences" ON user_chat_preferences
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for user_status
CREATE POLICY "Users can update their own status" ON user_status
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view others' status" ON user_status
    FOR SELECT USING (true);

-- RLS Policies for typing_indicators
CREATE POLICY "Users can manage typing in their chats" ON typing_indicators
    FOR ALL USING (
        auth.uid() = user_id OR 
        EXISTS (
            SELECT 1 FROM chats 
            WHERE chats.id = typing_indicators.chat_id 
            AND auth.uid() = ANY(chats.participant_ids)
        )
    );

-- Update existing RLS policies for chats table (for group functionality)
DROP POLICY IF EXISTS "Users can view their chats" ON chats;
CREATE POLICY "Users can view their chats" ON chats
    FOR SELECT USING (
        auth.uid() = ANY(participant_ids) OR 
        (type = 'group' AND is_private = false)
    );

DROP POLICY IF EXISTS "Users can update their chats" ON chats;
CREATE POLICY "Users can update their chats" ON chats
    FOR UPDATE USING (
        auth.uid() = ANY(participant_ids) AND (
            auth.uid() = creator_id OR 
            auth.uid() = ANY(COALESCE(admin_ids, '[]'::jsonb)::text[]::uuid[])
        )
    );
```

### 4. Create Indexes for Performance

```sql
-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_chats_username ON chats(username) WHERE username IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_chats_creator ON chats(creator_id) WHERE creator_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_chats_type_private ON chats(type, is_private);
CREATE INDEX IF NOT EXISTS idx_user_chat_preferences_pinned ON user_chat_preferences(user_id, is_pinned) WHERE is_pinned = true;
CREATE INDEX IF NOT EXISTS idx_user_status_online ON user_status(is_online, last_seen);
CREATE INDEX IF NOT EXISTS idx_typing_indicators_chat ON typing_indicators(chat_id, updated_at);
```

### 5. Set Up Real-time Subscriptions

```sql
-- Enable real-time for new tables
ALTER PUBLICATION supabase_realtime ADD TABLE user_chat_preferences;
ALTER PUBLICATION supabase_realtime ADD TABLE user_status;
ALTER PUBLICATION supabase_realtime ADD TABLE typing_indicators;
```

### 6. Create Trigger Functions for Auto-Updates

```sql
-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for auto-updating timestamps
CREATE TRIGGER update_user_chat_preferences_updated_at 
    BEFORE UPDATE ON user_chat_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_status_updated_at 
    BEFORE UPDATE ON user_status 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_typing_indicators_updated_at 
    BEFORE UPDATE ON typing_indicators 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 7. Optional: Clean up old typing indicators

```sql
-- Function to clean up old typing indicators (optional)
CREATE OR REPLACE FUNCTION cleanup_old_typing_indicators()
RETURNS void AS $$
BEGIN
    DELETE FROM typing_indicators 
    WHERE updated_at < NOW() - INTERVAL '30 seconds';
END;
$$ LANGUAGE plpgsql;

-- You can set up a cron job to run this periodically if needed
```

## 🚀 Getting Started

After setting up the database schema above, you can run the Flutter app as usual:

1. Make sure you have Flutter installed
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Set up your Supabase project and add the credentials to the app
5. Execute the SQL commands above in your Supabase SQL editor
6. Run `flutter run` to start the app

## 📱 New Features Added

### Group Chat Functionality
- Create groups with custom usernames (e.g., @mygroup)
- Public/Private group settings
- Admin management (make/remove admins)
- Member management (add/remove members)
- Group info screen with member list
- Real-time group message synchronization
- Message history for new members

### Enhanced Chat Management
- Pin/Unpin chats and groups
- Real-time chat list updates
- Group joining via @username
- Improved navigation and system back button support

### Real-time Features
- Instant message delivery and display
- Live typing indicators
- Online/Offline status tracking
- Real-time chat list updates

### UI/UX Improvements
- Consistent design across all screens
- Proper group icons and indicators
- Enhanced search functionality
- Improved bot management

## ✨ Latest Updates & Features (Fixed Issues)

### 🔧 Major Fixes & Improvements (Latest Release)
- **✅ Fixed Bot Deletion**: Enhanced bot deletion with proper RLS policy handling and user verification
- **✅ Group Creation Functionality**: Added complete group chat creation with user selection and management
- **✅ Real-time Messaging Fix**: Fixed message updates not appearing when returning to chat screen
- **✅ Online Status & Typing Indicators**: Implemented real working online/offline status with green dots and typing animations
- **✅ Last Seen Functionality**: Added proper last seen timestamps with smart formatting (just now, 5m ago, 2h ago, etc.)
- **✅ Navigation Menu Enhancement**: Back button replaces menu icon on non-home screens, returns to chat screen
- **✅ Improved User Avatar**: Enhanced avatar with gradient background and shadow effects matching app design
- **✅ Bot Management Cleanup**: Removed redundant add icons, kept only bottom FloatingActionButton for bot creation
- **✅ Group Creation UI**: Added group creation cards and FloatingActionButton in search screen
- **✅ Enhanced App Lifecycle**: Proper online/offline status management when app goes to background/foreground

### 🔧 Previous Major Fixes
- **✅ Fixed Supabase Stream Bug**: Resolved "The method 'eq' isn't defined for the class 'SupabaseStreamBuilder'" error
- **✅ Real-time Messaging**: Added instant message updates and real-time chat synchronization
- **✅ Typing Indicators**: Added animated typing indicators with real-time detection
- **✅ Online Status**: Shows user online/offline status and last seen time
- **✅ UTF-8 & Emoji Support**: Enhanced bot engine with proper UTF-8 encoding and emoji support
- **✅ AppBar Color Fix**: Fixed scrolling elevation and color consistency

### 🤖 Enhanced Bot System
- **Offline Bot Support**: Calculator bots and other offline functionality working
- **Online Bot Support**: Fixed async operations for API-based bots
- **Better Error Handling**: Proper error messages instead of "Instance of Future"
- **UTF-8 Support**: Full Unicode and emoji support in bot messages
- **Enhanced Templates**: Default bot code includes calculator, time, date functions
- **Context Support**: Bots receive enhanced context with timestamp and chat info

### 🔍 Search & Navigation Improvements
- **@bots Search**: Type "@bots" in search to create new bots
- **Better Icons**: Smart toy icons for all bot-related UI elements
- **Simplified Navigation**: Removed redundant "My Bots" tab, accessible via @bots
- **Homepage Return**: Fixed navigation to always return to homepage

### 🎨 UI/UX Enhancements
- **Fixed AppBar**: No more color changes or elevation issues on scroll
- **Better Bot Icons**: Custom container-wrapped smart_toy icons
- **Typing Animation**: Smooth animated typing indicators
- **Online Status**: Green dot for online, gray for offline users
- **Profile Consistency**: Fixed dice color issue, uses app theme colors

## 🗂 File Structure

```
├── main.dart           # App initialization, auth screens, main navigation
├── models.dart         # Data models (User, Bot, Message, Chat)
├── services.dart       # Supabase service & Bot engine
├── screens.dart        # All UI screens and components
└── README.md          # This documentation
```

## 🚀 Key Technologies

- **Flutter**: Cross-platform mobile development
- **Supabase**: Backend-as-a-Service for authentication and database
- **flutter_js**: JavaScript runtime for bot execution
- **Google Fonts**: Typography (Pacifico for branding, Manrope for UI)

## 🎯 Bot Creation

Create powerful bots using JavaScript:

```javascript
function processMessage(userMessage, chatId) {
  if (userMessage.toLowerCase().includes('hello')) {
    return 'Hello! How can I help you today?';
  }
  
  if (userMessage.toLowerCase().includes('time')) {
    return 'The current time is: ' + new Date().toLocaleTimeString();
  }
  
  return 'You said: ' + userMessage;
}
```

## 🔐 Privacy Features

- App Lock with biometric authentication
- Screenshot protection
- Sealed sender for metadata protection
- Message timers for auto-deletion
- Relay calls for IP address protection

## 🎨 Design System

- **Primary Color**: Cyan (#00ADB5)
- **Background**: Dark gray (#222831)
- **Surface**: Medium gray (#393E46)
- **Text**: Light gray (#EEEEEE)
- **Font**: Manrope for UI, Pacifico for branding

## 🤖 Custom Robot Icons

The app features custom-designed robot icons with:
- Robot head with antenna and eyes
- Body with arms and hands
- Legs with feet
- Consistent with app theme colors
- Used throughout the app for bot-related features

## 🔧 Setup Instructions

1. **Prerequisites**:
   - Flutter SDK (>=3.0.0) installed
   - Supabase project configured
   - Android Studio or VS Code with Flutter extensions

2. **Project Files**:
   - `pubspec.yaml`: Contains all required dependencies
   - `android/app/src/main/AndroidManifest.xml`: Android permissions and configuration
   - Main dart files: `main.dart`, `screens.dart`, `services.dart`, `models.dart`

3. **Dependencies** (from pubspec.yaml):
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     google_fonts: ^6.1.0      # Typography
     supabase_flutter: ^2.0.0  # Backend
     flutter_js: ^0.8.0        # Bot engine
     crypto: ^3.0.3            # Security utilities
   ```

4. **Android Configuration**:
   - Permissions for internet, camera, microphone, biometric auth
   - Screenshot protection and deep linking support
   - Network security configuration for HTTPS

5. **Setup Steps**:
   - Update Supabase URL and anon key in `main.dart`
   - Run `flutter pub get` to install dependencies
   - Set up database tables for users, bots, chats, and messages
   - Configure Android permissions if targeting physical devices

## 📋 Required Database Schemas

To support all the new features, add these tables to your Supabase database:

```sql
-- Typing indicators table
CREATE TABLE typing_indicators (
  chat_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  is_typing BOOLEAN DEFAULT true,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (chat_id, user_id)
);

-- User status table for online/offline tracking
CREATE TABLE user_status (
  user_id TEXT PRIMARY KEY,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable real-time subscriptions
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;

-- Add policies as needed for your security requirements
```

## 🤖 Enhanced Bot Creation

Create powerful bots with the new enhanced template:

```javascript
function processMessage(userMessage, chatId, context) {
  // Enhanced bot template with UTF-8 support
  const message = userMessage.toLowerCase();
  
  if (message.includes('hello') || message.includes('hi')) {
    return 'Hello! 👋 How can I help you today?';
  }
  
  if (message.includes('calculate ')) {
    try {
      const expression = message.replace('calculate ', '');
      const result = eval(expression.replace(/[^0-9+\-*/.() ]/g, ''));
      return 'Result: ' + result + ' ✨';
    } catch (e) {
      return 'Sorry, I couldn\'t calculate that. Try simple math like "2+2" 🤔';
    }
  }
  
  return 'You said: "' + userMessage + '" 💬';
}
```

## 📋 Recent Bug Fixes

### Latest Session Fixes:
- ✅ Fixed profile section layout - removed square container, consistent colors
- ✅ Fixed navigation auto-redirect issue - pages stay open correctly
- ✅ Created custom robot icons - replaced basic icons with detailed robot design
- ✅ Restored "My Bots" navigation tab for better user experience
- ✅ Fixed bot "{}" response issue - enhanced validation and error handling
- ✅ Fixed input area two-color issue - now uses single consistent color
- ✅ Fixed username status display - online/typing indicators work properly
- ✅ Enhanced bot engine with better error messages and fallbacks

### Previous Session Fixes:
- ✅ Fixed bot response returning "Instance of 'Future<dynamic>'" - Enhanced async handling
- ✅ Added real-time messaging with instant updates
- ✅ Implemented typing indicators with smooth animations  
- ✅ Added online/offline status tracking
- ✅ Fixed AppBar color elevation issues on scroll
- ✅ Enhanced bot engine with UTF-8 support and better error handling
- ✅ Fixed async operations for both offline and online bots

## 🔮 Future Enhancements

- Voice message support
- File sharing capabilities
- Group chat functionality
- Bot marketplace
- Advanced bot analytics
- Push notifications

---

Built with ❤️ using Flutter and Supabase

## 🗂 Database Setup

Run these SQL commands in your Supabase SQL editor:

```sql
-- User status table for online/offline tracking
CREATE TABLE user_status (
  user_id TEXT PRIMARY KEY,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Typing indicators table for real-time typing status
CREATE TABLE typing_indicators (
  chat_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  is_typing BOOLEAN DEFAULT true,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (chat_id, user_id)
);

-- Update chats table to support groups (if not already done)
-- Add these columns if they don't exist:
ALTER TABLE chats ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE chats ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'direct';
ALTER TABLE chats ADD COLUMN IF NOT EXISTS participant_ids TEXT[] DEFAULT '{}';
ALTER TABLE chats ADD COLUMN IF NOT EXISTS participant_usernames JSONB DEFAULT '{}';

-- Enable real-time subscriptions
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;

-- Add policies for security (adjust based on your requirements)
-- Messages policies
CREATE POLICY "Users can view messages in their chats" ON messages FOR SELECT USING (
  chat_id IN (
    SELECT id FROM chats WHERE auth.uid() = ANY(participant_ids)
  )
);

CREATE POLICY "Users can insert messages in their chats" ON messages FOR INSERT WITH CHECK (
  chat_id IN (
    SELECT id FROM chats WHERE auth.uid() = ANY(participant_ids)
  ) AND auth.uid() = sender_id
);

-- Typing indicators policies
CREATE POLICY "Users can manage typing indicators in their chats" ON typing_indicators FOR ALL USING (
  chat_id IN (
    SELECT id FROM chats WHERE auth.uid() = ANY(participant_ids)
  ) AND auth.uid() = user_id
);

-- User status policies
CREATE POLICY "Users can view all user statuses" ON user_status FOR SELECT USING (true);
CREATE POLICY "Users can manage their own status" ON user_status FOR ALL USING (auth.uid() = user_id);

-- Bot deletion policies (if needed)
CREATE POLICY "Users can delete their own bots" ON bots FOR DELETE USING (auth.uid() = creator_id);

-- Chat policies for groups
CREATE POLICY "Users can view their chats" ON chats FOR SELECT USING (auth.uid() = ANY(participant_ids));
CREATE POLICY "Users can create chats" ON chats FOR INSERT WITH CHECK (auth.uid() = ANY(participant_ids));
CREATE POLICY "Users can update their chats" ON chats FOR UPDATE USING (auth.uid() = ANY(participant_ids));
```