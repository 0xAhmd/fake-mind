import 'package:fake_mind/chat/presentation/cubit/chat_cubit_factory.dart';
import 'package:fake_mind/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'chat/presentation/pages/chat_list_page.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    debugPrint('Environment variables loaded successfully');

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  } catch (e) {
    debugPrint('Initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatCubitFactory.create(),
      child: MaterialApp(
        title: 'Fake Mind',
        theme: ThemeData(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: Colors.green,
            selectionColor: Colors.green.shade200,
            selectionHandleColor: Colors.green,
          ),
          fontFamily: GoogleFonts.lato().fontFamily,
          scaffoldBackgroundColor: kScaffoldBackgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const ChatListPage(),
      ),
    );
  }
}
