import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class RentalDetailScreen extends StatefulWidget {
  final String rentalId;

  const RentalDetailScreen({super.key, required this.rentalId});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userRole = userDoc.data()?['role'] as String?;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Penyewaan'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('rentals').doc(widget.rentalId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _userRole == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Detail penyewaan tidak ditemukan.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isAdmin = _userRole == 'admin';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Mobil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Nama Mobil: ${data['carName'] ?? '-'}'),
                        const SizedBox(height: 16),
                        const Text(
                          'Informasi Penyewa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Nama: ${data['userName'] ?? '-'}'),
                        Text('Email: ${data['userEmail'] ?? '-'}'),
                        const SizedBox(height: 16),
                        const Text(
                          'Detail Penyewaan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: Text(data['carName'] ?? '-'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nama Pemesan: ${data['userName'] ?? '-'}'),
                              Text('Durasi: ${data['duration'] ?? '-'} hari'),
                              Text('Status: ${data['status'] ?? '-'}'),
                              if (data['date'] != null)
                                Text('Tanggal Pengambilan: ${(data['date'] as Timestamp).toDate().day}/${(data['date'] as Timestamp).toDate().month}/${(data['date'] as Timestamp).toDate().year}'),
                              if (data['returnDate'] != null)
                                Text('Tanggal Pengembalian: ${(data['returnDate'] as Timestamp).toDate().day}/${(data['returnDate'] as Timestamp).toDate().month}/${(data['returnDate'] as Timestamp).toDate().year}'),
                              Text('Total Harga: Rp${data['totalPrice'] ?? 0}'),
                            ],
                          ),
                        ),
                        if (data['imageUrl'] != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Foto KTP',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final url = Uri.parse(data['imageUrl']);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            child: Image.network(
                              data['imageUrl'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isAdmin && data['status'] == 'pending') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Aksi Admin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Setujui'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () async {
                            try {
                              final carId = data['carId'];
                              final carRef = FirebaseFirestore.instance.collection('cars').doc(carId);

                              await FirebaseFirestore.instance.runTransaction((transaction) async {
                                final carSnapshot = await transaction.get(carRef);
                                if (carSnapshot.exists) {
                                  final currentQuantity = carSnapshot.data()?['quantity'] ?? 0;
                                  if (currentQuantity > 0) {
                                    transaction.update(carRef, {'quantity': currentQuantity - 1});
                                    transaction.update(snapshot.data!.reference, {'status': 'approved'});
                                  }
                                }
                              });

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Penyewaan disetujui dan stok mobil diperbarui!'), backgroundColor: Colors.green),
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal menyetujui permintaan: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('Tolak'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            try {
                              await snapshot.data!.reference.update({'status': 'rejected'});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Penyewaan ditolak'), backgroundColor: Colors.red),
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal menolak permintaan: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
} 