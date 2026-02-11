import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Navigate to appropriate page after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () async {
      if (mounted) {
        final box = await Hive.openBox('database');
        final username = box.get("username");

        if (username != null) {
          // User exists, go to login
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (_) => const LoginPage()),
          );
        } else {
          // New user, go to signup
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (_) => const SignupPage()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.3; // 30% of screen width

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CupertinoColors.systemPurple,
                CupertinoColors.systemIndigo,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            padding: EdgeInsets.all(logoSize * 0.15),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/icon/logo.png',
                              width: logoSize,
                              height: logoSize,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: size.height * 0.04),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'QuickPay',
                      style: TextStyle(
                        fontSize: size.width * 0.09,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.012),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Your Digital Wallet',
                      style: TextStyle(
                        fontSize: size.width * 0.04,
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
