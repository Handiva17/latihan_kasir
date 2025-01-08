import 'package:flutter/material.dart';
import 'login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://sldlwwcvlqduyzuryydh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNsZGx3d2N2bHFkdXl6dXJ5eWRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYxMzI2MzQsImV4cCI6MjA1MTcwODYzNH0.ouCFMy7Gwaq-cMDze2ajwPawPSwN5b_Tfn-KObEUhA0',
  );
  runApp(MyApp());
}
        
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Halaman Login';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: LoginScreen(),
      ),
    );
  }
}
