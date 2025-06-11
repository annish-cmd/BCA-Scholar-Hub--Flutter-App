import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/auth_provider.dart';
import 'home_screen.dart';
import '../main.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  final List<Widget> pages;

  const SplashScreen({super.key, required this.pages});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotateAnimation;
  late final Animation<double> _opacityAnimation;
  final int _currentIndex = 0;
  bool _showText = false;
  bool _startTextAnimation = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.elasticInOut),
      ),
    );

    _animationController.forward();

    // Show text after logo animation completes
    Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _showText = true;
        });
      }
    });

    // Start text animation after showing text
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _startTextAnimation = true;
        });
      }
    });

    // Navigate to login screen or home screen based on auth status after animation completes
    Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        navigateToNextScreen();
      }
    });
  }

  void navigateToNextScreen() {
    // Check if user is logged in with Firebase
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoggedIn) {
      // Navigate to home screen if logged in
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => HomeScreen(
                currentIndex: _currentIndex,
                pages: widget.pages,
                onIndexChanged: (index) {
                  // This will update the state in the MyApp widget using the global key
                  myAppKey.currentState?.updateIndex(index);
                },
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      // Navigate to login screen if not logged in
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  LoginScreen(pages: widget.pages),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [const Color(0xFF121212), const Color(0xFF1F1F1F)]
                    : [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Container(
                          width: screenSize.width * 0.4,
                          height: screenSize.width * 0.4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    isDarkMode
                                        ? Colors.blue.withAlpha(51)
                                        : Colors.blue.withAlpha(102),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors:
                                      isDarkMode
                                          ? [
                                            Colors.blue.shade800,
                                            Colors.purple.shade800,
                                          ]
                                          : [
                                            Colors.blue.shade600,
                                            Colors.purple.shade600,
                                          ],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.softLight,
                              child: Image.asset(
                                'assets/images/anish_library.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 50),

              // Animated text
              if (_showText)
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors:
                                isDarkMode
                                    ? [
                                      Colors.blue.shade300,
                                      Colors.purple.shade300,
                                    ]
                                    : [
                                      Colors.blue.shade800,
                                      Colors.purple.shade800,
                                    ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          "BCA Scholar Hub",
                          style: TextStyle(
                            fontFamily: 'Bauhaus 93',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (_startTextAnimation)
                        Container(
                          width: screenSize.width * 0.7,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? Colors.grey.shade900.withAlpha(128)
                                    : Colors.white.withAlpha(77),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isDarkMode
                                      ? Colors.blue.withAlpha(77)
                                      : Colors.blue.withAlpha(51),
                              width: 1,
                            ),
                          ),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade800,
                            ),
                            child: AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  'All Your BCA Study Materials',
                                  speed: const Duration(milliseconds: 83),
                                ),
                                TypewriterAnimatedText(
                                  'Explore. Learn. Grow.',
                                  speed: const Duration(milliseconds: 83),
                                ),
                                TypewriterAnimatedText(
                                  'Access your study materials',
                                  speed: const Duration(milliseconds: 83),
                                ),
                              ],
                              totalRepeatCount: 1,
                              displayFullTextOnTap: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
