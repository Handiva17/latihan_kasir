import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({Key? key}) : super(key: key);

  @override
  _TransaksiPageState createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _transactionHistory = [];
  String? _selectedCustomer;
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCustomers();
    _fetchTransactionHistory();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await _supabase.from('produk').select();
      setState(() {
        _products = List<Map<String, dynamic>>.from(response as List<dynamic>);
      });
    } catch (error) {
      debugPrint('Error fetching products: $error');
    }
  }

  Future<void> _fetchCustomers() async {
    try {
      final response = await _supabase.from('pelanggan').select();
      setState(() {
        _customers = List<Map<String, dynamic>>.from(response as List<dynamic>);
      });
    } catch (error) {
      debugPrint('Error fetching customers: $error');
    }
  }

  Future<void> _fetchTransactionHistory() async {
    try {
      final response = await _supabase.from('penjualan').select(
          'penjualan_id, tanggal_penjualan, total_harga, pelanggan_id');
      setState(() {
        _transactionHistory = List<Map<String, dynamic>>.from(
            response as List<dynamic>);
      });
    } catch (error) {
      debugPrint('Error fetching transaction history: $error');
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      _cart.add({...product, 'quantity': 1});
      _calculateTotal();
    });
  }

  void _updateCart(Map<String, dynamic> product, int quantity) {
    setState(() {
      final index =
          _cart.indexWhere((item) => item['produk_id'] == product['produk_id']);
      if (index != -1) {
        if (quantity > 0) {
          _cart[index]['quantity'] = quantity;
        } else {
          _cart.removeAt(index);
        }
      }
      _calculateTotal();
    });
  }


  void _calculateTotal() {
    double total = _cart.fold(
      0,
      (sum, item) => sum + (item['harga'] * item['quantity']),
    );
    if (_selectedCustomer != null && _selectedCustomer != 'pelanggan biasa') {
      total -= 1000; // Diskon Rp 1000
    }
    setState(() {
      _totalPrice = total;
    });
  }




  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    try {
      final response = await _supabase.from('penjualan').insert({
        'tanggal_penjualan': DateTime.now().toIso8601String(),
        'total_harga': _totalPrice,
        'pelanggan_id': _selectedCustomer == 'pelanggan biasa'
            ? null
            : int.parse(_selectedCustomer!),
      }).select();
      final penjualanId = response[0]['penjualan_id'];

      for (final item in _cart) {
        await _supabase.from('detail_penjualan').insert({
          'penjualan_id': penjualanId,
          'produk_id': item['produk_id'],
          'jumlah_produk': item['quantity'],
          'subtotal': item['harga'] * item['quantity'],
        });
      }

      setState(() {
        _cart.clear();
        _selectedCustomer = null;
        _totalPrice = 0;
      });

      // Refresh transaction history
      await _fetchTransactionHistory();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil!')));
    } catch (error) {
      debugPrint('Error during checkout: $error');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat transaksi.')));
    }
  }

  String _formatDateTime(String dateTime) {
    final date = DateTime.parse(dateTime);
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Widget _buildProductList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(product['nama_produk'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Harga: ${product['harga']}'),
            trailing: ElevatedButton(
              onPressed: () => _addToCart(product),
              child: const Text('Tambah'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCart() {
    return Column(
      children: [
        ..._cart.map((item) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(item['nama_produk']),
              subtitle:
                  Text('Harga: ${item['harga']} x ${item['quantity']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _updateCart(item, item['quantity'] - 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _updateCart(item, item['quantity'] + 1),
                  ),
                ],
              ),
            ),
          );
        }),
        ListTile(
          title: const Text('Total Harga',
              style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(_totalPrice.toStringAsFixed(2)),
        ),
        ElevatedButton(
          onPressed: _checkout,
          child: const Text('Bayar'),
        ),
      ],
    );
  }

  Widget _buildTransactionHistory() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Riwayat Transaksi',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      ..._transactionHistory.map((transaction) {
        // Format hanya tanggal tanpa jam
        final formattedDate = DateFormat('dd MMMM yyyy').format(
          DateTime.parse(transaction['tanggal_penjualan']),
        );

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text('Transaksi #${transaction['penjualan_id']}'),
            subtitle: Text('Tanggal: $formattedDate'),
            trailing: Text('Total: Rp ${transaction['total_harga']}'),
          ),
        );
      }),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: _selectedCustomer,
                hint: const Text('Pilih Pelanggan'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: 'pelanggan biasa',
                    child: Text('Pelanggan Biasa'),
                  ),
                  ..._customers.map((customer) {
                    return DropdownMenuItem(
                      value: customer['pelanggan_id'].toString(),
                      child: Text(customer['nama_pelanggan']),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCustomer = value;
                    _calculateTotal();
                  });
                },
              ),
            ),
            const Divider(),
            const Text(
              'Daftar Produk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            _buildProductList(),
            const Divider(),
            const Text(
              'Keranjang Belanja',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            _buildCart(),
            const Divider(),
            _buildTransactionHistory(),
          ],
        ),
      ),
    );
  }
}
