import 'package:flutter/material.dart';
import 'dart:math';
import '../pages/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _textController;
  late AnimationController _transitionController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _screenFadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _textController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Анимация для плавного перехода
    _screenFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: const Cubic(0.2, 0.8, 0.4, 1.0), // Специальная плавная кривая
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

    _textController.forward();

    // Плавный переход на главный экран
    Future.delayed(const Duration(milliseconds: 5500), () {
      // Запускаем анимацию перехода
      _transitionController.forward().then((_) {
        // Переходим на главный экран с плавной анимацией
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: Duration.zero, // Нулевая длительность, так как анимация уже выполнена
            pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _textController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        return Stack(
          children: [
            // Главный экран (появляется под сплеш-скрином во время перехода)
            if (_transitionController.value > 0.5)
              Transform.scale(
                scale: 1.0 + (_transitionController.value - 0.5) * 0.5,
                child: HomePage(),
              ),

            // Splash-экран с анимацией
            FadeTransition(
              opacity: _screenFadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Scaffold(
                  backgroundColor: Colors.blueGrey,
                  body: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: WavePainter(_waveController.value),
                            size: MediaQuery.of(context).size,
                          );
                        },
                      ),
                      Center(
                        child: FadeTransition(
                          opacity: TweenSequence([
                            TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
                            TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 25),
                            TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
                          ]).animate(_textController),
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: const Text(
                              'Welcome to ToDoList',
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 36.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 30.0;
    final waveLength = size.width / 1.2;

    path.moveTo(0, size.height * 0.5);

    for (double x = 0; x <= size.width; x++) {
      double y = sin((x / waveLength * 2 * pi) + (animationValue * 2 * pi)) *
          waveHeight +
          size.height * 0.5;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}