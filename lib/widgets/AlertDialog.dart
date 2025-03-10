import 'package:flutter/material.dart';

class StationSelectionDialog extends StatelessWidget {
  const StationSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    String? departureStation;
    String? arrivalStation;

    // AlertDialog을 사용하여 팝업 표시
    return AlertDialog(
      title: const Text('역 선택'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '출발지',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Elevated 버튼을 사용해서 출발지 도착지 선택할 수 있도록 함
          // 버튼 클릭하면 해당 역 이름이 변수에 저장됨
          ElevatedButton(
            onPressed: () {
              departureStation = '서울역';
              debugPrint('출발지 선택: $departureStation');
            },
            child: const Text('서울역'),
          ),
          ElevatedButton(
            onPressed: () {
              departureStation = '송도달빛축제공원역';
              debugPrint('출발지 선택: $departureStation');
            },
            child: const Text('송도달빛축제공원역'),
          ),
          const SizedBox(height: 20),
          const Text(
            '도착지',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              arrivalStation = '강남역';
              debugPrint('도착지 선택: $arrivalStation');
            },
            child: const Text('강남역'),
          ),
          ElevatedButton(
            onPressed: () {
              arrivalStation = '종로3가';
              debugPrint('도착지 선택: $arrivalStation');
            },
            child: const Text('종로3가'),
          ),
        ],
      ),
      actions: [
        // TextButton 으로 "취소" "확인" 버튼 추가
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            debugPrint('출발지: $departureStation, 도착지: $arrivalStation');
            Navigator.of(context).pop();
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}
