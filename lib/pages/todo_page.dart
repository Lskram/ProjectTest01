import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../controllers/notification_controller.dart';
import '../controllers/app_controller.dart';
import '../models/notification_session.dart';
import '../models/pain_point.dart';
import '../models/treatment.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> with TickerProviderStateMixin {
  String? sessionId;
  NotificationSession? session;
  PainPoint? painPoint;
  List<Treatment> treatments = [];
  List<bool> treatmentCompleted = [];
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    sessionId = Get.arguments as String?;
    _loadSessionData();

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _loadSessionData() {
    if (sessionId == null) {
      // Create a mock session for testing
      _createMockSession();
      return;
    }

    // Load real session data
    final notificationController = NotificationController.instance;
    final sessionData = notificationController.getSessionData(
        // This would get session from database
        NotificationSession(
      id: sessionId!,
      scheduledTime: DateTime.now(),
      painPointId: 1,
      treatmentIds: [1, 2],
    ));

    if (sessionData != null) {
      setState(() {
        painPoint = sessionData['painPoint'];
        treatments = sessionData['treatments'];
        treatmentCompleted = List.filled(treatments.length, false);
      });
    }
  }

  void _createMockSession() {
    final appController = AppController.instance;
    final selectedPainPoints = appController.selectedPainPoints;

    if (selectedPainPoints.isNotEmpty) {
      final randomPainPoint = selectedPainPoints.first;
      final painPointTreatments =
          appController.getTreatmentsForPainPoint(randomPainPoint.id);

      setState(() {
        painPoint = randomPainPoint;
        treatments = painPointTreatments.take(2).toList();
        treatmentCompleted = List.filled(treatments.length, false);
      });
    }
  }

  void _toggleTreatmentCompleted(int index) {
    setState(() {
      treatmentCompleted[index] = !treatmentCompleted[index];
    });

    final progress = treatmentCompleted.where((completed) => completed).length /
        treatmentCompleted.length;
    _progressAnimationController.animateTo(progress);
  }

  Future<void> _completeSession() async {
    if (!treatmentCompleted.every((completed) => completed)) {
      Get.snackbar(
        'ยังไม่เสร็จ',
        'กรุณาทำท่าออกกำลังกายให้ครบทุกท่า',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    // Show completion animation
    await _showCompletionDialog();

    // Navigate back to home
    Get.back();
  }

  Future<void> _showCompletionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              size: 80,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 20),
            const Text(
              'เยี่ยมมาก!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'คุณทำออกกำลังกายครบแล้ว\nร่างกายจะรู้สึกดีขึ้น',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('เสร็จแล้ว'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (painPoint == null || treatments.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('ออกกำลังกาย')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final allCompleted = treatmentCompleted.every((completed) => completed);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('ดูแล: ${painPoint!.name}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Header
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
                Text(
                  'ความคืบหน้า',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${treatmentCompleted.where((c) => c).length} / ${treatments.length} ท่า',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearPercentIndicator(
                      width: MediaQuery.of(context).size.width - 48,
                      lineHeight: 8,
                      percent: _progressAnimation.value,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      progressColor: Colors.white,
                      barRadius: const Radius.circular(4),
                      animation: false,
                    );
                  },
                ),
              ],
            ),
          ),

          // Treatments List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: treatments.length,
              itemBuilder: (context, index) {
                final treatment = treatments[index];
                final isCompleted = treatmentCompleted[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    elevation: isCompleted ? 8 : 4,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color:
                            isCompleted ? Colors.green.shade50 : Colors.white,
                        border: Border.all(
                          color: isCompleted
                              ? Colors.green.shade300
                              : Colors.grey.shade200,
                          width: isCompleted ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'ท่าที่ ${index + 1}/${treatments.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  treatment.durationText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Text(
                            treatment.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            treatment.instructions,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Complete Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _toggleTreatmentCompleted(index),
                              icon: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 20,
                              ),
                              label: Text(
                                isCompleted ? 'ทำเสร็จแล้ว' : 'ทำเสร็จ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCompleted
                                    ? Colors.green.shade600
                                    : Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Complete All Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: allCompleted ? _completeSession : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allCompleted
                          ? Colors.green.shade600
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: allCompleted ? 4 : 0,
                    ),
                    child: Text(
                      allCompleted ? 'เสร็จสิ้น 🎉' : 'ทำให้ครบทุกท่าก่อน',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Snooze functionality
                          _showSnoozeDialog();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('เลื่อน'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Skip functionality
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('ข้าม'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnoozeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลื่อนการแจ้งเตือน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('เลื่อนไปกี่นาที?'),
            const SizedBox(height: 16),
            ...[5, 15, 30].map((minutes) => ListTile(
                  title: Text('$minutes นาที'),
                  onTap: () {
                    Navigator.pop(context);
                    Get.back();
                    Get.snackbar(
                        'เลื่อนแล้ว', 'จะแจ้งเตือนอีกครั้งใน $minutes นาที');
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }
}
