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
                          content: const SingleChildScrollView(
                            child: Text(
                              'この利用規約（以下、「本規約」といいます。）は、ニューズジャパン株式会社（以下、「当社」といいます。）が提供する「ドンだめよ」アプリケーション（以下、「本アプリ」といいます。）の利用条件を定めるものです。ユーザーの皆さま（以下、「ユーザー」といいます。）には、本規約に従って、本アプリをご利用いただきます。\n\n'
                              '1. 適用\n\n'
                              '本規約は、ユーザーと当社との間の本アプリの利用に関わる一切の関係に適用されるものとします。\n\n'
                              '2. 利用資格\n\n'
                              'ユーザーは、本アプリを利用するにあたり、以下の条件を満たすものとします。\n'
                              '- 未成年者の場合、保護者の同意を得ていること。\n'
                              '- 本規約に同意すること。\n\n'
                              '3. サービスの概要\n\n'
                              '本アプリは、スマートフォンの加速度センサーを利用して衝撃を検知し、警告音を再生することで、落とし物防止を支援するアプリケーションです。本アプリは、子供向けに設計されており、安全な利用を目的としています。\n\n'
                              '4. 禁止事項\n\n'
                              'ユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません。\n'
                              '- 本アプリの不正利用や改変。\n'
                              '- 当社または第三者の権利を侵害する行為。\n'
                              '- 法令に違反する行為。\n'
                              '- 本アプリの正常な動作を妨げる行為。\n\n'
                              '5. 免責事項\n\n'
                              '当社は、本アプリの利用により生じた損害（データの損失、機器の故障など）について、一切の責任を負いません。ユーザーは自己責任で本アプリを利用するものとします。また、本アプリは完全性を保証するものではなく、検知が失敗する場合があります。\n\n'
                              '6. 知的財産権\n\n'
                              '本アプリに関する著作権、商標権、その他の知的財産権は、当社または正当な権利者に帰属します。ユーザーは、これらを侵害しないよう注意するものとします。\n\n'
                              '7. 変更\n\n'
                              '当社は、必要に応じて本規約を変更することができるものとします。変更後の規約は、本アプリ上に掲載された時点で効力を生じるものとします。ユーザーは定期的に本規約を確認するものとします。\n\n'
                              '8. 連絡先\n\n'
                              '本アプリに関するお問い合わせは、以下の連絡先までお願いします。\n\n'
                              'ニューズジャパン株式会社\n'
                              'メール: info@newsjapan.co.jp\n\n'
                              '制定日: 2025年9月27日',
                            ),
                          ),
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
