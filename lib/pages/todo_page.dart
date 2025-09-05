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
  bool isLoading = true;

  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();
    sessionId = Get.arguments as String?;
    _initializeAnimations();
    _loadSessionData();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
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

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _loadSessionData() async {
    try {
      setState(() => isLoading = true);

      if (sessionId == null) {
        await _createMockSession();
        return;
      }

      // Load real session data
      final notificationController = Get.find<NotificationController>();
      final sessionData =
          await notificationController.getSessionData(sessionId!);

      if (sessionData != null) {
        setState(() {
          session = sessionData['session'];
          painPoint = sessionData['painPoint'];
          treatments = List<Treatment>.from(sessionData['treatments']);
          treatmentCompleted = List.filled(treatments.length, false);
        });
      } else {
        await _createMockSession();
      }

      _updateProgress();
    } catch (e) {
      debugPrint('❌ Error loading session data: $e');
      await _createMockSession();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createMockSession() async {
    try {
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

        // Create mock session
        session = NotificationSession(
          id: sessionId ?? 'mock_${DateTime.now().millisecondsSinceEpoch}',
          scheduledTime: DateTime.now(),
          painPointId: randomPainPoint.id,
          treatmentIds: treatments.map((t) => t.id).toList(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error creating mock session: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadSessionData();
    Get.snackbar('รีเฟรช', 'ข้อมูลถูกอัปเดตแล้ว');
  }

  void _toggleTreatmentCompleted(int index) {
    setState(() {
      treatmentCompleted[index] = !treatmentCompleted[index];
    });

    final progress = treatmentCompleted.where((completed) => completed).length /
        treatmentCompleted.length;
    _progressAnimationController.animateTo(progress);

    // Check if all completed
    if (treatmentCompleted.every((completed) => completed)) {
      _onAllTreatmentsCompleted();
    }
  }

  void _onAllTreatmentsCompleted() {
    _celebrationController.forward();
    Get.snackbar(
      'ยินดีด้วย! 🎉',
      'คุณทำกิจกรรมครบทุกท่าแล้ว',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _updateProgress() {
    final progress = treatmentCompleted.where((completed) => completed).length /
        (treatmentCompleted.isEmpty ? 1 : treatmentCompleted.length);
    _progressAnimationController.animateTo(progress);
  }

  void _markSessionCompleted() async {
    try {
      if (session == null) return;

      // Update session status
      final updatedSession = session!.copyWith(
        status: SessionStatusHive.completed,
        completedTime: DateTime.now(),
        treatmentCompleted: treatmentCompleted,
      );

      // Save to database (would typically call a service)
      // await DatabaseService.instance.saveNotificationSession(updatedSession);

      Get.snackbar(
        'สำเร็จ! 🎊',
        'บันทึกผลการออกกำลังกายแล้ว',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate back with delay
      await Future.delayed(const Duration(seconds: 2));
      Get.back();
    } catch (e) {
      debugPrint('❌ Error marking session completed: $e');
      Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถบันทึกได้');
    }
  }

  void _skipSession() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('ข้ามกิจกรรม'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการข้ามกิจกรรมนี้?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ข้าม', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('กิจกรรมออกกำลังกาย'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: isLoading ? _buildLoadingWidget() : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('กำลังโหลดกิจกรรม...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (painPoint == null || treatments.isEmpty) {
      return _buildErrorWidget();
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeaderCard(),
              const SizedBox(height: 24),
              _buildProgressCard(),
              const SizedBox(height: 24),
              _buildTreatmentsSection(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'ไม่พบข้อมูลกิจกรรม',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'เวลาออกกำลังกาย!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      painPoint!.nameTh,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${treatments.length} ท่า • ${_getTotalDuration()} นาที',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final completed = treatmentCompleted.where((c) => c).length;
    final total = treatmentCompleted.length;
    final progress = total > 0 ? completed / total : 0.0;

    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_celebrationAnimation.value * 0.05),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ความคืบหน้า',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$completed/$total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: progress == 1.0
                          ? Colors.green
                          : Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      progress == 1.0
                          ? 'เสร็จสิ้น! 🎉'
                          : '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  builder: (context, child) {
                    return Column(
                      children: [
                        LinearPercentIndicator(
                          padding: EdgeInsets.zero,
                          lineHeight: 8,
                          percent: _progressAnimation.value,
                          backgroundColor: Colors.grey.shade200,
                          progressColor: progress == 1.0
                              ? Colors.green
                              : Colors.orange.shade600,
                          barRadius: const Radius.circular(4),
                          animation: true,
                          animationDuration: 500,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [child!],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTreatmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ท่าออกกำลังกาย',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...treatments.asMap().entries.map((entry) {
          final index = entry.key;
          final treatment = entry.value;
          return _buildTreatmentCard(treatment, index);
        }),
      ],
    );
  }

  Widget _buildTreatmentCard(Treatment treatment, int index) {
    final isCompleted = treatmentCompleted[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green : Colors.grey.shade300,
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Checkbox(
            value: isCompleted,
            onChanged: (_) => _toggleTreatmentCompleted(index),
            activeColor: Colors.green,
          ),
          title: Text(
            treatment.nameTh,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey : Colors.black,
            ),
          ),
          subtitle: Text(
            '${treatment.durationText} • ${treatment.difficultyText}',
            style: TextStyle(
              color: isCompleted ? Colors.grey : Colors.grey.shade600,
            ),
          ),
          trailing: Icon(
            isCompleted ? Icons.check_circle : Icons.expand_more,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (treatment.description.isNotEmpty) ...[
                    Text(
                      treatment.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'วิธีการ:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...treatment.instructions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 8, top: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (treatment.warnings != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.yellow.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.yellow.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              treatment.warnings!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.yellow.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (treatment.benefits != null &&
                      treatment.benefits!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.favorite,
                                  color: Colors.green.shade600, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'ประโยชน์:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...treatment.benefits!.map((benefit) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        size: 16, color: Colors.green.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        benefit,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final allCompleted = treatmentCompleted.every((completed) => completed);
    final hasProgress = treatmentCompleted.any((completed) => completed);

    return Column(
      children: [
        if (allCompleted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markSessionCompleted,
              icon: const Icon(Icons.celebration),
              label: const Text('เสร็จสิ้น!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else ...[
          Row(
            children: [
              if (hasProgress) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markSessionCompleted,
                    icon: const Icon(Icons.check),
                    label: const Text('บันทึกความคืบหน้า'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasProgress ? null : () => _showSkipConfirmation(),
                  icon: const Icon(Icons.skip_next),
                  label: const Text('ข้ามกิจกรรม'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        // Timer section (optional)
        _buildTimerSection(),

        const SizedBox(height: 16),

        // Quick tips
        _buildQuickTips(),
      ],
    );
  }

  Widget _buildTimerSection() {
    final totalDuration = _getTotalDuration();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: Colors.blue.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เวลาที่แนะนำ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'ประมาณ $totalDuration นาที',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _startTimer,
            child: const Text('ตั้งไทเมอร์'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'เคล็ดลับ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• ทำช้าๆ และสม่ำเสมอ\n• หายใจเข้า-ออกตามจังหวะ\n• หยุดทันทีหากรู้สึกเจ็บ\n• ทำในที่โล่งและปลอดภัย',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _showSkipConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('ข้ามกิจกรรม'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณแน่ใจหรือไม่ว่าต้องการข้ามกิจกรรมนี้?'),
            SizedBox(height: 12),
            Text(
              'การออกกำลังกายสม่ำเสมอจะช่วยลดอาการปวดเมื่อยได้ดีกว่า',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ทำต่อ'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _skipSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ข้าม'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    // Implement timer functionality
    Get.snackbar(
      'ไทเมอร์',
      'คุณสมบัตินี้กำลังพัฒนา',
      duration: const Duration(seconds: 2),
    );
  }

  int _getTotalDuration() {
    return treatments.fold(
        0, (sum, treatment) => sum + (treatment.duration ~/ 60));
  }
}
