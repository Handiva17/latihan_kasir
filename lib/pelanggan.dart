import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PelangganScreen extends StatefulWidget {
  const PelangganScreen({Key? key}) : super(key: key);

  @override
  State<PelangganScreen> createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pelanggan = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPelanggan();
  }

  Future<void> _fetchPelanggan() async {
    try {
      final response = await supabase.from('pelanggan').select();
      setState(() {
        pelanggan = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      _showError('Terjadi kesalahan saat mengambil data pelanggan: $e');
    }
  }

  Future<void> _addPelanggan(String nama, String alamat, String nomorTelepon) async {
    try {
      final response = await supabase.from('pelanggan').insert({
        'nama_pelanggan': nama,
        'alamat': alamat,
        'nomor_telepon': nomorTelepon,
      }).select();

      if (response != null && response.isNotEmpty) {
        setState(() {
          pelanggan.add(response.first);
        });
      }
    } catch (e) {
      _showError('Gagal menambahkan pelanggan: $e');
    }
  }

  Future<void> _editPelanggan(int id, String nama, String alamat, String nomorTelepon) async {
    try {
      final response = await supabase.from('pelanggan').update({
        'nama_pelanggan': nama,
        'alamat': alamat,
        'nomor_telepon': nomorTelepon,
      }).eq('pelanggan_id', id).select();

      if (response != null && response.isNotEmpty) {
        setState(() {
          final index = pelanggan.indexWhere((item) => item['pelanggan_id'] == id);
          if (index != -1) {
            pelanggan[index] = response.first;
          }
        });
      }
    } catch (e) {
      _showError('Gagal mengedit pelanggan: $e');
    }
  }

  Future<void> _deletePelanggan(int id) async {
    try {
      await supabase.from('pelanggan').delete().eq('pelanggan_id', id);
      setState(() {
        pelanggan.removeWhere((item) => item['pelanggan_id'] == id);
      });
    } catch (e) {
      _showError('Gagal menghapus pelanggan: $e');
    }
  }

  void _showDeleteConfirmation(int id, String namaPelanggan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus pelanggan "$namaPelanggan"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
              style: TextButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 177, 255),
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                _deletePelanggan(id);
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddPelangganDialog({Map<String, dynamic>? pelangganData}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController namaController = TextEditingController(
        text: pelangganData != null ? pelangganData['nama_pelanggan'] : '');
    final TextEditingController alamatController = TextEditingController(
        text: pelangganData != null ? pelangganData['alamat'] : '');
    final TextEditingController nomorTeleponController = TextEditingController(
        text: pelangganData != null ? pelangganData['nomor_telepon'] : '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(pelangganData == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                  validator: (value) =>
                      value!.isEmpty ? 'Nama pelanggan tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: alamatController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  validator: (value) =>
                      value!.isEmpty ? 'Alamat tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: nomorTeleponController,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value!.isEmpty) return 'Nomor telepon tidak boleh kosong';
                    return RegExp(r'^\d+$').hasMatch(value)
                        ? null
                        : 'Masukkan nomor telepon yang benar';
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
              style: TextButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 81, 177, 255),
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final String nama = namaController.text;
                  final String alamat = alamatController.text;
                  final String nomorTelepon = nomorTeleponController.text;

                  if (pelangganData == null) {
                    _addPelanggan(nama, alamat, nomorTelepon);
                  } else {
                    _editPelanggan(
                        pelangganData['pelanggan_id'], nama, alamat, nomorTelepon);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Simpan'),
              style: TextButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 33, 114, 243),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pelanggan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : pelanggan.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada pelanggan!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pelanggan.length,
                  itemBuilder: (context, index) {
                    final item = pelanggan[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(
                          item['nama_pelanggan'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alamat: ${item['alamat']}'),
                            Text('Nomor Telepon: ${item['nomor_telepon']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showAddPelangganDialog(pelangganData: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(
                                item['pelanggan_id'],
                                item['nama_pelanggan'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPelangganDialog(),
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 7, 79, 186),
      ),
    );
  }
}
