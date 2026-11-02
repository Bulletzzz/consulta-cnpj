import 'package:flutter/material.dart';

import 'screens/consulta_page.dart';

void main() => runApp(const ConsultaCnpjApp());

class ConsultaCnpjApp extends StatelessWidget {
  const ConsultaCnpjApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Consulta CNPJ',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B50)),
      scaffoldBackgroundColor: const Color(0xFFF3F6F4),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F9F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCEDBD4)),
        ),
      ),
    ),
    home: const ConsultaPage(),
  );
}
