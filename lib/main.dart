import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mut6/MapScreen.dart';
import 'package:mut6/SchoolDashboardScreen.dart';
import 'package:mut6/WelcomeScreen.dart';
import 'package:mut6/add_admin_screen.dart';
import 'package:mut6/home_screen.dart';
import 'package:mut6/login_screen.dart';
import 'package:mut6/map_picker_screen.dart';
import 'package:mut6/modifyAdminScreen.dart';
import 'package:mut6/provider.dart';
import 'package:mut6/providers/TeacherProvider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mutabie App',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => LoginSchoolScreen(),
        '/AddAdminScreen': (context) => AddAdminScreen(),
        '/AdminScreen': (context) => AdminListScreen(),
        '/MapScreen': (context) => MapScreen(),
        '/SchoolDashboardScreen': (context) => SchoolDashboardScreen(),
        '/map_picker': (context) => MapPickerScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
