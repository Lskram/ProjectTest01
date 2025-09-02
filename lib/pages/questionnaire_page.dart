import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final Set<int> _selectedPainPoints = <int>{};
  bool _isLoading = false;

  void _togglePainPoint(int painPointId) {
    setState(() {
      if (_selectedPainPoints.contains(painPointId)) {
        _selectedPainPoints.remove(painPointId);
      } else if (_selectedPainPoints.length < 3) {
        _selectedPainPoints.add(painPointId);
      } else {
        Get.snackbar(
          'เกินจำนวน',
          'เลือกได้สูงสุด 3 จุด',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      }
    });
  }

  Future<void> _completeSetup() async {
    if (_selectedPainPoints.isEmpty) {
      Get.snackbar(
        'กรุณาเลือก',
        'เลือกอย่างน้อย 1 จุดที่ปวดบ่อย',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AppController.instance
          .completeFirstTimeSetup(_selectedPainPoints.toList());
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar('ข้อผิดพลาด', 'เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('ตั้งค่าครั้งแรก'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        final appController = AppController.instance;
        final painPoints = appController.painPoints;

        return Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.quiz,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'คุณปวดตรงไหนบ่อย?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'เลือกได้สูงสุด 3 จุด (${_selectedPainPoints.length}/3)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Pain Points List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: painPoints.length,
                itemBuilder: (context, index) {
                  final painPoint = painPoints[index];
                  final isSelected = _selectedPainPoints.contains(painPoint.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      elevation: isSelected ? 8 : 2,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _togglePainPoint(painPoint.id),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color:
                                isSelected ? Colors.blue.shade50 : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade300
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue.shade600
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getPainPointIcon(painPoint.iconName),
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  size: 24,
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      painPoint.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.blue.shade800
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      painPoint.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Checkbox
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.blue.shade600
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 16)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'เริ่มใช้งาน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  IconData _getPainPointIcon(String iconName) {
    switch (iconName) {
      case 'head':
        return Icons.face;
      case 'eye':
        return Icons.visibility;
      case 'neck':
        return Icons.face_retouching_natural;
      case 'shoulder':
        return Icons.accessibility_new;
      case 'back_upper':
        return Icons.airline_seat_recline_normal;
      case 'back_lower':
        return Icons.airline_seat_legroom_reduced;
      case 'arm':
        return Icons.pan_tool;
      case 'wrist':
        return Icons.touch_app;
      case 'leg':
        return Icons.directions_walk;
      case 'foot':
        return Icons.directions_run;
      default:
        return Icons.healing;
    }
  }
}
