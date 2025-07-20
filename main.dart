import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Import separated files
import 'models.dart';
import 'services.dart';
import 'screens.dart';
import 'bot_builder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://egatfepylqfaxhupbkvg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVnYXRmZXB5bHFmYXhodXBia3ZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5MzA5NzQsImV4cCI6MjA2ODUwNjk3NH0.7YXlLWHKndyY4pLtb7XX7z3My6xsdZpF1_54LL4-CVg',
  );
  
  runApp(const SecumeApp());
}

// --- App Theme and Configuration ---

class SecumeApp extends StatelessWidget {
  const SecumeApp({super.key});

  ThemeData _buildDarkTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF00ADB5),
      scaffoldBackgroundColor: const Color(0xFF222831),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00ADB5),
        secondary: Color(0xFF00ADB5),
        surface: Color(0xFF393E46),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFEEEEEE),
        error: Color(0xFFFF6B6B),
      ),
      fontFamily: 'Manrope',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFEEEEEE), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFFEEEEEE)),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEEEEEE)),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        labelLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF222831),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22.0,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.bold,
          color: Color(0xFFEEEEEE),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF222831),
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF222831),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF222831),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF00ADB5),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00ADB5),
        secondary: Color(0xFF00ADB5),
        surface: Color(0xFFFFFFFF),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1A1A1A),
        error: Color(0xFFD32F2F),
      ),
      fontFamily: 'Manrope',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1A1A1A), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        labelLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22.0,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFFF8F9FA),
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFFF8F9FA),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFFF8F9FA),
      ),
      cardTheme: const CardTheme(
        color: Color(0xFFFFFFFF),
        elevation: 2,
        shadowColor: Color(0x1A000000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secume',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system, // Follow system theme
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          final session = snapshot.data?.session;
          if (session != null) {
            return const MainScreen();
          } else {
            return const SignInScreen();
          }
        },
      ),
    );
  }
}

// --- Authentication Screens ---

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set system chrome navigation bar color
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF222831),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF222831),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = await SupabaseService.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (user != null) {
      // Navigation handled by StreamBuilder
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in failed. Please check your credentials.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Secume',
                textAlign: TextAlign.center,
                style: GoogleFonts.pacifico(fontSize: 60),
              ),
              const SizedBox(height: 48.0),
              _buildTextField(hint: 'Email', controller: _emailController),
              const SizedBox(height: 16.0),
              _buildTextField(hint: 'Password', controller: _passwordController, obscure: true),
              const SizedBox(height: 24.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                onPressed: _isLoading ? null : _signIn,
              ),
              TextButton(
                child: Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_usernameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = await SupabaseService.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _usernameController.text.trim(),
      _fullNameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user != null) {
      // Navigation handled by StreamBuilder
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up failed. Username or email might already exist.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Join Secume',
              textAlign: TextAlign.center,
              style: GoogleFonts.pacifico(fontSize: 50),
            ),
            const SizedBox(height: 32.0),
            _buildTextField(hint: 'Full Name', controller: _fullNameController),
            const SizedBox(height: 16.0),
            _buildTextField(hint: 'Username', controller: _usernameController),
            const SizedBox(height: 16.0),
            _buildTextField(hint: 'Email', controller: _emailController),
            const SizedBox(height: 16.0),
            _buildTextField(hint: 'Password', controller: _passwordController, obscure: true),
            const SizedBox(height: 24.0),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Create Account', 
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 16, 
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      )
                    ),
                onPressed: _isLoading ? null : _signUp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for text fields on auth screens
Widget _buildTextField({required String hint, TextEditingController? controller, bool obscure = false}) {
  return Builder(
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: isDark ? const Color(0xFF393E46) : const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
    },
  );
}

// --- Main App Screen ---

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  AppUser? _currentUser;
  List<Widget> _screens = [];
  List<String> _screenTitles = [];
  List<List<Widget>?> _appBarActions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _setupScreens();
    // Set user as online when app starts
    SupabaseService.setOnlineStatus(true);
    // Set system chrome navigation bar color
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF222831),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF222831),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Set user as offline when app closes
    SupabaseService.setOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground
        SupabaseService.setOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is in background or closed
        SupabaseService.setOnlineStatus(false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final userProfile = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .single();
        
        setState(() {
          _currentUser = AppUser.fromJson(userProfile);
        });
      } catch (e) {
        print('Error loading user: $e');
      }
    }
  }

  void _setupScreens() {
    _screens = [
      const ChatsScreen(),
      const CallsScreen(),
      const PrivacyScreen(),
      const BotManagementScreen(),
    ];

    _screenTitles = ['Secume', 'Calls', 'Privacy', 'My Bots'];

    _appBarActions = [
      [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserSearchScreen()),
            );
          },
        ),
      ],
      null,
      null,
      null, // Removed add icon for bot creation - only keep FloatingActionButton
    ];
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.of(context).pop();
    // Fixed navigation - don't auto-return to homepage
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget?> floatingActionButtons = [
      FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserSearchScreen()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      FloatingActionButton(
        onPressed: () {},
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add_ic_call, color: Colors.white),
      ),
      null,
      FloatingActionButton(
        onPressed: () {
                  Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VisualBotBuilderScreen()),
        ).then((_) => setState(() {}));
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: Container(
          padding: const EdgeInsets.all(4),
          child: CustomIcon(
            painter: RobotIconPainter(color: Colors.white),
            size: 24,
          ),
        ),
      ),
    ];

    return PopScope(
      canPop: _selectedIndex == 0, // Allow system back only on home screen
      onPopInvoked: (didPop) {
        if (!didPop && _selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0; // Go back to home screen instead of exiting
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _screenTitles[_selectedIndex],
            style: _selectedIndex == 0
                ? GoogleFonts.pacifico(fontSize: 26)
                : null,
          ),
          leading: _selectedIndex == 0 
              ? null // Show drawer icon on home screen
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0; // Go back to home screen
                    });
                  },
                ),
          actions: _appBarActions[_selectedIndex],
        ),
        drawer: _selectedIndex == 0 ? AppDrawer(
          user: _currentUser!,
          selectedIndex: _selectedIndex,
          onItemTapped: _onDrawerItemTapped,
        ) : null, // Only show drawer on home screen
        body: _screens[_selectedIndex],
        floatingActionButton: floatingActionButtons[_selectedIndex],
      ),
    );
  }
}

// --- AppDrawer ---

class AppDrawer extends StatelessWidget {
  final AppUser user;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const AppDrawer({
    super.key,
    required this.user,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.call_outlined,
                  selectedIcon: Icons.call,
                  text: 'Calls',
                  index: 1,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.privacy_tip_outlined,
                  selectedIcon: Icons.privacy_tip,
                  text: 'Privacy',
                  index: 2,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.smart_toy_outlined,
                  selectedIcon: Icons.smart_toy,
                  text: 'My Bots',
                  index: 3,
                  customIcon: Container(
                    padding: const EdgeInsets.all(4),
                    child: CustomIcon(
                      painter: RobotIconPainter(
                        color: selectedIndex == 3 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[400]!
                      ),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await SupabaseService.signOut();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222831) : const Color(0xFFF8F9FA),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.transparent,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFEEEEEE) : const Color(0xFF1A1A1A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B6B6B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String text,
    required int index,
    Widget? customIcon,
  }) {
    final isSelected = selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: customIcon ?? Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? Theme.of(context).primaryColor : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600]),
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700]),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => onItemTapped(index),
      ),
    );
  }
}

// Add custom robot icon
class CustomIcon extends StatelessWidget {
  final CustomPainter painter;
  final double size;

  const CustomIcon({
    super.key,
    required this.painter,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: painter,
      size: Size(size, size),
    );
  }
}

class RobotIconPainter extends CustomPainter {
  final Color color;

  const RobotIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;

    // Robot head (main body)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.15, w * 0.6, w * 0.5),
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(headRect, strokePaint);

    // Eyes
    canvas.drawCircle(Offset(w * 0.35, h * 0.35), w * 0.05, paint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.35), w * 0.05, paint);

    // Antenna
    canvas.drawLine(
      Offset(w * 0.5, h * 0.15),
      Offset(w * 0.5, h * 0.05),
      strokePaint,
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.05), w * 0.03, paint);

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.25, h * 0.6, w * 0.5, w * 0.25),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(bodyRect, strokePaint);

    // Arms
    canvas.drawLine(
      Offset(w * 0.25, h * 0.7),
      Offset(w * 0.1, h * 0.75),
      strokePaint,
    );
    canvas.drawLine(
      Offset(w * 0.75, h * 0.7),
      Offset(w * 0.9, h * 0.75),
      strokePaint,
    );

    // Hands
    canvas.drawCircle(Offset(w * 0.1, h * 0.75), w * 0.04, paint);
    canvas.drawCircle(Offset(w * 0.9, h * 0.75), w * 0.04, paint);

    // Legs
    canvas.drawLine(
      Offset(w * 0.35, h * 0.85),
      Offset(w * 0.35, h * 0.95),
      strokePaint,
    );
    canvas.drawLine(
      Offset(w * 0.65, h * 0.85),
      Offset(w * 0.65, h * 0.95),
      strokePaint,
    );

    // Feet
    canvas.drawOval(
      Rect.fromLTWH(w * 0.3, h * 0.93, w * 0.1, w * 0.06),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.6, h * 0.93, w * 0.1, w * 0.06),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
