import 'package:fake_mind/chat/presentation/chat_page.dart';
import 'package:fake_mind/chat/presentation/chat_provider.dart';
import 'package:fake_mind/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: kscaffoldBackgroundColor,
      statusBarIconBrightness: Brightness.light,
    ),
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: GoogleFonts.lato().fontFamily,

        scaffoldBackgroundColor: kscaffoldBackgroundColor,
      ),

      debugShowCheckedModeBanner: false,
      home: ChatPage(),
    );
  }
}

