import 'package:flutter/material.dart';

class RealTimeScreen extends StatelessWidget {
  const RealTimeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("실시간 화면", style: TextStyle(fontSize: 20)),
    );
  }
}
