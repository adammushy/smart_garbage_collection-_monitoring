import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:SGMCS/firebase_options.dart';
import 'package:SGMCS/providers/data-provider.dart';
import 'package:SGMCS/providers/default_provider.dart';
import 'package:SGMCS/providers/user-provider.dart';
import 'package:SGMCS/views/base/splash_screen.dart';
import 'package:SGMCS/views/screens/auth/login_user.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:json_theme/json_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final themelight = await rootBundle.loadString('assets/lightTheme.json');
  final lightJson = jsonDecode(themelight);
  final lighttheme = ThemeDecoder.decodeThemeData(lightJson)!;

  final themeDark = await rootBundle.loadString('assets/darkTheme.json');
  final darkJson = jsonDecode(themeDark);
  final darkTheme = ThemeDecoder.decodeThemeData(darkJson)!;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DefaultProvider()),
        ChangeNotifierProvider(create: (context) => UserManagementProvider()),
        ChangeNotifierProvider(create: (context) => DataManagementProvider())
      ],
      child: MyApp(
        theme: lighttheme,
        darkTheme: darkTheme,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  // const MyApp({super.key});
  const MyApp({super.key, required this.theme, required this.darkTheme});
  final ThemeData theme;
  final ThemeData darkTheme;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Garbage Monitoring and Collection system',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,

      // home: const SplashScreen(),
      home: Login(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '1',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
