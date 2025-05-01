import 'package:flutter/material.dart';
import '../screen2/my_info_screen.dart';
import '../screen2/inquiry_list_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = true;
    String name = isLoggedIn ? '한수연' : '로그인';
    String email = isLoggedIn ? 'rushcutter@naver.com' : '로그인';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('마이러쉬'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            onTap: () {
              if (isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyInfoScreen()),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 설정/피드백/앱 정보 (임시 레이아웃)
          const Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(title: const Text('알림 설정'), onTap: () {}),
          ListTile(title: const Text('언어 설정'), onTap: () {}),
          const SizedBox(height: 16),
          const Text('피드백 및 지원', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(title: const Text('자주 묻는 질문'), onTap: () {}),
          ListTile(
            title: const Text('문의하기 / 오류 신고'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InquiryListScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('앱 정보', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(title: const Text('버전 정보'), onTap: () {}),
          ListTile(title: const Text('이용약관 및 개인정보 처리방침'), onTap: () {}),
          ListTile(title: const Text('오픈소스 라이선스'), onTap: () {}),
          const SizedBox(height: 16),

        ],
      ),
    );
  }
}
