import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'profile.dart';
import 'transaksi.dart'; // Halaman Transaksi
import 'pelanggan.dart'; // Halaman Pelanggan
import 'registrasi.dart'; // Halaman Registrasi
import 'riwayat.dart'; // Halaman Riwayat

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  String _userRole = '';
  

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _fetchProducts();
  }

  Future<void> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? '';
    });
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

  Future<void> _editProduct(
      int id, String namaProduk, double harga, int stok) async {
    try {
      final response = await supabase
          .from('produk')
          .update({
            'nama_produk': namaProduk,
            'harga': harga,
            'stok': stok,
          })
          .eq('produk_id', id)
          .select();

      if (response != null && response.isNotEmpty) {
        setState(() {
          final index =
              products.indexWhere((product) => product['produk_id'] == id);
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

  void _showDeleteConfirmation(int id, String namaProduk) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content:
              Text('Apakah Anda yakin ingin menghapus produk "$namaProduk"?'),
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
                _deleteProduct(id);
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddProductDialog({Map<String, dynamic>? product}) {
    final _formKey = GlobalKey<FormState>();

    final TextEditingController namaProdukController = TextEditingController(
      text: product != null ? product['nama_produk'] : '',
    );
    final TextEditingController hargaController = TextEditingController(
      text: product != null ? product['harga'].toString() : '',
    );
    final TextEditingController stokController = TextEditingController(
      text: product != null ? product['stok'].toString() : '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaProdukController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (value) =>
                      value!.isEmpty ? 'Nama produk tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: hargaController,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Harga tidak boleh kosong';
                    return double.tryParse(value) == null
                        ? 'Masukkan harga dengan benar'
                        : null;
                  },
                ),
                TextFormField(
                  controller: stokController,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Stok tidak boleh kosong';
                    return int.tryParse(value) == null
                        ? 'Masukkan stok dengan benar'
                        : null;
                  },
                ),
              ],
            ),
          ),
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
                if (_formKey.currentState!.validate()) {
                  final String namaProduk = namaProdukController.text;
                  final double harga = double.parse(hargaController.text);
                  final int stok = int.parse(stokController.text);

                  if (product == null) {
                    _addProduct(namaProduk, harga, stok);
                  } else {
                    _editProduct(product['produk_id'], namaProduk, harga, stok);
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

  Widget _buildProdukPage() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
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
                            onPressed: () =>
                                _showAddProductDialog(product: product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(
                              product['produk_id'],
                              product['nama_produk'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
  }
 

    List<BottomNavigationBarItem> _getBottomNavItems() {
      if (_userRole == 'Admin') {
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_shopping_cart),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Pelanggan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration),
            label: 'Registrasi',
          ),
        ];
      } else if (_userRole == 'Petugas') {
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_shopping_cart),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
        ];
      }
      return []; // Kembalikan list kosong jika role tidak dikenali
    }

    // Tentukan halaman yang ditampilkan berdasarkan role
    List<Widget> _getPages() {
      if (_userRole == 'Admin') {
        return [
          _buildProdukPage(),
          const TransaksiPage(),
          const RiwayatPage(),
          const PelangganScreen(),
          const RegistrasiPage(),
        ];
      } else if (_userRole == 'Petugas') {
        return [
          const TransaksiPage(),
          const RiwayatPage(),
        ];
      }
      return []; // Kembalikan list kosong jika role tidak dikenali
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
            icon: const Icon(Icons.account_circle),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _getPages(), // Gunakan metode _getPages()
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
        backgroundColor: const Color.fromARGB(255, 7, 80, 190),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: _getBottomNavItems(), // Gunakan metode _getBottomNavItems()
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddProductDialog(),
              child: const Icon(Icons.add, color: Colors.white),
              backgroundColor: const Color.fromARGB(255, 7, 79, 186),
            )
          : null,
    );
  }
}