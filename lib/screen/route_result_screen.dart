import 'package:flutter/material.dart';
import 'package:rushcutter/screen/real_time_bottom_sheet.dart';
import 'package:rushcutter/providers/saved_route_provider.dart';
import 'package:provider/provider.dart';
import 'package:rushcutter/models/saved_route.dart';
import 'package:rushcutter/services/path_service.dart';
import 'package:rushcutter/services/api_station_service.dart';



class RouteResultScreen extends StatefulWidget {
  final String departure;
  final String arrival;

  const RouteResultScreen({
    super.key,
    required this.departure,
    required this.arrival,
  });

  @override
  State<RouteResultScreen> createState() => _RouteResultScreenState();
}
class _RouteResultScreenState extends State<RouteResultScreen> {
  late TimeOfDay departureTime;
  late TimeOfDay arrivalTime;
  String? globalStartName;
  String? globalEndName;
  int? globalTravelTime;
  List<dynamic> routes = [];
  List<dynamic> exchanges = [];
  List<dynamic> stations = [];
  List<dynamic> shortestRoutes = [];
  List<dynamic> minTransferRoutes = [];
  List<dynamic> minTransferStations = [];
  List<dynamic> minTransferExchanges = [];
  String? minTransferStartName;
  String? minTransferEndName;
  int? minTransferTravelTime;

  int getTravelTimeTo(String untilStationName) {
    final target = stations.firstWhere(
          (s) => s['endName'] == untilStationName,
      orElse: () => null,
    );
    return target != null ? target['travelTime'] : 0;
  }

  String formatWithoutAmPm(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay getCumulativeTime(TimeOfDay departure, int totalMinutes) {
    final base = DateTime(0, 1, 1, departure.hour, departure.minute);
    final adjusted = base.add(Duration(minutes: totalMinutes));
    return TimeOfDay.fromDateTime(adjusted);
  }

  bool isFavorite = false;
  Future<void> fetchRouteData() async {


    final stationService = ApiStationService();
    final startFrCode = await stationService.getFrCodeByStationName(widget.departure);
    final endFrCode = await stationService.getFrCodeByStationName(widget.arrival);
    final pathService = PathService();

    if (startFrCode == null || endFrCode == null) {
      print("❌ 출발역 또는 도착역의 fr_code를 찾을 수 없습니다.");
      return;
    }

    final shortest = await pathService.getShortestPath(startFrCode, endFrCode);
    final minTransfer = await pathService.getMinTransferPath(startFrCode, endFrCode); // ✅ 여기에 실제 데이터가 들어옴
    print('🔍 최소환승 API 응답: $minTransfer');
    if (shortest != null && shortest['result'] != null) {
      final totalMinutes = shortest['result']['globalTravelTime'];
      final now = DateTime.now();

      setState(() {
        departureTime = TimeOfDay.fromDateTime(now);
        globalStartName = shortest['result']['globalStartName'];
        globalEndName = shortest['result']['globalEndName'];
        globalTravelTime = shortest['result']['globalTravelTime'];
        routes = shortest['result']['route'];
        shortestRoutes = shortest['result']['route'];
        exchanges = shortest['result']['exchanges'];
        stations = shortest['result']['stations'];
        arrivalTime = TimeOfDay.fromDateTime(now.add(Duration(minutes: totalMinutes)));
      });
    }

    if (minTransfer != null && minTransfer['result'] != null) {
      setState(() {
        minTransferRoutes = minTransfer['result']['route'];
        minTransferStations = minTransfer['result']['stations'];
        minTransferExchanges = minTransfer['result']['exchanges'];
        minTransferStartName = minTransfer['result']['globalStartName'];
        minTransferEndName = minTransfer['result']['globalEndName'];
        minTransferTravelTime = minTransfer['result']['globalTravelTime'];
      });
    }
  }

  String get durationText {
    final travel = globalTravelTime ?? 0;
    int walk = 0;
    for (final transfer in exchanges) {
      final walkTime = ((transfer['exWalkTime'] ?? 0) as num) / 60;
      walk += walkTime.ceil();
    }
    final total = travel + walk;
    final hours = total ~/ 60;
    final minutes = total % 60;
    return '${hours > 0 ? '$hours시간 ' : ''}$minutes분';
  }


  @override
  void initState() {
    super.initState();
    departureTime = TimeOfDay.now();
    arrivalTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 1)));
    fetchRouteData(); // 🚀 실제 API 연동 함수 실행
  }


  String _formatTime24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _calculateTotalMinutes(List<dynamic> routeList, List<dynamic> stationList, List<dynamic> exchangeList, String endName) {
    int total = 0;
    for (final route in routeList) {
      final index = routeList.indexOf(route);
      int section = 0;

      if (index == 0) {
        final nextStation = routeList.length > 1 ? routeList[1]['startName'] : endName;
        final s = stationList.firstWhere((s) => s['endName'] == nextStation, orElse: () => null);
        if (s != null) section = s['travelTime'];
      } else {
        final prev = stationList.firstWhere((s) => s['endName'] == routeList[index]['startName'], orElse: () => null);
        final curr = (index + 1 < routeList.length)
            ? stationList.firstWhere((s) => s['endName'] == routeList[index + 1]['startName'], orElse: () => null)
            : stationList.firstWhere((s) => s['endName'] == endName, orElse: () => null);
        if (prev != null && curr != null) {
          section = curr['travelTime'] - prev['travelTime'];
        }
      }

      total += section;

      final transfer = exchangeList.cast<Map<String, dynamic>?>().firstWhere(
            (ex) => ex?['startName'] == route['startName'],
        orElse: () => null,
      );

      if (transfer != null) {
        final walk = (((transfer['exWalkTime'] ?? 0) as num) / 60).ceil();
        total += walk;
      }
    }

    return total;
  }



  @override
  Widget build(BuildContext context) {
    final route = SavedRoute(
      from: widget.departure,
      to: widget.arrival,
      details: '인천1호선, 1호선 (환승 1회)',
    );
    final provider = Provider.of<SavedRouteProvider>(context);
    final isSaved = provider.isSaved(route);
    return DefaultTabController(
        length: 2,
        child:Scaffold(
        backgroundColor: Colors.white, // ✅ 페이지 전체 배경 흰색 적용
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              '길찾기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: const TabBar(
              labelColor: Colors.black,
              indicatorColor: Color(0xFF4262C5),
              tabs: [
                Tab(text: '최단거리'),
                Tab(text: '최소환승'),
              ],
            ),
          ),



          floatingActionButton: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.only(bottom: 16, right: 8),
          child: FloatingActionButton(
            onPressed: () {
              final now = TimeOfDay.now();
              setState(() {
                departureTime = now;
                // arrivalTime 제거!
              });
            },
            backgroundColor: const Color(0xFF4262C5),
            shape: const CircleBorder(),
            child: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),


        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

          body: TabBarView(
            children: [
              _buildRouteTab(
                routeList: shortestRoutes,
                stationList: stations,
                exchangeList: exchanges,
                startName: globalStartName ?? '',
                endName: globalEndName ?? '',
                travelTime: globalTravelTime ?? 0,
                isSaved: isSaved,
                provider: provider,
                route: route,
              ),
              _buildRouteTab(
                routeList: minTransferRoutes,
                stationList: minTransferStations,
                exchangeList: minTransferExchanges,
                startName: minTransferStartName ?? '',
                endName: minTransferEndName ?? '',
                travelTime: minTransferTravelTime ?? 0,
                isSaved: isSaved,
                provider: provider,
                route: route,
              ),
            ],
          ),


        )
    );
  }

  String getDurationText(List<dynamic> exchanges, int baseTravelTime) {
    int walk = 0;
    for (final transfer in exchanges) {
      final walkTime = ((transfer['exWalkTime'] ?? 0) as num) / 60;
      walk += walkTime.ceil();
    }
    final total = baseTravelTime + walk;
    final hours = total ~/ 60;
    final minutes = total % 60;
    return '${hours > 0 ? '$hours시간 ' : ''}$minutes분';
  }


  Widget _buildRouteTab({
    required List<dynamic> routeList,
    required List<dynamic> stationList,
    required List<dynamic> exchangeList,
    required String startName,
    required String endName,
    required int travelTime,
    required bool isSaved,
    required SavedRouteProvider provider,
    required SavedRoute route,
  }) {

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 상단 간격 줄이기
          const SizedBox(height: 4),
          if (startName.isNotEmpty && endName.isNotEmpty)
            Text(
              '$startName → $endName',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),

          // ✅ 시간 + 환승 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    travelTime == 0
                        ? '계산 중...'
                        : getDurationText(exchangeList, travelTime),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 6),
                    child: exchangeList.isNotEmpty
                        ? Text('환승 ${exchangeList.length}회',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),

                ],
              ),
              IconButton(
                iconSize: 32,
                icon: Icon(
                  isSaved ? Icons.star : Icons.star_border,
                  color: isSaved ? Colors.amber : Colors.grey,
                ),
                onPressed: () {
                  provider.toggle(route);
                },
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ✅ 출발/도착 시간 박스
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FF),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _selectTime(context, true),
                  child: Text(
                    '출발 ${departureTime.format(context)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  child: Text(
                    '도착 ${getCumulativeTime(departureTime, _calculateTotalMinutes(routeList, stationList, exchangeList, endName)).format(context)}',

                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Expanded(
            child: Builder(builder: (context) {
              int accumulatedMinutes = 0;

              return ListView.builder(
                itemCount: routeList.length + 1,
                itemBuilder: (context, index) {
                  List<int> sectionDurations = [];
                  if (index < routeList.length) {
                    final route = routeList[index];
                    final station = route['startName'];
                    final line = route['laneName'];
                    final stationCount = '${route['stationCount']}개 역 이동';
                    final destination = '${route['wayName']}행';
                    int sectionTotalTime = 0;
                    if (index == 0) {
                      if (routeList.length > 1) {
                        final firstTransferStation = stationList.firstWhere(
                              (s) => s['endName'] == routeList[1]['startName'],
                          orElse: () => null,
                        );
                        if (firstTransferStation != null) {
                          sectionTotalTime = firstTransferStation['travelTime'];
                        }
                      } else {
                        final s = stationList.firstWhere(
                              (s) => s['endName'] == endName,
                          orElse: () => null,
                        );
                        if (s != null) {
                          sectionTotalTime = s['travelTime'];
                        }
                      }
                    } else {
                      final prev = stationList.firstWhere(
                            (s) => s['endName'] == routeList[index]['startName'],
                        orElse: () => null,
                      );
                      final curr = (index + 1 < routeList.length)
                          ? stationList.firstWhere(
                            (s) => s['endName'] == routeList[index + 1]['startName'],
                        orElse: () => null,
                      )
                          : stationList.firstWhere(
                            (s) => s['endName'] == endName,
                        orElse: () => null,
                      );
                      if (prev != null && curr != null) {
                        sectionTotalTime = curr['travelTime'] - prev['travelTime'];
                      }
                    }
                    sectionDurations.add(sectionTotalTime);
                    final stepTime = getCumulativeTime(departureTime, accumulatedMinutes);
                    accumulatedMinutes += sectionTotalTime;

                    final transfer = exchangeList.cast<Map<String, dynamic>?>().firstWhere(
                          (ex) => ex?['startName'] == station,
                      orElse: () => null,
                    );

                    final fastTransfer = transfer != null
                        ? '빠른 환승 ${transfer['fastTrainCar']}'
                        : '일반 승차';
                    final arrivalTimeFormatted =
                    formatWithoutAmPm(getCumulativeTime(departureTime, accumulatedMinutes));
                    List<Widget> steps = [];

                    steps.add(_buildRouteStep(
                      time: formatWithoutAmPm(stepTime),
                      station: '$station 승차',
                      line: line,
                      color: getLineColor(line),
                      duration: '$sectionTotalTime분',
                      stationCount: stationCount,
                      destination: route['wayName'],
                      fastTransfer: fastTransfer,
                      icon: Icons.directions_subway,
                      context: context,
                      endName: (index == routeList.length - 1)
                          ? endName
                          : route['endName']?.toString() ?? transfer?['exName']?.toString() ?? '',
                      arrivalTime: arrivalTimeFormatted,
                      departureTime: stepTime,
                      sectionDurations: sectionDurations,
                      exchangeList: exchangeList,
                    ));
                    if (route['endName'] == null) {
                      print('⚠️ 경고: route["endName"]가 null입니다. route: $route');
                    }
                    if (transfer != null) {
                      final walkMinutes = (((transfer['exWalkTime'] ?? 0) as num) / 60).ceil();
                      final walkTime = getCumulativeTime(departureTime, accumulatedMinutes);

                      steps.add(_buildTransferStep(
                        time: formatWithoutAmPm(walkTime),
                        station: transfer['exName'] ?? '',
                        distance: '$walkMinutes분',
                      ));

                      accumulatedMinutes += walkMinutes;
                    }

                    return Column(children: steps);
                  } else {
                    if (endName.isEmpty) return const SizedBox.shrink();
                    final finalArrival = getCumulativeTime(departureTime, accumulatedMinutes);
                    return Column(
                      children: [
                        _buildArrivalStep(
                          time: formatWithoutAmPm(finalArrival),
                          station: '$endName 하차',
                        ),
                        const SizedBox(height: 100),
                      ],
                    );
                  }

                },
              );
            }),
          ),

        ],
      ),
    );
  }


  Widget _buildCongestionButton(BuildContext context, {
    required String line,
    required String station,
    required String destination,
    required String fastTransfer,
    required String time,
    required String duration,
    required String stationCount,
    required IconData icon,
    required Color color,
    required String endName,
    required String arrivalTime,
    required TimeOfDay departureTime,
    required List<int> sectionDurations,
    required List<dynamic> exchangeList,
  }) {
    return GestureDetector(
      onTap: () {
        if (line == '인천1호선') {
          // ✅ 인천1호선은 팝업 띄우기
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.error_outline, size: 40, color: Colors.black),
                  SizedBox(height: 16),
                  Text(
                    '혼잡도를 지원하지 않는 경로입니다.\n지하철 2~9호선의 혼잡도만 제공됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(bottom: 12),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                // ✅ 실시간 버튼 → 모달 띄움
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 먼저 다이얼로그 닫고
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => RealTimeBottomSheet(
                        color: color,
                        line: line,
                        station: station,
                        fastTransfer: fastTransfer,
                        icon: icon,
                        duration: duration,
                        arrivalStation: endName,
                        arrivalTime: arrivalTime,
                        sectionDurations: sectionDurations.toList(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4262C5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text('실시간', style: TextStyle(color: Colors.white)),
                ),

                // ✅ 확인 버튼 → 그냥 닫기
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text('확인', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        } else {
          // ✅ 2~9호선은 바로 혼잡도 예측 화면으로 이동
          Navigator.pushNamed(
            context,
            '/congestion',
            arguments: {
              'line': line,
              'station': station,
              'destination': destination,
              'fastTransfer': fastTransfer,
              'time': time,
              'duration': duration,
              'stationCount': stationCount,
              'iconCodePoint': icon.codePoint,
              'colorValue': color.value,
              'departureTime': departureTime.format(context),
              'arrivalTime': arrivalTime,
              'isFavorite': isFavorite,
              'actualArrival': endName,
              'sectionDurations': sectionDurations,
              'transferCount': exchangeList.length,

            },
          );

        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          '혼잡도 예측',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


  Future<void> _selectTime(BuildContext context, bool isDeparture) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDeparture ? departureTime : departureTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Colors.blue[800],
              dialHandColor: Colors.blue,
              dialBackgroundColor: Colors.blue[50],
              entryModeIconColor: Colors.blue[700],
              dayPeriodColor: Colors.blue[100],
              dayPeriodTextColor: Colors.blue[900],
              hourMinuteColor: Colors.blue[100],
            ),
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDeparture) {
          departureTime = picked;
        } else {
          arrivalTime = picked;
        }
      });
    }
  }





  Widget _buildRouteStep({
    required String time,
    required String station,
    required String line,
    required Color color,
    required String duration,
    required String stationCount,
    required String destination,
    required String fastTransfer,
    required IconData icon,
    required BuildContext context,
    required String endName,
    required String arrivalTime,
    required TimeOfDay departureTime,
    required List<int> sectionDurations,
    required List<dynamic> exchangeList,
  }) {

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 60, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _buildCircularIcon(icon, color),
                  Container(
                    width: 6,
                    height: 130,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5.5),
                    Text(
                      line,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      station,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(destination, style: const TextStyle(fontSize: 14)),
                    Text(fastTransfer, style: const TextStyle(fontSize: 14)),
                    Text(
                      '$duration ($stationCount)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ✅ 시간 → 아이콘 왼쪽 정중앙에 배치
        Positioned(
          left: 10,
          top: 6.5,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // ✅ 소요 시간 → 아이콘과 아이콘 사이의 정중앙 왼쪽에 배치
        // ✅ 전달받은 duration을 사용하도록 수정
        Positioned(
          left: 10,
          top: 85,
          child: SizedBox(
            width: 50, // 고정 너비, 필요에 따라 조절 (숫자 2자리도 여유있게)
            child: Text(
              duration,
              textAlign: TextAlign.right, // 👉 오른쪽 정렬
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),



        // ✅ 혼잡도 예측 버튼
        Positioned(
          right: 16,
          bottom: 0,
          child: _buildCongestionButton(
            context,
            line: line,
            station: station,
            destination: destination,
            fastTransfer: fastTransfer,
            time: time,
            duration: duration,
            stationCount: stationCount,
            icon: icon,
            color: color,
            endName: endName,
            arrivalTime: arrivalTime,
            departureTime: departureTime,
            sectionDurations: sectionDurations.toList(),
            exchangeList: exchangeList,
          ),
        ),
      ],
    );
  }


// ✅ 환승 정보 위젯 (시간 + 소요 시간 정확히 위치)
  Widget _buildTransferStep({
    required String time,
    required String station,
    required String distance,
  }) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 60, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _buildCircularIcon(Icons.directions_walk, Colors.grey),
                  Container(
                    width: 6,
                    height: 40, // ✅ 아이콘 사이 거리 설정
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6), // 👈 전체를 아래로 내림
                    Text('$station 하차',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('',
                        style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),

            ],
          ),
        ),

        // ✅ 시간 → 아이콘의 정중앙 왼쪽에 배치
        Positioned(
          left: 10,
          top: 6.5,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // 도보시간
        Positioned(
          left: 40,
          top: 45,
          child: Text(
            distance, //
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

// ✅ 도착 정보 위젯 (시간만 왼쪽에 고정)
  Widget _buildArrivalStep({
    required String time,
    required String station,
  }) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 60, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCircularIcon(Icons.location_on, Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5.5),
                    Text(
                      station,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ✅ 시간 → 아이콘의 정중앙 왼쪽에 배치
        Positioned(
          left: 10,
          top: 6.5,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

// ✅ 원형 아이콘 생성 함수
  Widget _buildCircularIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

Color getLineColor(String line) {
  switch (line) {
    case '1호선': return Color(0xFF0052A4);
    case '2호선': return Color(0xFF00A84D);
    case '3호선': return Color(0xFFEF7C1C);
    case '4호선': return Color(0xFF00A4E3);
    case '5호선': return Color(0xFF996CAC);
    case '6호선': return Color(0xFFCD7C2F);
    case '7호선': return Color(0xFF747F00);
    case '8호선': return Color(0xFFE6186C);
    case '9호선': return Color(0xFFBDB092);
    case '인천1호선': return Color(0xFF79A0D4);
    case '인천2호선': return Color(0xFFF5A251);
    case '수인.분당선': return Color(0xFFFABD00);
    case '신분당선': return Color(0xFFD31145);
    case '경의중앙선': return Color(0xFF77C4A3);
    case '서해선': return Color(0xFF8FC31F14);
    default: return Colors.grey;
  }
}
