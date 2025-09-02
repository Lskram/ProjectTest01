import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();

    // Wait for initialization and navigate
    _checkAppStateAndNavigate();
  }

  void _checkAppStateAndNavigate() async {
    // Wait a bit for splash animation
    await Future.delayed(const Duration(seconds: 3));

    // Check app state and navigate accordingly
    _navigateBasedOnState();
  }

  void _navigateBasedOnState() {
    final appController = AppController.instance;
    final currentState = appController.appState;

    switch (currentState) {
      case AppState.firstTime:
        Get.offNamed('/questionnaire');
        break;
      case AppState.ready:
        Get.offNamed('/home');
        break;
      case AppState.error:
        _showErrorDialog();
        break;
      case AppState.loading:
        // Wait a bit more and try again
        Future.delayed(const Duration(seconds: 1), () {
          _navigateBasedOnState();
        });
        break;
    }
  }

  void _showErrorDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('เกิดข้อผิดพลาด'),
        content: const Text('ไม่สามารถเริ่มต้นแอปได้ กรุณาลองใหม่อีกครั้ง'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _checkAppStateAndNavigate();
            },
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.self_improvement,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // App Name
              Text(
                'Office Syndrome Helper',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle
              Text(
                'ดูแลสุขภาพ ป้องกันออฟฟิศซินโดรม',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade600,
                ),
              ),

              const SizedBox(height: 50),

              // Loading indicator
              Obx(() {
                final appController = AppController.instance;
                final currentState = appController.appState;

                if (currentState == AppState.loading) {
                  return Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'กำลังเตรียมระบบ...',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                } else if (currentState == AppState.error) {
                  return Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 40,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'เกิดข้อผิดพลาด',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
}
