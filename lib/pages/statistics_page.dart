import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../controllers/statistics_controller.dart';
import '../models/notification_session.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late StatisticsController statisticsController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize StatisticsController if not exists
    if (!Get.isRegistered<StatisticsController>()) {
      Get.put(StatisticsController());
    }
    statisticsController = StatisticsController.instance;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สถิติและผลการใช้งาน'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'วันนี้', icon: Icon(Icons.today)),
            Tab(text: 'สัปดาห์', icon: Icon(Icons.date_range)),
            Tab(text: 'เดือน', icon: Icon(Icons.calendar_month)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: statisticsController.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: statisticsController.refresh,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTodayTab(),
            _buildWeeklyTab(),
            _buildMonthlyTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab() {
    return Obx(() {
      if (statisticsController.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTodayOverviewCard(),
            const SizedBox(height: 24),
            _buildCompletionRateCard(
              statisticsController.todayCompletionRate,
              statisticsController.todayCompletedSessions,
              statisticsController.todayTotalSessions,
              'วันนี้',
            ),
            const SizedBox(height: 24),
            _buildSessionsListCard(statisticsController.todaySessions),
            const SizedBox(height: 24),
            _buildInsightsCard('วันนี้'),
          ],
        ),
      );
    });
  }

  Widget _buildWeeklyTab() {
    return Obx(() {
      if (statisticsController.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWeeklyOverviewCard(),
            const SizedBox(height: 24),
            _buildCompletionRateCard(
              statisticsController.weeklyCompletionRate,
              statisticsController.weeklyCompletedSessions,
              statisticsController.weeklyTotalSessions,
              'สัปดาห์นี้',
            ),
            const SizedBox(height: 24),
            _buildWeeklyChartCard(),
            const SizedBox(height: 24),
            _buildInsightsCard('สัปดาห์นี้'),
          ],
        ),
      );
    });
  }

  Widget _buildMonthlyTab() {
    return Obx(() {
      if (statisticsController.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMonthlyOverviewCard(),
            const SizedBox(height: 24),
            _buildCompletionRateCard(
              statisticsController.monthlyCompletionRate,
              statisticsController.monthlyCompletedSessions,
              statisticsController.monthlyTotalSessions,
              'เดือนนี้',
            ),
            const SizedBox(height: 24),
            _buildMonthlyTrendsCard(),
            const SizedBox(height: 24),
            _buildInsightsCard('เดือนนี้'),
          ],
        ),
      );
    });
  }

  Widget _buildTodayOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'สถิติวันนี้',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'ทั้งหมด',
                  '${statisticsController.todayTotalSessions}',
                  'ครั้ง',
                  Colors.blue.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'สำเร็จ',
                  '${statisticsController.todayCompletedSessions}',
                  'ครั้ง',
                  Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'ข้าม',
                  '${statisticsController.todaySkippedSessions}',
                  'ครั้ง',
                  Colors.red.shade400,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'เลื่อน',
                  '${statisticsController.todaySnoozedSessions}',
                  'ครั้ง',
                  Colors.orange.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'สถิติสัปดาห์นี้',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'ทั้งหมด',
                  '${statisticsController.weeklyTotalSessions}',
                  'ครั้ง',
                  Colors.blue.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'สำเร็จ',
                  '${statisticsController.weeklyCompletedSessions}',
                  'ครั้ง',
                  Colors.green.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'อัตราสำเร็จ',
                  '${(statisticsController.weeklyCompletionRate * 100).toInt()}',
                  '%',
                  Colors.purple.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'สถิติเดือนนี้',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'ทั้งหมด',
                  '${statisticsController.monthlyTotalSessions}',
                  'ครั้ง',
                  Colors.blue.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'สำเร็จ',
                  '${statisticsController.monthlyCompletedSessions}',
                  'ครั้ง',
                  Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'วันที่มีกิจกรรม',
                  '${statisticsController.activeDaysThisMonth}',
                  'วัน',
                  Colors.purple.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'เฉลี่ยต่อวัน',
                  '${statisticsController.averageSessionsPerDay.toStringAsFixed(1)}',
                  'ครั้ง',
                  Colors.orange.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRateCard(
    double rate,
    int completed,
    int total,
    String period,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            'อัตราการทำกิจกรรมสำเร็จ$period',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 80,
            lineWidth: 12,
            percent: rate,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(rate * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getCompletionRateColor(rate),
                  ),
                ),
                Text(
                  '$completed/$total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            progressColor: _getCompletionRateColor(rate),
            backgroundColor: Colors.grey.shade200,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 16),
          _buildRatingText(rate),
        ],
      ),
    );
  }

  Widget _buildWeeklyChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กิจกรรมรายวัน (7 วันที่ผ่านมา)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _buildSimpleBarChart(),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart() {
    final dailyStats = statisticsController.dailyStatsForWeek;
    final maxValue = dailyStats.values.isEmpty ? 1.0 : dailyStats.values.reduce((a, b) => a > b ? a : b).toDouble();
    
    return Container(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final day = DateTime.now().subtract(Duration(days: 6 - index));
          final dayKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
          final value = dailyStats[dayKey] ?? 0;
          final height = maxValue > 0 ? (value / maxValue) * 160 : 0.0;
          
          const dayNames = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];
          final dayName = dayNames[day.weekday % 7];
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 24,
                height: height,
                decoration: BoxDecoration(
                  color: value > 0 ? Colors.blue.shade400 : Colors.grey.shade300,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyTrendsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แนวโน้มรายสัปดาห์',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _buildTrendChart(),
          const SizedBox(height: 16),
          _buildTrendAnalysis(),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final weeklyTrends = statisticsController.weeklyTrends;
    
    return Container(
      height: 160,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          final week = index + 1;
          final sessions = weeklyTrends[week] ?? 0;
          final maxValue = weeklyTrends.values.isEmpty ? 1 : weeklyTrends.values.reduce((a, b) => a > b ? a : b);
          final height = maxValue > 0 ? (sessions / maxValue) * 120 : 0.0;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                sessions.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                width: 32,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.purple.shade400,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'สัปดาห์ $week',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    final trends = statisticsController.weeklyTrends;
    String trendText;
    Color trendColor;
    IconData trendIcon;

    if (trends.length < 2) {
      trendText = 'ข้อมูลไม่เพียงพอสำหรับวิเคราะห์แนวโน้ม';
      trendColor = Colors.grey;
      trendIcon = Icons.info;
    } else {
      final thisWeek = trends[4] ?? 0;
      final lastWeek = trends[3] ?? 0;
      
      if (thisWeek > lastWeek) {
        trendText = 'เพิ่มขึ้น ${thisWeek - lastWeek} ครั้งจากสัปดาห์ที่แล้ว';
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
      } else if (thisWeek < lastWeek) {
        trendText = 'ลดลง ${lastWeek - thisWeek} ครั้งจากสัปดาห์ที่แล้ว';
        trendColor = Colors.orange;
        trendIcon = Icons.trending_down;
      } else {
        trendText = 'คงที่เท่ากับสัปดาห์ที่แล้ว';
        trendColor = Colors.blue;
        trendIcon = Icons.trending_flat;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: trendColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(trendIcon, color: trendColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trendText,
              style: TextStyle(
                color: trendColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsListCard(List<NotificationSession> sessions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กิจกรรมล่าสุด',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty)
            const Center(
              child: Text(
                'ยังไม่มีกิจกรรมในวันนี้',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Column(
              children: sessions.take(5).map((session) => _buildSessionItem(session)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(NotificationSession session) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (session.status) {
      case SessionStatusHive.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'สำเร็จ';
        break;
      case SessionStatusHive.skipped:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'ข้าม';
        break;
      case SessionStatusHive.snoozed:
        statusColor = Colors.orange;
        statusIcon = Icons.snooze;
        statusText = 'เลื่อน';
        break;
      case SessionStatusHive.pending:
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        statusText = 'รอดำเนินการ';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'ไม่ทราบ';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.scheduledTime.hour.toString().padLeft(2, '0')}:${session.scheduledTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${session.treatmentIds.length} ท่าออกกำลังกาย',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(String period) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                'ข้อมูลเชิงลึก$period',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...statisticsController.getInsights(period).map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildRatingText(double rate) {
    String text;
    Color color;
    
    if (rate >= 0.8) {
      text = 'ยอดเยี่ยม! 🎉';
      color = Colors.green;
    } else if (rate >= 0.6) {
      text = 'ดีมาก! 👍';
      color = Colors.blue;
    } else if (rate >= 0.4) {
      text = 'ปานกลาง 👌';
      color = Colors.orange;
    } else if (rate >= 0.2) {
      text = 'ควรปรับปรุง 📈';
      color = Colors.red;
    } else {
      text = 'เริ่มต้นใหม่ 🚀';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.blue;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade200,
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }
}