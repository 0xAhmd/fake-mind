import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'chat/presentation/chat_list_page.dart';
import 'chat/presentation/chat_provider.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FakeMind Chat',
      theme: ThemeData(
        fontFamily: GoogleFonts.lato().fontFamily,
        scaffoldBackgroundColor: kscaffoldBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const ChatListPage(),
    );
  }
}
