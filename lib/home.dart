import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart'; // Import halaman login

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  int _currentIndex = 0; // Untuk mengatur halaman yang sedang aktif

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await supabase.from('produk').select();
      setState(() {
        products = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      _showError('Terjadi kesalahan saat mengambil data: $e');
    }
  }

  Future<void> _addProduct(String namaProduk, double harga, int stok) async {
    try {
      final response = await supabase.from('produk').insert({
        'nama_produk': namaProduk,
        'harga': harga,
        'stok': stok,
      }).select();

      if (response != null && response.isNotEmpty) {
        setState(() {
          products.add(response.first);
        });
      }
    } catch (e) {
      _showError('Gagal menambahkan produk: $e');
    }
  }

  Future<void> _editProduct(int id, String namaProduk, double harga, int stok) async {
    try {
      final response = await supabase.from('produk').update({
        'nama_produk': namaProduk,
        'harga': harga,
        'stok': stok,
      }).eq('produk_id', id).select();

      if (response != null && response.isNotEmpty) {
        setState(() {
          final index = products.indexWhere((product) => product['produk_id'] == id);
          if (index != -1) {
            products[index] = response.first;
          }
        });
      }
    } catch (e) {
      _showError('Gagal mengedit produk: $e');
    }
  }

  Future<void> _deleteProduct(int id) async {
    try {
      await supabase.from('produk').delete().eq('produk_id', id);
      setState(() {
        products.removeWhere((product) => product['produk_id'] == id);
      });
    } catch (e) {
      _showError('Gagal menghapus produk: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddProductDialog() {
    final TextEditingController namaProdukController = TextEditingController();
    final TextEditingController hargaController = TextEditingController();
    final TextEditingController stokController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Produk'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaProdukController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
              ),
              TextField(
                controller: hargaController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stokController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final String namaProduk = namaProdukController.text;
                final double harga = double.tryParse(hargaController.text) ?? 0.0;
                final int stok = int.tryParse(stokController.text) ?? 0;

                if (namaProduk.isNotEmpty && harga > 0 && stok >= 0) {
                  _addProduct(namaProduk, harga, stok);
                  Navigator.of(context).pop();
                } else {
                  _showError('Mohon isi data dengan benar.');
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final TextEditingController namaProdukController = TextEditingController(text: product['nama_produk']);
    final TextEditingController hargaController = TextEditingController(text: product['harga'].toString());
    final TextEditingController stokController = TextEditingController(text: product['stok'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Produk'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaProdukController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
              ),
              TextField(
                controller: hargaController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stokController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final String namaProduk = namaProdukController.text;
                final double harga = double.tryParse(hargaController.text) ?? 0.0;
                final int stok = int.tryParse(stokController.text) ?? 0;

                if (namaProduk.isNotEmpty && harga > 0 && stok >= 0) {
                  _editProduct(product['produk_id'], namaProduk, harga, stok);
                  Navigator.of(context).pop();
                } else {
                  _showError('Mohon isi data dengan benar.');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomePage() {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : products.isEmpty
            ? const Center(
                child: Text(
                  'Tidak ada produk!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(
                        product['nama_produk'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga: Rp${product['harga']}',
                            style: const TextStyle(color: Colors.green),
                          ),
                          Text('Stok: ${product['stok']}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditProductDialog(product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(product['produk_id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
  }

  Widget _buildPaymentPage() {
    return const Center(
      child: Text(
        'Halaman Pembayaran',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProfilePage() {
    return const Center(
      child: Text(
        'Halaman Profile',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kasir Warteg",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 79, 186),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(),
          _buildPaymentPage(),
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Pembayaran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
