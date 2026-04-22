import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'views/home_view.dart';
import 'views/climate_view.dart';
import 'views/power_view.dart';
import 'views/system_view.dart';
import 'views/stats_view.dart';
import 'views/health_view.dart';

// Conditionally import background service
import 'services/background_service.dart' if (dart.library.js_interop) 'services/background_service_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable persistence for Realtime Database BEFORE any usage
  if (!kIsWeb) {
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      debugPrint("Firebase Persistence Enabled");
    } catch (e) {
      debugPrint("Error setting persistence: $e");
    }
    // Small delay to ensure persistence flag is processed before background isolate starts
    await Future.delayed(const Duration(milliseconds: 100));
    await initializeService();
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirebaseService()),
      ],
      child: const SmartHomeApp(),
    ),
  );
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111827),
        primaryColor: const Color(0xFF3B82F6),
        cardColor: const Color(0xFF1F2937),
        useMaterial3: true,
      ),
      home: const WebWrapper(child: MainScaffold()),
    );
  }
}

class WebWrapper extends StatelessWidget {
  final Widget child;
  const WebWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 50,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _views = const [
    HomeView(),
    ClimateView(),
    PowerView(),
    SystemView(),
    StatsView(),
    HealthView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    final firebase = context.read<FirebaseService>();
    switch (index) {
      case 0: firebase.forceSync('pzem'); break;   // HOME
      case 1: firebase.forceSync('ac'); break;     // CLIMATE
      case 2: firebase.forceSync('relays'); break; // POWER
      case 3: firebase.forceSync('pc'); break;     // SYSTEM
      case 4: firebase.forceSync('energy'); break; // STATS
      case 5: firebase.forceSync('all'); break;    // HEALTH
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = context.select<FirebaseService, bool>((s) => s.isConnected);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _views[_selectedIndex],
            if (!isConnected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    'CONNECTION LOST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF1F2937), width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF111827),
          selectedItemColor: const Color(0xFF3B82F6),
          unselectedItemColor: const Color(0xFF6B7280),
          selectedFontSize: 9,
          unselectedFontSize: 9,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: FaIcon(FontAwesomeIcons.house, size: 20),
              ),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: FaIcon(FontAwesomeIcons.snowflake, size: 20),
              ),
              label: 'CLIMATE',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: FaIcon(FontAwesomeIcons.plug, size: 20),
              ),
              label: 'POWER',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: FaIcon(FontAwesomeIcons.desktop, size: 20),
              ),
              label: 'SYSTEM',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: FaIcon(FontAwesomeIcons.chartBar, size: 20),
              ),
              label: 'STATS',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: FaIcon(FontAwesomeIcons.heartPulse, size: 20),
              ),
              label: 'HEALTH',
            ),
          ],
        ),
      ),
    );
  }
}
