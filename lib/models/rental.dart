import 'package:cloud_firestore/cloud_firestore.dart';

class Rental {
  final String id;
  final String userId;
  final String userName;
  final String carId;
  final String carName;
  final String duration;
  final DateTime date;
  final String status;
  final String? imageUrl;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  Rental({
    required this.id,
    required this.userId,
    required this.userName,
    required this.carId,
    required this.carName,
    required this.duration,
    required this.date,
    required this.status,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Rental.fromFirestore(Map<String, dynamic> data, String docId) {
    return Rental(
      id: docId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      carId: data['carId'] ?? '',
      carName: data['carName'] ?? '',
      duration: data['duration'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'carId': carId,
      'carName': carName,
      'duration': duration,
      'date': Timestamp.fromDate(date),
      'status': status,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
} 