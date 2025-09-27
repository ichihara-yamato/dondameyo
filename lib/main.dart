import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ドンだめよ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isMonitoring = false;
  AudioPlayer? audioPlayer;
  StreamSubscription<AccelerometerEvent>? accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioPlayer!.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    ));
    accelerometerSubscription = accelerometerEvents.listen((event) {
      if (!isMonitoring) return;

      final magnitude = event.x * event.x + event.y * event.y + event.z * event.z;
      final acceleration = sqrt(magnitude);

      debugPrint('Acceleration: $acceleration');

      if (acceleration > 40.0) {
        debugPrint('Fall detected! Acceleration: $acceleration');
        audioPlayer?.play(AssetSource('warning.mp3'));
        debugPrint('Sound played');
        _showStopDialog();
      }
    });
  }

  @override
  void dispose() {
    accelerometerSubscription?.cancel();
    audioPlayer?.dispose();
    super.dispose();
  }

  void _toggleMonitoring() {
    setState(() {
      isMonitoring = !isMonitoring;
    });
  }

  void _showStopDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('警告音を停止'),
        content: const Text('落下を検知しました。音を停止しますか？'),
        actions: [
          TextButton(
            onPressed: () {
              audioPlayer?.stop();
              setState(() {
                isMonitoring = false;
              });
              Navigator.of(context).pop();
            },
            child: const Text('停止'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ドンだめよ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
                    Expanded(
                      child: _SquarePanel(
                        label: isMonitoring ? '起動中' : '起動',
                        icon: isMonitoring ? Icons.stop : Icons.play_arrow,
                        backgroundImage: 'assets/button_bg1.png',
                        onTap: _toggleMonitoring,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SquarePanel(
                        label: '設定',
                        icon: Icons.settings,
                        backgroundImage: 'assets/button_bg2.png',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        ),
                      ),
                    ),
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
  }) : assert(
         icon != null || iconPath != null,
         'Either icon or iconPath must be provided',
       ),
       assert(
         color != null || backgroundImage != null,
         'Either color or backgroundImage must be provided',
       );

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
            image: backgroundImage != null
                ? DecorationImage(
                    image: AssetImage(backgroundImage!),
                    fit: BoxFit.cover,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconPath != null)
                  Image.asset(
                    iconPath!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  )
                else
                  Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
