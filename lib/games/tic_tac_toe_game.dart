import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicTacToePage extends StatefulWidget {
  final bool vsAI;
  const TicTacToePage({super.key, this.vsAI = false});

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage> {
  List<String> _board = List.filled(9, '');
  String _current = 'X';
  String? _winner;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _board = List.filled(9, '');
    _current = 'X';
    _winner = null;
    setState(() {});
  }

  void _makeMove(int idx) {
    if (_board[idx] != '' || _winner != null) return;

    final wasWinner = _winner;

    setState(() {
      _board[idx] = _current;
      _winner = _checkWinner();
      if (_winner == null) _current = _current == 'X' ? 'O' : 'X';
    });

    if (widget.vsAI && wasWinner == null && _winner == 'X') {
      _incrementTtcWins();
    }

    if (widget.vsAI && _winner == null && _current == 'O') {
      _doAiMove();
    }
  }

  Future<void> _doAiMove() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || _winner != null) return;

    final empties = <int>[];
    for (var i = 0; i < 9; i++) if (_board[i] == '') empties.add(i);
    if (empties.isEmpty) return;

    final pick = empties[_rng.nextInt(empties.length)];
    if (!mounted) return;
    setState(() {
      _board[pick] = 'O';
      _winner = _checkWinner();
      if (_winner == null) _current = 'X';
    });
  }

  Future<void> _incrementTtcWins() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.set(
        {'ttcWins': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Failed to increment ttcWins: $e');
    }
  }

  String? _checkWinner() {
    const wins = [
      [0,1,2],
      [3,4,5],
      [6,7,8],
      [0,3,6],
      [1,4,7],
      [2,5,8],
      [0,4,8],
      [2,4,6],
    ];

    for (final combo in wins) {
      final a = _board[combo[0]];
      if (a != '' && a == _board[combo[1]] && a == _board[combo[2]]) {
        return a; // X or O
      }
    }

    if (_board.every((c) => c != '')) return 'Draw';
    return null;
  }

  Widget _buildCell(int i) {
    final val = _board[i];
    return GestureDetector(
      onTap: () {
        if (widget.vsAI && _current == 'O') return;
        _makeMove(i);
      },
      child: Padding(
        padding: const EdgeInsets.all(8), // inner padding so marks don't touch the lines
        child: Container(
          decoration: BoxDecoration(
            color: val == '' ? Colors.transparent : (val == 'X' ? Colors.blue.shade700 : Colors.red.shade700),
            border: Border.all(
              color: Colors.black, // gridline color
              width: 2,            // gridline thickness
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              val,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    String statusText;
    if (_winner == null) {
      statusText = "Turn: $_current";
    } else if (_winner == 'Draw') {
      statusText = "It's a draw!";
    } else {
      statusText = "Winner: $_winner";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => TicTacToePage(vsAI: !widget.vsAI)),
              );
            },
            child: Text(widget.vsAI ? 'Play 2-player' : 'Play vs CPU'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(statusText, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 0,
                            crossAxisSpacing: 0,
                          ),
                          itemCount: 9,
                          itemBuilder: (_, i) => _buildCell(i),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _startNewGame,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Game'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
