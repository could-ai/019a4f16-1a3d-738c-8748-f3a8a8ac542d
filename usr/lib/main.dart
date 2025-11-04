import 'dart:async';
import 'dart:math';
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
  static const double coinWidth = 25;
  static const double coinHeight = 25;
  static const double gravity = 0.6;
  static const double jumpStrength = -15.0;

  late AnimationController _controller;
  double _characterY = 0;
  double _characterVelocityY = 0;
  bool _isJumping = false;
  bool _isSliding = false;

  final List<Rect> _obstacles = [];
  final List<Rect> _coins = [];
  double _gameSpeed = 5.0;
  int _score = 0;
  int _coinsCollected = 0;

  Timer? _speedIncreaseTimer;
  final Stopwatch _stopwatch = Stopwatch();

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
      _coins.clear();
      _gameSpeed = 5.0;
      _score = 0;
      _coinsCollected = 0;
      _addObstacle();
      _addCoin();
    });
    _controller.repeat();
    _speedIncreaseTimer?.cancel();
    _speedIncreaseTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _gameSpeed += 0.5;
      });
    });
    _stopwatch..reset()..start();
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
  
  void _addCoin() {
    final screenWidth = MediaQuery.of(context).size.width;
    // Add some randomness to coin spawning
    final nextCoinX = _coins.isEmpty ? screenWidth : _coins.last.right + Random().nextInt(200) + 150;
    _coins.add(
      Rect.fromLTWH(
        nextCoinX,
        0, // Will be adjusted
        coinWidth,
        coinHeight,
      ),
    );
  }

  void _gameLoop() {
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
    
    // Coin movement and management
    for (int i = _coins.length - 1; i >= 0; i--) {
      final coin = _coins[i];
      final newLeft = coin.left - _gameSpeed;
      _coins[i] = coin.translate(newLeft - coin.left, 0);

      if (newLeft < -coinWidth) {
        _coins.removeAt(i);
      }
    }

    if (_obstacles.isEmpty || (screenWidth - _obstacles.last.left) > 300) {
      _addObstacle();
    }
    
    if (_coins.isEmpty || (screenWidth - _coins.last.left) > 400) {
      _addCoin();
    }
    
    // Collision detection
    final characterRect = Rect.fromLTWH(
      50,
      MediaQuery.of(context).size.height - groundHeight - characterHeight + (_isSliding ? 20 : _characterY),
      characterWidth,
      _isSliding ? characterHeight / 2 : characterHeight,
    );

    // Coin collection
    for (int i = _coins.length - 1; i >= 0; i--) {
      final coin = _coins[i];
      final coinOnGroundRect = Rect.fromLTWH(
        coin.left,
        MediaQuery.of(context).size.height - groundHeight - coin.height,
        coin.width,
        coin.height
      );
      if (characterRect.overlaps(coinOnGroundRect)) {
        setState(() {
          _coinsCollected++;
          _coins.removeAt(i);
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
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            
            // Coins
            ..._coins.map((coin) {
              return Positioned(
                bottom: groundHeight,
                left: coin.left,
                child: Container(
                  width: coin.width,
                  height: coin.height,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),

            // Score, Timer, and Coins UI
            Positioned(
              top: 50,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score: $_score',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time: ${_stopwatch.elapsed.inSeconds}s',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coins: $_coinsCollected',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
