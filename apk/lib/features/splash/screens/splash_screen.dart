import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../painters/seal_painter.dart';
import '../painters/circuit_painter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _sealController;
  late AnimationController _textController;
  late AnimationController _loaderController;
  late AnimationController _dotController;

  late Animation<double> _sealScale;
  late Animation<double> _sealOpacity;
  late Animation<double> _loaderProgress;

  @override
  void initState() {
    super.initState();

    // Seal pop animation
    _sealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sealScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _sealController, curve: Curves.elasticOut),
    );
    _sealOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sealController, curve: Curves.easeOut),
    );

    // Text fade-up animations
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Loader animation
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _loaderProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.easeInOut),
    );

    // Pulsing dots
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _sealController.forward();
    });
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _loaderController.repeat();
      }
    });

    // Navigate after splash
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/auth');
      }
    });
  }

  @override
  void dispose() {
    _sealController.dispose();
    _textController.dispose();
    _loaderController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout(screenWidth, screenHeight)
            : _buildPortraitLayout(screenWidth, screenHeight),
      ),
    );
  }

  Widget _buildPortraitLayout(double width, double height) {
    return Stack(
      children: [
        // Grid lines
        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(),
          ),
        ),

        // Radial glow
        Positioned(
          top: height * 0.3,
          left: width / 2 - 150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFB8860B)..withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Pulsing dots
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _dotController,
            builder: (context, _) {
              return CustomPaint(
                painter: PulsingDotsPainter(
                  animationValue: _dotController.value,
                  dots: [
                    PulsingDot(x: 0.15, y: 0.18, size: 2, delay: 0.0),
                    PulsingDot(x: 0.80, y: 0.22, size: 1.5, delay: 0.2),
                    PulsingDot(x: 0.12, y: 0.72, size: 2.5, delay: 0.4),
                    PulsingDot(x: 0.85, y: 0.68, size: 1.5, delay: 0.6),
                    PulsingDot(x: 0.30, y: 0.85, size: 2, delay: 0.3),
                    PulsingDot(x: 0.88, y: 0.30, size: 1.5, delay: 0.5),
                  ],
                ),
              );
            },
          ),
        ),

        // Corner circuits
        Positioned(
          top: 20,
          left: 20,
          child: CustomPaint(
            size: const Size(60, 60),
            painter: CircuitCornerPainter(),
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
            child: CustomPaint(
              size: const Size(60, 60),
              painter: CircuitCornerPainter(),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1.0, -1.0, 1.0),
            child: CustomPaint(
              size: const Size(60, 60),
              painter: CircuitCornerPainter(),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1.0, -1.0, 1.0),
            child: CustomPaint(
              size: const Size(60, 60),
              painter: CircuitCornerPainter(),
            ),
          ),
        ),

        // Main content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Seal
              AnimatedBuilder(
                animation: _sealController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _sealScale.value,
                    child: Opacity(
                      opacity: _sealOpacity.value,
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: SealPainter(animationValue: _sealController.value),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App name
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textController,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(_textController),
                      child: child,
                    ),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    text: 'Pay',
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Verify',
                        style: TextStyle(color: Color(0xFFB8860B)),
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _textController,
                      curve: const Interval(0.1, 0.5),
                    ),
                    child: child,
                  );
                },
                child: Container(
                  width: 40,
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8860B)..withValues(alpha: 0.4),
                  ),
                ),
              ),

              // Tagline
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _textController,
                      curve: const Interval(0.2, 0.7),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _textController,
                        curve: const Interval(0.2, 0.7),
                      )),
                      child: child,
                    ),
                  );
                },
                child: const Text(
                  'Secure · Instant · Trusted',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 11,
                    color: Color(0xFFB8860B),
                    letterSpacing: 2.5,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Sub tagline
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _textController,
                      curve: const Interval(0.3, 0.8),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _textController,
                        curve: const Interval(0.3, 0.8),
                      )),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  'CBE · TeleBirr · Awash · Amole',
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 10,
                    color: Colors.white..withValues(alpha: 0.35),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom loader
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _textController,
            builder: (context, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: _textController,
                  curve: const Interval(0.5, 1.0),
                ),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  // Loading bar track
                  Container(
                    width: 80,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white..withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: AnimatedBuilder(
                      animation: _loaderController,
                      builder: (context, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final progress = _loaderProgress.value;
                            final barWidth = constraints.maxWidth * 0.6;
                            final offset = progress * constraints.maxWidth;

                            return Stack(
                              children: [
                                Positioned(
                                  left: offset - barWidth,
                                  child: Container(
                                    width: barWidth,
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB8860B),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Powered by text
                  Text(
                    'Powered by Fira Tech Solutions',
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 9,
                      color: Colors.white..withValues(alpha: 0.2),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(double width, double height) {
    return Stack(
      children: [
        // Grid lines
        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(),
          ),
        ),

        // Radial glow
        Positioned(
          top: height / 2 - 120,
          left: width / 2 - 120,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFB8860B)..withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Main content - horizontal layout
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Seal
              AnimatedBuilder(
                animation: _sealController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _sealScale.value,
                    child: Opacity(
                      opacity: _sealOpacity.value,
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: SealPainter(animationValue: _sealController.value),
                  ),
                ),
              ),

              const SizedBox(width: 40),

              // Text block
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App name
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(_textController),
                          child: child,
                        ),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: 'Pay',
                        style: TextStyle(
                          fontFamily: 'Helvetica Neue',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Verify',
                            style: TextStyle(color: Color(0xFFB8860B)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Divider
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(0.1, 0.5),
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 2,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8860B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Tagline
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(0.2, 0.7),
                        ),
                        child: child,
                      );
                    },
                    child: const Text(
                      'Secure · Instant · Trusted',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 10,
                        color: Color(0xFFB8860B),
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Sub tagline
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(0.3, 0.8),
                        ),
                        child: child,
                      );
                    },
                    child: Text(
                      'CBE · TeleBirr · Awash · Amole · Dashen',
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 10,
                        color: Colors.white..withValues(alpha: 0.3),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
