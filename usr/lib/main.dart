import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Endless Runner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  static const double characterWidth = 50;
  static const double characterHeight = 50;
  static const double groundHeight = 50;
  static const double obstacleWidth = 40;
  static const double obstacleHeight = 40;
  static const double gravity = 0.6;
  static const double jumpStrength = -15.0;

  late AnimationController _controller;
  double _characterY = 0;
  double _characterVelocityY = 0;
  bool _isJumping = false;
  bool _isSliding = false;

  final List<Rect> _obstacles = [];
  double _gameSpeed = 5.0;
  int _score = 0;
  bool _gameOver = false;

  Timer? _speedIncreaseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_gameLoop);

    startGame();
  }

  void startGame() {
    setState(() {
      _characterY = 0;
      _characterVelocityY = 0;
      _isJumping = false;
      _isSliding = false;
      _obstacles.clear();
      _gameSpeed = 5.0;
      _score = 0;
      _gameOver = false;
      _addObstacle();
    });
    _controller.repeat();
    _speedIncreaseTimer?.cancel();
    _speedIncreaseTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_gameOver) {
        setState(() {
          _gameSpeed += 0.5;
        });
      }
    });
  }

  void _addObstacle() {
    final screenWidth = MediaQuery.of(context).size.width;
    _obstacles.add(
      Rect.fromLTWH(
        screenWidth,
        0, // Will be adjusted in game loop
        obstacleWidth,
        obstacleHeight,
      ),
    );
  }

  void _gameLoop() {
    if (_gameOver) {
      _controller.stop();
      _speedIncreaseTimer?.cancel();
      return;
    }

    // Character physics
    if (_isJumping) {
      _characterVelocityY += gravity;
      _characterY += _characterVelocityY;

      if (_characterY >= 0) {
        _characterY = 0;
        _isJumping = false;
        _characterVelocityY = 0;
      }
    }

    // Obstacle movement and management
    final screenWidth = MediaQuery.of(context).size.width;
    for (int i = _obstacles.length - 1; i >= 0; i--) {
      final obstacle = _obstacles[i];
      final newLeft = obstacle.left - _gameSpeed;
      _obstacles[i] = obstacle.translate(newLeft - obstacle.left, 0);

      if (newLeft < -obstacleWidth) {
        _obstacles.removeAt(i);
        _score++;
      }
    }

    if (_obstacles.isEmpty || (screenWidth - _obstacles.last.left) > 300) {
      _addObstacle();
    }
    
    // Collision detection
    final characterRect = Rect.fromLTWH(
      50,
      MediaQuery.of(context).size.height - groundHeight - characterHeight + (_isSliding ? 20 : _characterY),
      characterWidth,
      _isSliding ? characterHeight / 2 : characterHeight,
    );

    for (final obstacle in _obstacles) {
       final obstacleOnGroundRect = Rect.fromLTWH(
         obstacle.left,
         MediaQuery.of(context).size.height - groundHeight - obstacle.height,
         obstacle.width,
         obstacle.height
       );
      if (characterRect.overlaps(obstacleOnGroundRect)) {
        setState(() {
          _gameOver = true;
        });
      }
    }

    setState(() {});
  }

  void _jump() {
    if (!_isJumping && !_isSliding) {
      setState(() {
        _isJumping = true;
        _characterVelocityY = jumpStrength;
      });
    }
  }

  void _slide() {
    if (!_isJumping) {
      setState(() {
        _isSliding = true;
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if(mounted){
          setState(() {
            _isSliding = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _speedIncreaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: GestureDetector(
        onTap: _jump,
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! > 3) { // Swiping down
            _slide();
          }
        },
        child: Stack(
          children: [
            // Background
            Container(color: Colors.lightBlue[100]),

            // Ground
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: groundHeight,
                color: Colors.green[400],
              ),
            ),

            // Character
            Positioned(
              bottom: groundHeight - (_isSliding ? 20 : _characterY),
              left: 50,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: characterWidth,
                height: _isSliding ? characterHeight / 2 : characterHeight,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(_isSliding ? 20 : 8),
                ),
              ),
            ),

            // Obstacles
            ..._obstacles.map((obstacle) {
              return Positioned(
                bottom: groundHeight,
                left: obstacle.left,
                child: Container(
                  width: obstacle.width,
                  height: obstacle.height,
                  color: Colors.red,
                ),
              );
            }).toList(),

            // Score
            Positioned(
              top: 50,
              left: 20,
              child: Text(
                'Score: $_score',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            // Game Over Screen
            if (_gameOver)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Game Over',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Your Score: $_score',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: startGame,
                        child: const Text('Restart Game'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
