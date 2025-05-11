import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/saved_route.dart';
import '../../providers/saved_route_provider.dart';
import 'package:rushcutter/screen/route_result_screen.dart';


class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});


  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> with TickerProviderStateMixin {
  bool isEditExpanded = false;
  bool isSearching = false;
  String searchQuery = '';
  late List<SavedRoute> localRoutes;
  Widget _buildRouteTile(SavedRoute route, int index) {
    return Container(
      key: ValueKey(route),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(
            Icons.menu,         // ← 선 3줄 아이콘
            color: Colors.black87,
            size: 23,
          ),
        ),

        title: Text(
          '${route.from} → ${route.to}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(route.details),
        ),
        trailing: GestureDetector(
          onTap: () {
            context.read<SavedRouteProvider>().removeRoute(route);
            setState(() {
              localRoutes.remove(route);
            });
          },
          child: const Icon(Icons.star, color: Colors.amber),
        ),

        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => RouteResultScreen(
                departure: route.from,
                arrival: route.to,
              ),
            ),
          );
          if (result == false) {
            context.read<SavedRouteProvider>().removeRoute(route);
            setState(() {
              localRoutes.remove(route);
            });
          }
        },
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    final savedRoutes = context.read<SavedRouteProvider>().savedRoutes;
    localRoutes = List.from(savedRoutes); // 복사본 생성
  }
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = localRoutes.removeAt(oldIndex);
      localRoutes.insert(newIndex, item);
    });

    context.read<SavedRouteProvider>().updateRoutes(localRoutes);
  }


  @override
  Widget build(BuildContext context) {
    final savedRoutes = context.watch<SavedRouteProvider>().savedRoutes;

    final filteredRoutes = isSearching
        ? savedRoutes.where((route) {
      final query = searchQuery.toLowerCase();
      return route.from.toLowerCase().contains(query) ||
          route.to.toLowerCase().contains(query) ||
          route.details.toLowerCase().contains(query);
    }).toList()
        : savedRoutes;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12), // 위 여백 확보
              color: Colors.white,
              child: isSearching
                  ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: '경로 검색',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        isSearching = false;
                        searchQuery = '';
                      });
                    },
                  ),
                ],
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '자주 찾는 경로',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        isSearching = true;
                      });
                    },
                  ),
                ],
              ),
            ),

            // 🔷 본문 리스트
            Expanded(
              child: isSearching
                  ? (filteredRoutes.isEmpty
                  ? const Center(
                child: Text(
                  '검색 결과가 없습니다.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: filteredRoutes.length,
                itemBuilder: (context, index) =>
                    _buildRouteTile(filteredRoutes[index], index),
              ))
                  : (localRoutes.isEmpty
                  ? const Center(
                child: Text(
                  '⭐ 지정된 경로가 없습니다.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              )
                  : ReorderableListView(
                onReorder: _onReorder,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.only(top: 8),
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    elevation: 0,
                    child: child,
                  );
                },
                children: [
                  for (int i = 0; i < localRoutes.length; i++)
                    _buildRouteTile(localRoutes[i], i),
                ],
              )),
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildConnectedActionButton(String label, IconData icon) {
    return TextButton(
      onPressed: () {
        print('$label 눌림');
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}