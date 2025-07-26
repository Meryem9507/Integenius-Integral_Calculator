import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:integenius_app/screens/homepage.dart';
import 'package:integenius_app/screens/how_to_use.dart';
import 'package:integenius_app/screens/calculate.dart';
import 'package:flutter/rendering.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPaintSizeEnabled = false;
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const Integenius());
}

class Integenius extends StatelessWidget {
  const Integenius({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/calculate': (context) => const CalculateScreen(),
        '/howToUse': (context) => const HelpScreen(),
      },
    );
  }
}
