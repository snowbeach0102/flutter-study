import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

void main() {
  // 웹 뷰 요소 등록
  ui_web.platformViewRegistry.registerViewFactory(
    'my-html-view',
    (int viewId) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      
      // 여기에 원하는 HTML 코드를 작성하세요
      div.innerHTML = '''
       
      ''';
      return div;
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MetaCheck Web',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Web + HTML 연동'),
          backgroundColor: Colors.blue.shade100,
        ),
        body: const Center(
          child: SizedBox(
            width: 480,
            height: 300,
            child: HtmlElementView(viewType: 'my-html-view'),
          ),
        ),
      ),
    );
  }
}