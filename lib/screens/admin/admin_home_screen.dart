import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/car.dart';
import '../../models/rental.dart';
import 'rental_detail_screen.dart';
import 'add_car_screen.dart';
import 'edit_car_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      // Permintaan Sewa (Index 0)
      RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshData,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rentals')
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Tidak ada permintaan sewa.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.directions_car, color: Colors.blue),
                    title: Text(data['carName'] ?? '-'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pemesan: ${data['userName'] ?? '-'}'),
                        Text('Tanggal: ${(data['date'] as Timestamp).toDate().toString().substring(0, 16)}'),
                        Text('Durasi: ${data['duration'] ?? '-'}'),
                        Text('Status: ${data['status'] ?? '-'}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data['status'] == 'pending') ...[
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              try {
                                await doc.reference.update({'status': 'approved'});
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Permintaan disetujui, user diminta ambil mobil.'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              try {
                                await doc.reference.update({'status': 'rejected'});
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Permintaan ditolak'), backgroundColor: Colors.red),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ] else if (data['status'] == 'approved') ...[
                          IconButton(
                            icon: const Icon(Icons.directions_car, color: Colors.orange),
                            tooltip: 'Set Sedang Digunakan',
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
                                      transaction.update(doc.reference, {'status': 'in_use'});
                                    } else {
                                      throw Exception('Stok mobil habis!');
                                    }
                                  }
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Status diubah menjadi Sedang Digunakan & stok berkurang'), backgroundColor: Colors.orange),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ] else if (data['status'] == 'in_use') ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.blue),
                            tooltip: 'Set Selesai',
                            onPressed: () async {
                              try {
                                final carId = data['carId'];
                                final carRef = FirebaseFirestore.instance.collection('cars').doc(carId);
                                await FirebaseFirestore.instance.runTransaction((transaction) async {
                                  final carSnapshot = await transaction.get(carRef);
                                  if (carSnapshot.exists) {
                                    final currentQuantity = carSnapshot.data()?['quantity'] ?? 0;
                                    transaction.update(carRef, {'quantity': currentQuantity + 1});
                                    transaction.update(doc.reference, {'status': 'completed'});
                                  }
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Status diubah menjadi Selesai, stok mobil bertambah'), backgroundColor: Colors.blue),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RentalDetailScreen(rentalId: doc.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      // Riwayat Sewa (Index 1)
      RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshData,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rentals')
              .where('status', whereIn: ['approved', 'in_use', 'completed', 'returned', 'rejected'])
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Tidak ada riwayat sewa.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'];
                final statusColor = status == 'approved' ? Colors.green : status == 'returned' ? Colors.blue : Colors.red;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.directions_car, color: statusColor),
                    title: Text(data['carName'] ?? '-'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pemesan: ${data['userName'] ?? '-'}'),
                        Text('Status: $status', style: TextStyle(color: statusColor)),
                        Text('Tanggal: ${(data['date'] as Timestamp).toDate().toString().substring(0, 16)}'),
                        Text('Durasi: ${data['duration'] ?? '-'}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data['status'] == 'approved') ...[
                          IconButton(
                            icon: const Icon(Icons.directions_car, color: Colors.orange),
                            tooltip: 'Set Sedang Digunakan',
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
                                      transaction.update(doc.reference, {'status': 'in_use'});
                                    } else {
                                      throw Exception('Stok mobil habis!');
                                    }
                                  }
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Status diubah menjadi Sedang Digunakan & stok berkurang'), backgroundColor: Colors.orange),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ] else if (data['status'] == 'in_use') ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.blue),
                            tooltip: 'Set Selesai',
                            onPressed: () async {
                              try {
                                final carId = data['carId'];
                                final carRef = FirebaseFirestore.instance.collection('cars').doc(carId);
                                await FirebaseFirestore.instance.runTransaction((transaction) async {
                                  final carSnapshot = await transaction.get(carRef);
                                  if (carSnapshot.exists) {
                                    final currentQuantity = carSnapshot.data()?['quantity'] ?? 0;
                                    transaction.update(carRef, {'quantity': currentQuantity + 1});
                                    transaction.update(doc.reference, {'status': 'completed'});
                                  }
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Status diubah menjadi Selesai, stok mobil bertambah'), backgroundColor: Colors.blue),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RentalDetailScreen(rentalId: doc.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      // Daftar Mobil (Index 2)
      RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshData,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cars')
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Tidak ada data mobil.'));
            }

            final cars = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Car.fromFirestore(data, doc.id);
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.directions_car, color: Colors.blue),
                    title: Text(car.name),
                    subtitle: Text('Tersedia: ${car.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditCarScreen(
                                  carId: car.id,
                                  carData: {
                                    'name': car.name,
                                    'description': car.description ?? '',
                                    'price': car.price,
                                    'quantity': car.quantity,
                                    'imageUrl': car.imageUrl,
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance.collection('cars').doc(car.id).delete();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mobil berhasil dihapus'), backgroundColor: Colors.green),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      // Profil (Index 3)
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text(FirebaseAuth.instance.currentUser?.email ?? '-', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: _pages[_selectedIndex],
        ),
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCarScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'Permintaan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Mobil'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
} 