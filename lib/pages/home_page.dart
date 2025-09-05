import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/app_controller.dart';
import '../widgets/live_countdown_widget.dart';
import '../models/notification_session.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeController homeController;

  @override
  void initState() {
    super.initState();
    // Initialize HomeController if not exists
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
    homeController = HomeController.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: homeController.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMainCountdown(),
                  const SizedBox(height: 24),
                  _buildCurrentSessionCard(),
                  const SizedBox(height: 24),
                  _buildTodayProgressCard(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildPermissionWarning(),
                  const SizedBox(height: 100), // Bottom padding for navigation
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.blue.shade600,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Office Syndrome Helper',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      actions: [
        Obx(() => IconButton(
              icon: Icon(
                homeController.isNotificationEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: Colors.white,
              ),
              onPressed: homeController.toggleNotifications,
            )),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => Get.toNamed('/settings'),
        ),
      ],
    );
  }

  Widget _buildMainCountdown() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'การแจ้งเตือนถัดไป',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          LiveCountdownWidget(
            size: 180,
            primaryColor: Colors.blue.shade600,
          ),
          const SizedBox(height: 16),
          Obx(() => Text(
                homeController.statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCurrentSessionCard() {
    return Obx(() {
      if (!homeController.hasActiveSession) {
        return const SizedBox.shrink();
      }

      return FutureBuilder<Map<String, dynamic>?>(
        future: homeController.getCurrentSessionDetails(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final painPoint = data['painPoint'];
          final treatments = data['treatments'];
          final session = data['session'];

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'มีกิจกรรมรอดำเนินการ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'จุดที่ปวด: ${painPoint?.nameTh ?? "ไม่ทราบ"}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ท่าออกกำลังกาย: ${treatments?.length ?? 0} ท่า',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (treatments != null && treatments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...treatments.take(2).map((treatment) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                treatment.nameTh,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: homeController.startExerciseSession,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('เริ่มออกกำลังกาย'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: homeController.skipCurrentSession,
                      child: const Text('ข้าม'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildTodayProgressCard() {
    return Obx(() {
      final stats = homeController.formattedTodayStats;

      return Container(
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
              children: [
                Icon(
                  Icons.today,
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'ความคืบหน้าวันนี้',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'ทั้งหมด',
                    stats['total']!,
                    'ครั้ง',
                    Colors.blue.shade600,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'สำเร็จ',
                    stats['completed']!,
                    'ครั้ง',
                    Colors.green.shade600,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'อัตราสำเร็จ',
                    stats['rate']!,
                    '',
                    Colors.purple.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearCountdownWidget(
              controller: homeController,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String title, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (unit.isNotEmpty) ...[
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
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
          const Text(
            'การดำเนินการ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'สถิติ',
                  Icons.analytics,
                  Colors.purple.shade600,
                  () => Get.toNamed('/statistics'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'การตั้งค่า',
                  Icons.settings,
                  Colors.blue.shade600,
                  () => Get.toNamed('/settings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildActionButton(
                      homeController.isNotificationEnabled
                          ? 'ปิดแจ้งเตือน'
                          : 'เปิดแจ้งเตือน',
                      homeController.isNotificationEnabled
                          ? Icons.notifications_off
                          : Icons.notifications_active,
                      homeController.isNotificationEnabled
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                      homeController.toggleNotifications,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'รีเฟรช',
                  Icons.refresh,
                  Colors.orange.shade600,
                  homeController.refresh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _buildPermissionWarning() {
    return Obx(() {
      if (homeController.hasPermissions) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ต้องการอนุญาติ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'แอปต้องการอนุญาติเพื่อส่งการแจ้งเตือนและตั้งเวลาแจ้งเตือนแบบแม่นยำ',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: homeController.requestPermissions,
                icon: const Icon(Icons.security),
                label: const Text('อนุญาติการใช้งาน'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
