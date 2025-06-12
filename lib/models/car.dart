import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final int price;
  final String? imageUrl;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  Car({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Car.fromFirestore(Map<String, dynamic> data, String docId) {
    return Car(
      id: docId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: data['price'] ?? 0,
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
} 