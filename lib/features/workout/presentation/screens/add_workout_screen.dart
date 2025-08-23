import 'package:flutter/material.dart';
import '../../../workout/domain/models/exercise.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _muscleGroups = [
    '목', '승모근', '어깨', '가슴', '등', 
    '삼두', '이두', '전완', '복부', '허리', 
    '엉덩이', '하체', '종아리'
  ];
  
  final Map<String, int> _muscleCount = {
    '목': 2, '승모근': 18, '어깨': 87, '가슴': 82, 
    '등': 124, '삼두': 49, '이두': 53, '전완': 9, 
    '복부': 56, '허리': 7, '엉덩이': 23, '하체': 98, '종아리': 14
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search(스쿼트, 스 크 ...',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 최상단 탭 표시
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    SizedBox(width: 10),
                    Text('분류', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                    SizedBox(width: 20),
                    Text('전체', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 20),
                    Text('최근 30일', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 20),
                    Text('즐겨찾기', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 20),
                    Text('커스텀', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 20),
                    Text('유산소', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 10),
                  ],
                ),
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.purple, width: 2),
                ),
              ),
            ),
            
            // 메인 콘텐츠
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _muscleGroups.length,
                itemBuilder: (context, index) {
                  final muscle = _muscleGroups[index];
                  final count = _muscleCount[muscle] ?? 0;
                  
                  return InkWell(
                    onTap: () {
                      try {
                        // 운동 선택 시 이전 화면으로 결과 전달
                        Navigator.pop(context, Exercise(
                          name: muscle,
                          sets: 4,
                          reps: 12,
                          weight: 10.0,
                          intensity: 75,
                        ));
                      } catch (e) {
                        // 오류 방지
                        print('Error selecting exercise: $e');
                        Navigator.pop(context);
                      }
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                muscle.substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          muscle,
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          count.toString(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // 하단 이력
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHistoryItem('04 완료'),
                  _buildHistoryItem('05 완료'),
                  _buildHistoryItem('06 완료'),
                  _buildHistoryItem('07 완료'),
                ],
              ),
            ),
            
            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey),
                  const Text('슈퍼세트', style: TextStyle(color: Colors.purple)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('완료', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoryItem(String title) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.close, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
} 