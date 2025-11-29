import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyPoints {
  final String date;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int points;
  final int sessionsCompleted;
  final int questionsAnswered;
  final int correctAnswers;

  WeeklyPoints({
    required this.date,
    required this.weekStart,
    required this.weekEnd,
    required this.points,
    required this.sessionsCompleted,
    required this.questionsAnswered,
    required this.correctAnswers,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'weekStart': Timestamp.fromDate(weekStart),
      'weekEnd': Timestamp.fromDate(weekEnd),
      'points': points,
      'sessionsCompleted': sessionsCompleted,
      'questionsAnswered': questionsAnswered,
      'correctAnswers': correctAnswers,
    };
  }

  factory WeeklyPoints.fromMap(Map<String, dynamic> map, String date) {
    return WeeklyPoints(
      date: date,
      weekStart: (map['weekStart'] as Timestamp).toDate(),
      weekEnd: (map['weekEnd'] as Timestamp).toDate(),
      points: map['points'] as int,
      sessionsCompleted: map['sessionsCompleted'] as int,
      questionsAnswered: map['questionsAnswered'] as int,
      correctAnswers: map['correctAnswers'] as int,
    );
  }
}
