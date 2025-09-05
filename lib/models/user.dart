class AppUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final int hangmanWins;
  final int ttcWins;

  AppUser({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.hangmanWins,
    required this.ttcWins,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      hangmanWins: map['hangmanWins'] ?? 0,
      ttcWins: map['ttcWins'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'hangmanWins': hangmanWins,
      'ttcWins': ttcWins,
    };
  }
}