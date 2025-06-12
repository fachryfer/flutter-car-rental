import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';

class RentCarFormScreen extends StatefulWidget {
  final String carId;
  final String carName;
  final int price;

  const RentCarFormScreen({
    super.key,
    required this.carId,
    required this.carName,
    required this.price,
  });

  @override
  State<RentCarFormScreen> createState() => _RentCarFormScreenState();
}

class _RentCarFormScreenState extends State<RentCarFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _durationController = TextEditingController();
  DateTime? _selectedDate;
  File? _ktpImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _addressController.text = userData['address'] ?? '';
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickKtpImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _ktpImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadKtpImage() async {
    if (_ktpImage == null) return null;

    try {
      final cloudinary = CloudinaryPublic('dmhbguqqa', 'my_flutter_upload');
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(_ktpImage!.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah gambar KTP: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih tanggal pengambilan'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_ktpImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap unggah foto KTP'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User tidak ditemukan');

      final ktpImageUrl = await _uploadKtpImage();
      if (ktpImageUrl == null) {
        setState(() => _isLoading = false);
        return;
      }

      final duration = int.parse(_durationController.text);
      final totalPrice = widget.price * duration;
      final returnDate = _selectedDate!.add(Duration(days: duration));

      await FirebaseFirestore.instance.collection('rentals').add({
        'userId': user.uid,
        'userName': _nameController.text,
        'userEmail': _emailController.text,
        'userPhone': _phoneController.text,
        'userAddress': _addressController.text,
        'carId': widget.carId,
        'carName': widget.carName,
        'date': Timestamp.fromDate(_selectedDate!),
        'returnDate': Timestamp.fromDate(returnDate),
        'duration': duration,
        'totalPrice': totalPrice,
        'imageUrl': ktpImageUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permintaan penyewaan berhasil diajukan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengajukan penyewaan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime? returnDate;
    if (_selectedDate != null && int.tryParse(_durationController.text) != null) {
      returnDate = _selectedDate!.add(Duration(days: int.parse(_durationController.text)));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Pengajuan Sewa'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('cars').doc(widget.carId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data mobil tidak ditemukan.'));
          }
          final carData = snapshot.data!.data() as Map<String, dynamic>;
          final quantity = carData['quantity'] ?? 0;
          final isOutOfStock = quantity == 0;
          int duration = int.tryParse(_durationController.text) ?? 0;
          int totalPrice = widget.price * (duration > 0 ? duration : 0);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.carName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Harga per Hari: Rp ${widget.price.toString()}'),
                          const SizedBox(height: 8),
                          Text('Stok Tersisa: $quantity', style: TextStyle(color: isOutOfStock ? Colors.red : Colors.black)),
                          if (isOutOfStock)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text('Stok habis, tidak bisa disewa.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Setelah pengajuan disetujui, silakan datang ke lokasi rental untuk mengambil mobil. Terima kasih telah menggunakan layanan kami!',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!value.contains('@')) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor telepon tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Pengambilan',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedDate == null
                            ? 'Pilih Tanggal'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Durasi Sewa (hari)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Durasi tidak boleh kosong';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Durasi harus berupa angka lebih dari 0';
                      }
                      return null;
                    },
                    onChanged: (val) {
                      setState(() {}); // update total price & return date
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedDate != null && duration > 0)
                    Text('Tanggal Pengembalian: ${returnDate!.day}/${returnDate.month}/${returnDate.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Total Harga: Rp $totalPrice', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickKtpImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: _ktpImage != null
                            ? DecorationImage(
                                image: FileImage(_ktpImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _ktpImage == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap untuk unggah foto KTP'),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isOutOfStock || _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ajukan Sewa'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 