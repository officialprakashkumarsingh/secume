# Secume - Advanced Messaging App with Visual Bot Builder

Secume is a modern Flutter messaging application with advanced features including visual bot creation, real-time messaging, group chats, and comprehensive theming support.

## ✨ Recent Updates & New Features

### 🤖 Enhanced Visual Bot Builder
- **Advanced API-Connected Templates** - Create powerful bots with external API integrations
- **AI Assistant Template** - OpenAI-compatible endpoints for intelligent responses
- **Weather Bot** - Real-time weather data integration
- **News Bot** - Latest headlines and news updates
- **Crypto Bot** - Cryptocurrency prices and market data
- **Quote Bot** - Inspirational quotes and daily motivation
- **Improved Template System** - Professional bot templates with proper API documentation

### 🎨 Enhanced Theme System
- **Fixed Light Theme Issues** - Status bar, navigation bar, and inputs now properly adapt
- **Theme-Aware Components** - All UI elements respect light/dark theme preferences
- **Improved Accessibility** - Better contrast and visibility in both themes
- **Dynamic System UI** - Status and navigation bars adapt to current theme

### 💬 Improved Real-Time Messaging
- **Instant Message Updates** - Messages appear immediately without manual refresh
- **Silent Background Refresh** - Real-time updates without loading indicators
- **Enhanced Bot Responses** - Immediate bot message delivery and processing
- **Better Performance** - Optimized message streaming and UI updates

### 🔧 Bug Fixes
- **Fixed Bot Creation Issues** - Resolved bot creation failures
- **Light Theme Input Fields** - Search, group creation, and modal inputs now use proper theming
- **Real-Time Chat Updates** - Messages now update instantly in individual, group, and bot chats

## 📱 Android Configuration Updates

### Android Manifest (android/app/src/main/AndroidManifest.xml)

Add these permissions for enhanced functionality:

```xml
<!-- Internet permission for API calls -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Network state permission for connectivity checks -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Wake lock for real-time messaging -->
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- Foreground service for background messaging -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

<!-- Notification permissions for message alerts -->
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- Camera and storage for media sharing (optional) -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

Update the application theme in AndroidManifest.xml:

```xml
<application
    android:label="Secume"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:theme="@style/LaunchTheme">
    
    <!-- Add these for proper theme handling -->
    <meta-data
        android:name="io.flutter.embedding.android.NormalTheme"
        android:resource="@style/NormalTheme" />
    
    <activity
        android:name=".MainActivity"
        android:exported="true"
        android:launchMode="singleTop"
        android:theme="@style/LaunchTheme"
        android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
        android:hardwareAccelerated="true"
        android:windowSoftInputMode="adjustResize">
        
        <!-- Enable proper status bar handling -->
        <meta-data
            android:name="io.flutter.embedding.android.SplashScreenDrawable"
            android:resource="@drawable/launch_background" />
            
        <intent-filter android:autoVerify="true">
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity>
    
    <!-- Don't delete the meta-data below -->
    <meta-data
        android:name="flutterEmbedding"
        android:value="2" />
</application>
```

## 📦 Dependencies (pubspec.yaml)

Add these dependencies for enhanced bot functionality:

```yaml
name: secume
description: Advanced messaging app with visual bot builder

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Core dependencies
  supabase_flutter: ^2.3.4
  google_fonts: ^6.1.0
  
  # HTTP and API calls for bot integrations
  http: ^1.1.0
  dio: ^5.4.0  # Advanced HTTP client for API bots
  
  # JSON handling for bot configurations
  json_annotation: ^4.8.1
  
  # Real-time messaging enhancements
  web_socket_channel: ^2.4.0
  
  # Local storage for bot configs
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # UI enhancements
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  
  # Permissions for Android
  permission_handler: ^11.2.0
  
  # Network connectivity
  connectivity_plus: ^5.0.2
  
  # Image handling (optional for bot avatars)
  cached_network_image: ^3.3.1
  
  # Date/time formatting for bot responses
  intl: ^0.19.0
  
  # UUID generation for bot IDs
  uuid: ^4.3.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  
  # JSON code generation
  build_runner: ^2.4.8
  json_serializable: ^6.7.1
  
  # Hive code generation
  hive_generator: ^2.0.1

flutter:
  uses-material-design: true
  
  # Add custom fonts for better theming
  fonts:
    - family: Manrope
      fonts:
        - asset: assets/fonts/Manrope-Regular.ttf
        - asset: assets/fonts/Manrope-Bold.ttf
          weight: 700
    
  # Assets for bot templates
  assets:
    - assets/images/
    - assets/bot_templates/
```

## 🤖 Bot API Integration Guide

### Setting Up API Keys

Create a `.env` file in your project root:

```env
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_BASE_URL=https://api.openai.com/v1

# Weather API
OPENWEATHER_API_KEY=your_openweather_api_key_here

# News API
NEWS_API_KEY=your_news_api_key_here

# Other API keys as needed
COINGECKO_API_KEY=your_coingecko_api_key_here
```

### Bot Template Configuration

Each bot template includes:
- **API endpoint configuration**
- **Authentication setup**
- **Response formatting**
- **Error handling**
- **Rate limiting considerations**

### Example API Integration

For the AI Assistant bot, configure your OpenAI-compatible endpoint:

```dart
// In your bot configuration
{
  "type": "ai_assistant",
  "api_config": {
    "endpoint": "https://api.openai.com/v1/chat/completions",
    "model": "gpt-3.5-turbo",
    "max_tokens": 150,
    "temperature": 0.7
  }
}
```

## 🚀 Getting Started

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
   - Run the SQL commands provided above in your Supabase dashboard

4. **Run the app**
   ```bash
   flutter run
   ```

## 🗂️ Database Schema Updates

### Required SQL Commands for Supabase

```sql
-- Update bots table to use JSON configuration instead of JavaScript code
ALTER TABLE bots ADD COLUMN IF NOT EXISTS json_config TEXT;

-- For existing bots, you can set a default JSON config
UPDATE bots SET json_config = '{"type":"visual_bot","version":"1.0","rules":[],"default_response":"Bot is being updated to new format."}' WHERE json_config IS NULL;

-- Add API configuration support for advanced bots
ALTER TABLE bots ADD COLUMN IF NOT EXISTS api_config JSONB;

-- Add bot usage statistics
ALTER TABLE bots ADD COLUMN IF NOT EXISTS usage_count INTEGER DEFAULT 0;
ALTER TABLE bots ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMP WITH TIME ZONE;

-- Ensure proper indexing for bot searches
CREATE INDEX IF NOT EXISTS idx_bots_username ON bots(username);
CREATE INDEX IF NOT EXISTS idx_bots_is_public ON bots(is_public);
CREATE INDEX IF NOT EXISTS idx_bots_creator_id ON bots(creator_id);

-- Add message type support for bot responses
ALTER TABLE messages ADD COLUMN IF NOT EXISTS message_type VARCHAR(50) DEFAULT 'text';
ALTER TABLE messages ADD COLUMN IF NOT EXISTS metadata JSONB;

-- Real-time messaging improvements
CREATE INDEX IF NOT EXISTS idx_messages_chat_timestamp ON messages(chat_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
```

## 🎯 Features Overview

### Core Features
- **Real-time messaging** with instant updates
- **Group chats** with advanced management
- **Visual bot builder** with drag-and-drop interface
- **Dark/Light theme** with system integration
- **User presence** and typing indicators
- **Message history** and search

### Advanced Bot Features
- **API Integration Templates** for external services
- **OpenAI Compatible** endpoints for AI responses
- **Weather Integration** with real-time data
- **News API** for latest headlines
- **Cryptocurrency** prices and market data
- **Quote System** for daily inspiration
- **Custom Rule Engine** with multiple trigger types

### Technical Features
- **Flutter 3.0+** with modern widgets
- **Supabase Backend** for real-time data
- **Material Design 3** with dynamic theming
- **Responsive UI** for all screen sizes
- **Offline Support** with local caching
- **Performance Optimized** with lazy loading

## 🛠️ Development Notes

### Bot Creation Debug
If bot creation fails, check:
1. Supabase connection and authentication
2. Database permissions for the `bots` table
3. JSON configuration validity
4. Username uniqueness constraints

### Theme Issues
For theme-related problems:
1. Ensure `SystemChrome.setSystemUIOverlayStyle` is called after build context is available
2. Check that all custom colors use `Theme.of(context).colorScheme`
3. Verify input decorations use theme-aware colors

### Real-time Messaging
For messaging issues:
1. Check Supabase real-time subscriptions
2. Verify message stream listeners are properly set up
3. Ensure UI updates happen on the main thread
4. Check for proper error handling in message sending

## 📞 Support

For issues and feature requests, please check the existing issues or create a new one with detailed information about the problem and steps to reproduce.