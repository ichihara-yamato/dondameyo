import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  double threshold = 40.0;

  @override
  void initState() {
    super.initState();
    _loadThreshold();
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

      if (acceleration > threshold) {
        debugPrint('Fall detected! Acceleration: $acceleration');
        audioPlayer?.play(AssetSource('warning.mp3'));
        debugPrint('Sound played');
        _showStopDialog();
      }
    });
  }

  Future<void> _loadThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      threshold = prefs.getDouble('threshold') ?? 40.0;
    });
  }

  void _updateThreshold(double newThreshold) {
    setState(() {
      threshold = newThreshold;
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
                            builder: (_) => SettingsPage(onThresholdChanged: _updateThreshold),
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

class SettingsPage extends StatefulWidget {
  final Function(double) onThresholdChanged;

  const SettingsPage({super.key, required this.onThresholdChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double threshold = 40.0;
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _loadThreshold();
    _loadPackageInfo();
  }

  Future<void> _loadThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      threshold = prefs.getDouble('threshold') ?? 40.0;
    });
  }

  Future<void> _loadPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '設定',
          style: TextStyle(color: Colors.white),
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '衝撃検知設定',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '閾値: ${threshold.toStringAsFixed(1)} m/s²',
                    style: const TextStyle(color: Colors.black),
                  ),
                  Slider(
                    value: threshold,
                    min: 10,
                    max: 100,
                    divisions: 90,
                    label: threshold.toStringAsFixed(1),
                    onChanged: (value) async {
                      setState(() {
                        threshold = value;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setDouble('threshold', value);
                      widget.onThresholdChanged(value);
                    },
                  ),
                  Text(
                    threshold < 30
                        ? '低い: 軽い衝撃でも検知 (例: 机に軽く置く)'
                        : threshold < 60
                            ? '中程度: 普通の衝撃で検知 (例: 机に普通に叩く)'
                            : '高い: 強い衝撃のみ検知 (例: 机に強く叩く)',
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'このアプリについて',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (packageInfo != null) ...[
                    ListTile(
                      title: const Text(
                        'バージョン',
                        style: TextStyle(color: Colors.black),
                      ),
                      subtitle: Text(
                        packageInfo!.version,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    ListTile(
                      title: const Text(
                        'ビルド',
                        style: TextStyle(color: Colors.black),
                      ),
                      subtitle: Text(
                        packageInfo!.buildNumber,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      '利用規約',
                      style: TextStyle(color: Colors.black),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward,
                      color: Colors.black,
                    ),
                    onTap: () {
                      // 利用規約を表示
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('利用規約'),
                          content: const Text('ここに利用規約の内容を記載します。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('閉じる'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text(
                      'プライバシー・ポリシー',
                      style: TextStyle(color: Colors.black),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward,
                      color: Colors.black,
                    ),
                    onTap: () {
                      // プライバシー・ポリシーを表示
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('プライバシー・ポリシー'),
                          content: const Text('ここにプライバシー・ポリシーの内容を記載します。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('閉じる'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
