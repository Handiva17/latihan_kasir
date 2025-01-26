import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart'; // Import halaman home

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Key untuk form validation
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Untuk mengontrol visibilitas password
  bool _isLoading = false; // Untuk mengontrol loading state

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      // Jika form tidak valid, hentikan proses login
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String username = nameController.text.trim();
    final String password = passwordController.text.trim();

    try {
      // Query ke Supabase untuk validasi user
      final response = await supabase
          .from('user')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        // Login berhasil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Login gagal
        _showError('Username atau password salah, harap isi dengan benar.');
      }
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400, // Membatasi lebar container pada desktop
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 223, 239, 255),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          'Login',
                          style: TextStyle(
                            color: Color(0xff1F509A),
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 33, 58, 243),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 0, 19, 114),
                                width: 1,
                              ),
                            ),
                            labelText: 'User Name',
                            labelStyle: TextStyle(
                                color: const Color.fromARGB(255, 9, 0, 78)),
                            prefixIcon: const Icon(Icons.person),
                            prefixIconColor: const Color.fromARGB(255, 0, 2, 135),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Username tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: passwordController,
                          obscureText:
                              !_isPasswordVisible, // Mengontrol visibilitas password
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 33, 58, 243),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 0, 19, 114),
                                width: 1,
                              ),
                            ),
                            labelText: 'Password',
                            labelStyle: TextStyle(
                                color: const Color.fromARGB(255, 9, 0, 78)),
                            prefixIcon: const Icon(Icons.lock),
                            prefixIconColor: const Color.fromARGB(255, 0, 2, 135),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: _isPasswordVisible
                                    ? const Color.fromARGB(255, 81, 69, 255)
                                    : const Color.fromARGB(255, 0, 6, 84),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password tidak boleh kosong';
                            }
                            if (value.length < 1) {
                              return 'Password tidak sesuai';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Color(0xff0A3981),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white, // Warna latar belakang
    );
  }
}
