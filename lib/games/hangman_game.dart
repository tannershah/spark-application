import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const HangmanApp());
}

class HangmanApp extends StatelessWidget {
  const HangmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hangman',
      theme: ThemeData.dark(),
      home: const HangmanPage(),
    );
  }
}

class HangmanPage extends StatefulWidget {
  const HangmanPage({super.key});

  @override
  State<HangmanPage> createState() => _HangmanPageState();
}

class _HangmanPageState extends State<HangmanPage> {
  final List<String> _wordList = [
    // Spark & energy vibes
    "spark",
    "ignite",
    "flame",
    "ember",
    "flash",
    "lightning",
    "glow",
    "shine",
    "brilliant",
    "bright",
    "glimmer",
    "flare",
    "energy",
    "momentum",
    "vibe",
    "fusion",
    "synergy",
    "inspire",
    "create",
    "explore",
    "discover",
    "curiosity",
    "imagine",
    "innovate",
    "dynamic",
    "vision",
    "future",
    "collaborate",
    "together",
    "impact",

    // CS / coding-friendly words
    "code",
    "debug",
    "algorithm",
    "loop",
    "function",
    "variable",
    "array",
    "stack",
    "queue",
    "binary",
    "matrix",
    "network",
    "python",
    "java",
    "flutter",
    "firebase",
    "linux",
    "opensource",
    "compile",
    "execute"
  ];


  late String _word;
  late List<String> _guessedLetters;
  int _wrongGuesses = 0;
  final int _maxWrong = 10;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    final random = Random();
    _word = _wordList[random.nextInt(_wordList.length)].toUpperCase();
    _guessedLetters = [];
    _wrongGuesses = 0;
    setState(() {});
  }

  void _guessLetter(String letter) {
    if (_guessedLetters.contains(letter)) return;

    final wasWon = _isWon;

    _guessedLetters.add(letter);
    if (!_word.contains(letter)) {
      _wrongGuesses++;
    }

    final nowWon = _word.split('').every((c) => _guessedLetters.contains(c));
    if (!wasWon && nowWon) {
      _incrementHangmanWins();
    }

    setState(() {});
  }

  Future<void> _incrementHangmanWins() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.set(
        {'hangmanWins': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Failed to increment hangmanWins: $e');
    }
  }

  String get _displayWord {
    return _word.split('').map((c) {
      return _guessedLetters.contains(c) ? c : "_";
    }).join(" ");
  }

  bool get _isWon =>
      _word.split('').every((c) => _guessedLetters.contains(c));

  bool get _isLost => _wrongGuesses >= _maxWrong;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hangman")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _displayWord,
              style: const TextStyle(fontSize: 40, letterSpacing: 4),
            ),
            const SizedBox(height: 20),
            Text("Wrong guesses: $_wrongGuesses / $_maxWrong"),
            const SizedBox(height: 20),
            if (_isWon)
              const Text("🎉 You won!", style: TextStyle(fontSize: 24)),
            if (_isLost)
              Text("💀 You lost! Word was $_word",
                  style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 372),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('').map((letter) {
                    final alreadyGuessed = _guessedLetters.contains(letter);
                    return SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                        onPressed: (_isWon || _isLost || alreadyGuessed)
                            ? null
                            : () => _guessLetter(letter),
                        child: Text(letter, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startNewGame,
              child: const Text("New Game"),
            )
          ],
        ),
      ),
    );
  }
}
