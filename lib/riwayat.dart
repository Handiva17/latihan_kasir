import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RiwayatPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const RiwayatPage({Key? key, this.onRefresh}) : super(key: key);

  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _transactionHistory = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchTransactionHistory(); // Panggil data saat halaman aktif
  }

  Future<void> _fetchTransactionHistory() async {
    try {
      final response = await _supabase.from('penjualan').select('''
        penjualan_id,
        tanggal_penjualan,
        total_harga,
        pelanggan_id,
        detail_penjualan (
          produk_id,
          jumlah_produk,
          subtotal,
          produk (nama_produk, harga)
        )
      ''').order('tanggal_penjualan', ascending: false); // Sort by date descending
      setState(() {
        _transactionHistory =
            List<Map<String, dynamic>>.from(response as List<dynamic>);
      });
    } catch (error) {
      debugPrint('Error fetching transaction history: $error');
    }
  }

  String _formatDateTime(String dateTime) {
    final date = DateTime.parse(dateTime);
    return DateFormat('dd MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: _transactionHistory.isEmpty
          ? const Center(
              child: Text('Belum ada riwayat transaksi.'),
            )
          : ListView.builder(
              itemCount: _transactionHistory.length,
              itemBuilder: (context, index) {
                final transaction = _transactionHistory[index];
                final formattedDate =
                    _formatDateTime(transaction['tanggal_penjualan']);
                final detailPenjualan = List<Map<String, dynamic>>.from(
                    transaction['detail_penjualan'] as List<dynamic>);

                final totalHarga = transaction['total_harga'];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ExpansionTile(
                    title: Text('Transaksi #${_transactionHistory.length - index}'), // Urutkan transaksi
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tanggal: $formattedDate'),
                        Text('Total: Rp $totalHarga'),
                        if (transaction['pelanggan_id'] != null)
                          const Text('Diskon: Rp 1000 (Diskon Pelanggan)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic)),
                      ],
                    ),
                    children: detailPenjualan.map((detail) {
                      return ListTile(
                        title: Text(detail['produk']['nama_produk']),
                        subtitle: Text(
                            'Jumlah: ${detail['jumlah_produk']} | Subtotal: Rp ${detail['subtotal']}'),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}