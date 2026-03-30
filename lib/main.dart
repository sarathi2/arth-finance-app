import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

// ── Providers ──
import 'package:arth/ai_chat_provider.dart';
import 'package:arth/dashboard_provider.dart';
import 'package:arth/transaction_provider.dart';
import 'package:arth/budget_provider.dart';
import 'package:arth/goal_provider.dart';
import 'package:arth/profile_provider.dart';
import 'package:arth/auth_provider.dart';

// ── Screens ──
import 'package:arth/login_screen.dart';
import 'package:arth/email_auth_screen.dart';
import 'package:arth/profile_setup_screen.dart';
import 'package:arth/home_screen.dart';
import 'package:arth/ai_chat_screen.dart';
import 'package:arth/transactions_screen.dart';
import 'package:arth/budget_screen.dart';
import 'package:arth/goal_screen.dart';
import 'package:arth/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ArthApp());
}

class ArthApp extends StatelessWidget {
  const ArthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AiChatProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        title: 'Arth',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1D9E75),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1D9E75),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/email-auth': (_) => const EmailAuthScreen(),
          '/profile-setup': (_) => const ProfileSetupScreen(),
          '/home': (_) => const _AppStartup(),
        },
        home: const _AuthGate(),
      ),
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────────────────────────
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'அ',
                    style: TextStyle(
                      fontSize: 60,
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Color(0xFF1D9E75)),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }
        return const _AppStartup();
      },
    );
  }
}

// ── App Startup ───────────────────────────────────────────────────────────────
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) => const MainShell();
}

// ── Main Shell (Upgraded Navigation & Back Button) ────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Track which tabs have been visited so we only build them once
  final Set<int> _visitedTabs = {0};

  static const List<Widget> _screens = [
    HomeScreen(),
    AiChatScreen(),
    TransactionsScreen(),
    BudgetScreen(),
    GoalScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // PopScope intercepts the physical Android back button!
    return PopScope(
      canPop: _currentIndex == 0, // Only allow app exit if we are on the Home tab
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return; // If it already popped, do nothing
        
        // If we are NOT on the Home tab, jump back to Home (index 0)
        setState(() {
          _currentIndex = 0;
        });
      },
      child: Scaffold(
        body: Stack(
          children: List.generate(_screens.length, (index) {
            final visited = _visitedTabs.contains(index);
            return Offstage(
              offstage: _currentIndex != index,
              child: visited ? _screens[index] : const SizedBox.shrink(),
            );
          }),
        ),
        // Upgraded to a fixed BottomNavigationBar to perfectly align 6 items
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() {
                _visitedTabs.add(i);
                _currentIndex = i;
              });
            },
            type: BottomNavigationBarType.fixed, // Forces perfect alignment!
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1D9E75),
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.smart_toy_outlined),
                activeIcon: Icon(Icons.smart_toy),
                label: 'Arth AI',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'History', // Shortened from Transactions
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_outline),
                activeIcon: Icon(Icons.pie_chart),
                label: 'Budget',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.flag_outlined),
                activeIcon: Icon(Icons.flag),
                label: 'Goals',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}