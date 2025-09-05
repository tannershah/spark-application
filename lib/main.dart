import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spark_application/games/hangman_game.dart';
import 'package:spark_application/user_auth/create_account_page.dart';
import 'package:spark_application/games/tic_tac_toe_game.dart';
import 'firebase_options.dart';

import 'user_auth/login_page.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseAuth.instance.authStateChanges().listen((user) {
  });
    runApp(const MyApp());
  }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginPage(),
        '/createAccount': (context) => const CreateAccountPage(),
        '/hangman': (context) => const HangmanPage(),
        '/tic-tac-toe': (context) => const TicTacToePage(),
        '/home': (context) => const MyHomePage(title: 'Welcome!')
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = authSnap.data;
        if (user == null) {
          return const LoginPage();
        }
        return const MyHomePage(title: 'Spark Arcade');
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<GameButton> games =  const [
      GameButton(title: 'Play Hangman', icon: Icons.videogame_asset, route: '/hangman'),
      GameButton(title: 'Play Tic-Tac-Toe', icon: Icons.videogame_asset, route: '/tic-tac-toe'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Log out?'),
                content: const Text('Are you sure you want to log out?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Log out')),
                ],
              ),
            );

            if (confirm != true) return;

            try {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logout failed: $e')),
              );
            }
          },
        ),
      ],
      ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  games.length * 2 - 1,
                  (index) {
                    if (index.isOdd) return const SizedBox(height: 12);
                    final i = index ~/ 2;
                    return games[i];
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            _StatsWidget(),
          ],
        ),
    );
  }
}

class GameButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;
  const GameButton({required this.title, required this.icon, required this.route, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, route),
      icon: Icon(icon, size: 28),
      label: Text(title, style: const TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(64)),
    );
  }
}

class _StatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text("Not logged in");
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("No stats yet");
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final hangmanWins = data['hangmanWins'] ?? 0;
        final ttcWins = data['ttcWins'] ?? 0;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.accessibility_new, size: 28, color: Colors.blue),
                    const SizedBox(height: 4),
                    Text("Hangman Wins",
                        style: Theme.of(context).textTheme.bodySmall),
                    Text("$hangmanWins",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.smart_toy, size: 28, color: Colors.red),
                    const SizedBox(height: 4),
                    Text("Tic-Tac-Toe Wins VS CPU",
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center),
                    Text("$ttcWins",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

