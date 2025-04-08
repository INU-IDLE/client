import 'package:flutter/material.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("소식 화면", style: TextStyle(fontSize: 20)),
    );
  }
}
