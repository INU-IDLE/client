import 'package:flutter/material.dart';
import '../models/station.dart';
import 'search_screen.dart';
import 'route_result_screen.dart';
import 'dart:ui';
import 'home_screen.dart';
import 'package:rushcutter/widgets/station_component.dart';
import 'package:rushcutter/data/station_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:rushcutter/screen/home_screen.dart';
import 'bottom_category_bar.dart';
import 'package:rushcutter/layout/main_layout.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.2),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.black, size: 18),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class SubwayMapScreen extends StatefulWidget {
  final String? searchQuery;
  final bool isSelectingDeparture;
  final dynamic selectedStation;
  final Matrix4? initialTransformation;
  final String? selectedStationId;
  final String selectedCategory;


  const SubwayMapScreen({
    // this.searchQuery,
    required this.isSelectingDeparture,
    this.searchQuery,
    required this.selectedStation,
    this.initialTransformation,
    this.selectedStationId,
    this.selectedCategory = 'HOME',
    super.key,
  });


  @override
  State<SubwayMapScreen> createState() => _SubwayMapScreenState();
}

class _SubwayMapScreenState extends State<SubwayMapScreen> {
  late final TransformationController _transformationController; // 추가
  // late StationService _stationService;
  Station? selectedStation;
  String? departureStation; // 출발역
  String? arrivalStation; // 도착역
  String? searchedStation; // 검색한 역
  bool showDepartureButton = true; // 출발지 버튼 표시 여부
  bool showArrivalButton = true; // 도착지 버튼 표시 여부
  late TextEditingController _departureController;
  late TextEditingController _arrivalController;
  String? selectedStationId;

  bool showButtons = false; // 선택 후 버튼 사라지게
  Station? _lastStationForButton; // 상태변수 (위치 기억하려고)
  String selectedCategory = 'HOME';

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.selectedCategory;
    _transformationController = TransformationController(
      widget.initialTransformation ?? Matrix4.identity(), // 시점 유지
    );
    searchedStation = widget.searchQuery; // 검색어로 초기화

    // HomeScreen에서 전달된 selectedStation 처리 - 버튼 클릭하는 것에 따라 결과값 반영
    if (widget.selectedStation != null && widget.selectedStation is Station) {
      final station = widget.selectedStation as Station;
      showButtons = false; // 초기값 false 지정
      if (station.id.isNotEmpty) {
        selectedStationId = station.id;
        selectedStation = station;
        // 출발/도착역에 자동 입력
        if (widget.isSelectingDeparture) {
          departureStation = station.stationNm;
        } else {
          arrivalStation = station.stationNm;
        }
        // 화면 중앙 세팅
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _transformationController.value = Matrix4.identity()
            ..translate(
              -station.cx * 1.3 + MediaQuery
                  .of(context)
                  .size
                  .width / 2,
              -station.cy * 1.3 + MediaQuery
                  .of(context)
                  .size
                  .height / 2,
            )
            ..scale(1.3);
        });
      }
    }
    // 검색 쿼리 + 기본값 설정
    else if (widget.searchQuery != null) {
      final station = stationData.firstWhere(
            (s) => s.stationNm == widget.searchQuery,
        orElse: () =>
            Station(id: '',
                cx: 0,
                cy: 0,
                r: 0,
                stationNm: '',
                line: ''),
      );

      if (station.id.isNotEmpty) {
        // 화면 중앙 이동 동일
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _transformationController.value = Matrix4.identity()
            ..translate(
                -station.cx * 1.3 + MediaQuery
                    .of(context)
                    .size
                    .width / 2,
                -station.cy * 1.3 + MediaQuery
                    .of(context)
                    .size
                    .height / 2
            )
            ..scale(1.3);

          setState(() {
            // 기본 정보 제공
            selectedStationId = station.id;
            selectedStation = station;
          });
        });
      }
    }
  }

  void _onSelectDeparture() {
    setState(() {
      departureStation = selectedStation?.stationNm;
      showButtons = false; // 역 선택 후 버튼 숨기기
    });
  }

  void _onSelectArrival() {
    setState(() {
      arrivalStation = selectedStation?.stationNm;
      showButtons = false; // 역 선택 후 버튼 숨기기
    });
  }

  void _handleStationTap(String? id) {
    final found = stationData.firstWhere(
          (s) => s.id == id,
      orElse: () =>
          Station(id: '',
              cx: 0,
              cy: 0,
              r: 0,
              stationNm: '',
              line: ''),
    );
    if (found.id.isNotEmpty) {
      // 역이 바뀔 때 애니메이션 자연스럽게 재생
      if (selectedStationId != id) {
        setState(() {
          showButtons = false;
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() {
            selectedStationId = id;
            selectedStation = found;
            _lastStationForButton = found;
            showButtons = true;
          });
        });
      }
    }
  }

  // 출발지 버튼 클릭 시 searchQuery 값 출발역에 반영
  void _setDepartureFromButton() {
    setState(() {
      if (widget.searchQuery != null) {
        departureStation = widget.searchQuery;
        // showDepartureButton = false;
        // showArrivalButton = false;
      }
    });
  }

  // 도착지 버튼 클릭 시 searchQuery 값 도착역에 반영
  void _setArrivalFromButtton() {
    setState(() {
      if (widget.searchQuery != null) {
        arrivalStation = widget.searchQuery;
        // showDepartureButton = false;
        // showArrivalButton = false;
      }
    });
  }


  // 출발역 설정 (빈칸 클릭 시)
  void _setDeparture() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(

        builder: (context) =>
            SearchScreen(
              isSelectingDeparture: false,
              initialQuery: departureStation ?? "", // 이전 입력값 전달 (null이면 빈 문자열)
            ),
      ),
    );

    if (result != null) {
      setState(() {
        departureStation = result; // 검색 결과를 출발역에 반영
      });
    }
  }

  // 도착역 설정 (빈칸 클릭 시)
  void _setArrival() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SearchScreen(
              isSelectingDeparture: false,
              initialQuery: arrivalStation ?? "", // 이전 입력값 전달 (null이면 빈 문자열)
            ),
      ),
    );
    if (result != null) {
      setState(() {
        arrivalStation = result; // 검색 결과를 도착역에 반영
      });
    }
  }


  // 출발역과 도착역 교환
  void swapStations() {
    // if (departureStation == null || arrivalStation == null) return;
    setState(() {
      String? temp = departureStation;
      departureStation = arrivalStation;
      arrivalStation = temp;
    });
  }

  // 검색 버튼 클릭 -> 결과 화면으로 이동
  void navigateToResult() {
    if (departureStation == null || arrivalStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("출발역과 도착역을 모두 입력해주세요.")),
      );
      return;
    }

    if (departureStation == arrivalStation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("출발역과 도착역이 동일할 수 없습니다.")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RouteResultScreen(
              departure: departureStation!,
              arrival: arrivalStation!,
            ),
      ),
    );
  }
  void onCategorySelected(String category) {
    if (category == 'HOME') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout(initialCategory: 'HOME')),
      );
    } else if (category == '시간표') {
      Navigator.pushReplacementNamed(context, '/timetable');
    } else if (category == '저장') {
      Navigator.pushReplacementNamed(context, '/saved');
    } else if (category == '소식') {
      Navigator.pushReplacementNamed(context, '/news');
    } else if (category == 'MY') {
      Navigator.pushReplacementNamed(context, '/mypage');
    }
  }



  void _hideButtons() {
    if (!showButtons) return; // 이미 숨김 상태면 무시
    setState(() {
      showButtons = false;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      // 애니메이션이 끝난 뒤에만 selectedStation을 null로!
      if (!showButtons) {
        setState(() {
          selectedStation = null;
          selectedStationId = null;
        });
      }
    });
  }

  // 출발역과 도착역 빈칸 생성
  Widget buildStationBox(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // 클릭 시 검색 화면으로 이동
      child: Container(
        height: 50,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ),
      ),
    );
  }

  // 선택 버튼 UI 생성
  Widget buildSelectButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
      }, // 임시 저장 결과 실제 빈칸(출발역/도착역)에 입력
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
    );
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/images/metropolitan.png'),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Station? buttonStation = selectedStation ?? _lastStationForButton;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단바 + 출발/도착역
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 상단 네비 (뒤로가기 + 타이틀 + 변환 + 검색)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new, size: 24, color: Colors.black),
                      ),
                      const Spacer(),
                      Text(
                        "노선도",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: swapStations,
                        child: const Icon(Icons.swap_horiz, size: 24, color: Colors.black),
                      ),
                      const SizedBox(width: 8),
                      // 검색 버튼을 swap 아이콘 오른쪽에 배치
                      CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        onPressed: navigateToResult,
                        child: const Text(
                          "검색",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 출발역/도착역 입력 박스 (X 버튼 포함)
                  Row(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            GestureDetector(
                              onTap: _setDeparture,
                              child: Container(
                                height: 44,
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F6F6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  departureStation ?? "출발역",
                                  style: TextStyle(
                                    color: departureStation == null ? Colors.grey[500] : Colors.black,
                                    fontSize: (departureStation == "동대문역사문화공원") ? 16 : 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            // X 버튼 (출발역 있을 때만)
                            if (departureStation != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                                onPressed: () => setState(() => departureStation = null),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            GestureDetector(
                              onTap: _setArrival,
                              child: Container(
                                height: 44,
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F6F6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  arrivalStation ?? "도착역",
                                  style: TextStyle(
                                    color: arrivalStation == null ? Colors.grey[500] : Colors.black,
                                    fontSize: (arrivalStation == "동대문역사문화공원") ? 16 : 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            // X 버튼 (도착역 있을 때만)
                            if (arrivalStation != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                                onPressed: () => setState(() => arrivalStation = null),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 노선도+버튼 (남은 공간만 차지, 아래로 스크롤 없음)
        //Positioned.fill(
        Expanded(
              child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset tapPos = box.globalToLocal(details.globalPosition);

                double minDist = double.infinity;
                Station? nearestStation;
                for (final station in stationData) {
                  final dx = tapPos.dx - station.cx;
                  final dy = tapPos.dy - station.cy;
                  final dist = sqrt(dx * dx + dy * dy);
                  if (dist < minDist) {
                    minDist = dist;
                    nearestStation = station;
                  }
                }

                // threshold: 120px 이내면 해당 역 선택
                if (nearestStation != null && minDist <= 150) {
                  setState(() {
                    selectedStation = nearestStation;
                    selectedStationId = nearestStation!.id;
                    _lastStationForButton = nearestStation;
                    showButtons = true;
                  });
                } else {
                  // 너무 멀면 선택 해제
                  setState(() {
                    showButtons = false;
                    selectedStation = null;
                    selectedStationId = null;
                  });
                }
              },
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.3,
                  maxScale: 2.0,
                  boundaryMargin: const EdgeInsets.all(500),
                  constrained: false,
                  child: SizedBox(
                    width: 4500,
                    height: 3800,
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/images/metropolitan.png',
                          width: 4500,
                          height: 3800,
                          fit: BoxFit.cover,
                        ),
                        StationComponent(
                          stations: stationData,
                          selectedId: selectedStationId,
                          onStationTap: (id) {
                            if (id == null) {
                              setState(() {
                                showButtons = false;
                                selectedStation = null;
                                selectedStationId = null;
                              });
                            } else {
                              final found = stationData.firstWhere((s) => s.id == id);
                              setState(() {
                                selectedStation = found;
                                selectedStationId = found.id;
                                _lastStationForButton = found;
                                showButtons = true;
                              });
                            }
                          },
                          transformationController: _transformationController,
                        ),
                      if (buttonStation != null && buttonStation.id.isNotEmpty)
                    Positioned(
                    left: (buttonStation.cx) - 60,
                top: (buttonStation.cy) - 90,
                child: AnimatedSlide(
                  offset: (showButtons)
                      ? Offset.zero
                      : const Offset(0, 0.2),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  child: AnimatedOpacity(
                    opacity: showButtons ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    onEnd: () {
                      if (!showButtons) {
                        setState(() {
                          selectedStation = null;
                          selectedStationId = null;
                        });
                      }
                    },
                    child: IgnorePointer(
                      ignoring: !showButtons,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        _CircleIconButton(
                        icon: Icons.arrow_upward,
                        label: '출발',
                        onTap: _onSelectDeparture,
                      ),
                      const SizedBox(width: 8),
                      // 도착지 버튼
                      _CircleIconButton(
                        icon: Icons.arrow_downward,
                        label: '도착',
                        onTap: _onSelectArrival,
                      ),
                      const SizedBox(width: 8),
                          ],
                    ),
                    ),
                  ),
                ),
              ),
                      ],
      ),

                    ),
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }


  Widget buildBottomNavBar() {
    return Container(
      height: 60,
      color: Colors.white,
      child: Row(
        children: [
          buildNavItem(Icons.home, "HOME"),
          buildNavItem(Icons.directions_transit, "실시간"),
          buildNavItem(Icons.favorite_border, "저장"),
          buildNavItem(Icons.article, "소식"),
          buildNavItem(Icons.person, "마이페이지"),
        ],
      ),
    );
  }

  Widget buildNavItem(IconData icon, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],

      ),
    );
  }
}