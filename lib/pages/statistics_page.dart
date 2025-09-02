import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/statistics_controller.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('สถิติการใช้งาน'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => StatisticsController.instance.refresh(),
          ),
        ],
      ),
      body: Obx(() {
        final statsController = StatisticsController.instance;
        
        if (statsController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return RefreshIndicator(
          onRefresh: () => statsController.refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Today Stats
              _buildTodayStatsCard(statsController),
              
              const SizedBox(height: 16),
              
              // Weekly Overview
              _buildWeeklyOverviewCard(statsController),
              
              const SizedBox(height: 16),
              
              // Insights
              _buildInsightsCard(statsController),
              
              const SizedBox(height: 16),
              
              // Weekly Chart (Placeholder)
              _buildWeeklyChartCard(statsController),
              
              const SizedBox(height: 16),
              
              // Actions
              _buildActionButtons(statsController),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTodayStatsCard(StatisticsController controller) {
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
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'สถิติวันนี้',
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
                  title: 'ทั้งหมด',
                  value: '${controller.todayTotalSessions}',
                  subtitle: 'ครั้ง',
                  color: Colors.blue.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  title: 'สำเร็จ',
                  value: '${controller.todayCompletedSessions}',
                  subtitle: 'ครั้ง',
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  title: 'ข้าม',
                  value: '${controller.todaySkippedSessions}',
                  subtitle: 'ครั้ง',
                  color: Colors.red.shade400,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  title: 'อัตราสำเร็จ',
                  value: '${(controller.todayCompletionRate * 100).toInt()}',
                  subtitle: '%',
                  color: Colors.purple.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverviewCard(StatisticsController controller) {
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
                Icons.calendar_view_week,
                color: Colors.green.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'ภาพรวมสัปดาห์นี้',
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
                  title: 'ทั้งหมด',
                  value: '${controller.weeklyTotalSessions}',
                  subtitle: 'ครั้ง',
                  color: Colors.blue.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  title: 'สำเร็จ',
                  value: '${controller.weeklyCompletedSessions}',
                  subtitle: 'ครั้ง',
                  color: Colors.green.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  title: 'อัตราสำเร็จ',
                  value: '${(controller.weeklyCompletionRate * 100).toInt()}',
                  subtitle: '%',
                  color: Colors.purple.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(StatisticsController controller) {
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
                Icons.insights,
                color: Colors.orange.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'ข้อมูลเชิงลึก',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInsightItem(
            icon: Icons.favorite,
            title: 'จุดที่ดูแลบ่อยสุด',
            value: controller.getMostCommonPainPoint(),
            color: Colors.red.shade400,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightItem(
            icon: Icons.schedule,
            title: 'ช่วงเวลาที่ดีสุด',
            value: controller.getBestTimeOfDay(),
            color: Colors.blue.shade600,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightItem(
            icon: Icons.trending_up,
            title: 'แนวโน้ม',
            value: controller.getWeeklyTrend(),
            color: Colors.green.shade600,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightItem(
            icon: Icons.local_fire_department,
            title: 'Streak',
            value: '${controller.getCurrentStreak()} วัน',
            color: Colors.orange.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChartCard(StatisticsController controller) {
    final chartData = controller.getWeeklyChartData();
    
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
                Icons.show_chart,
                color: Colors.purple.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'กราฟรายสัปดาห์',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Simple bar chart representation
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartData.map((data) {
                final rate = data['rate'] as double;
                final height = (rate * 120) + 10; // Min height 10
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(rate * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: height,
                      decoration: BoxDecoration(
                        color: rate > 0.7 
                            ? Colors.green.shade400 
                            : rate > 0.4 
                                ? Colors.orange.shade400 
                                : Colors.red.shade400,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['day'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(StatisticsController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showExportDialog(controller),
                icon: const Icon(Icons.share),
                label: const Text('ส่งออกสถิติ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCleanupDialog(controller),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('ลบข้อมูลเก่า'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              TextSpan(
                text: ' $subtitle',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showExportDialog(StatisticsController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('ส่งออกสถิติ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('เลือกรูปแบบที่ต้องการส่งออก'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('ข้อความ'),
              onTap: () {
                Navigator.pop(Get.context!);
                final exportText = controller.exportStatistics();
                Get.dialog(
                  AlertDialog(
                    title: const Text('สถิติการใช้งาน'),
                    content: SingleChildScrollView(
                      child: SelectableText(exportText),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(Get.context!),
                        child: const Text('ปิด'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog(StatisticsController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('ลบข้อมูลเก่า'),
        content: const Text(
          'คุณแน่ใจหรือไม่ที่จะลบข้อมูลที่เก่ากว่า 30 วัน?\n'
          'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(Get.context!);
              controller.cleanupOldData();
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }
}