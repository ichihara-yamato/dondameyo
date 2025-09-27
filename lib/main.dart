import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool('has_seen_startup') ?? false;
  runApp(MyApp(hasSeenStartup: seen));
}

class MyApp extends StatelessWidget {
  final bool hasSeenStartup;
  const MyApp({super.key, required this.hasSeenStartup});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ドンだめよ',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: hasSeenStartup ? const HomePage() : const StartupScreen(),
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    // Show the loading screen for 2.5 seconds, then mark as seen and navigate.
    Future.delayed(const Duration(milliseconds: 2500), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_startup', true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show the asset image. Make sure pubspec.yaml includes `assets/dondame_kids.png`.
            Image.asset('assets/dondame_kids.png', width: 240, height: 240, fit: BoxFit.contain),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ドンだめよ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // Two square panels placed vertically with spacing
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _SquarePanel(
                      label: '起動',
                      icon: Icons.play_arrow,
                      backgroundImage: 'assets/button_bg1.png',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StartPage())),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _SquarePanel(
                      label: '設定',
                      icon: Icons.settings,
                      backgroundImage: 'assets/button_bg2.png',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquarePanel extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? iconPath;
  final VoidCallback onTap;
  final Color? color;
  final String? backgroundImage;

  const _SquarePanel({
    required this.label,
    this.icon,
    this.iconPath,
    required this.onTap,
    this.color,
    this.backgroundImage,
  }) : assert(icon != null || iconPath != null, 'Either icon or iconPath must be provided'),
       assert(color != null || backgroundImage != null, 'Either color or backgroundImage must be provided');

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            image: backgroundImage != null ? DecorationImage(
              image: AssetImage(backgroundImage!),
              fit: BoxFit.cover,
            ) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0,4))],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconPath != null)
                  Image.asset(iconPath!, width: 48, height: 48, fit: BoxFit.contain)
                else
                  Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('起動')),
      body: const Center(child: Text('ここでゲームや処理を開始します。')),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: const Center(child: Text('設定画面')), 
    );
  }
}
