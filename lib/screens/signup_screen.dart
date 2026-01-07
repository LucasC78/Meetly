import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Meetly/config/theme.dart';
import 'package:Meetly/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pseudoController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isGoogleLoading = false;
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
          'email': _emailController.text.trim(),
          'pseudo': _pseudoController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte créé avec succès')),
        );

        Navigator.pushNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    final user = await _authService.signInWithGoogle();

    setState(() {
      _isGoogleLoading = false;
    });

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Ne rien faire : l'utilisateur a juste annulé
      debugPrint("Connexion Google annulée par l'utilisateur.");
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }

    if (value.length < 12) {
      return 'Le mot de passe doit contenir au moins 12 caractères.';
    }

    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialChar = RegExp(
      r'[!@#\$&*~%^()_+=\[\]{};:"\\|,.<>/?-]',
    ).hasMatch(value);

    if (!hasNumber) {
      return 'Le mot de passe doit contenir au moins un chiffre.';
    }

    if (!hasSpecialChar) {
      return 'Le mot de passe doit contenir au moins un caractère spécial.';
    }

    return null; // ✅ Valide
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [darkBackground, darkAccent3],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [lightBackground, lightAccent3],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'Créer Ton Compte',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: isDark ? darkAccent1 : lightAccent1,
                      shadows: [
                        Shadow(
                          blurRadius: 20,
                          color: isDark ? darkAccent1 : lightAccent1,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildInputField('Pseudo', _pseudoController),
                  const SizedBox(height: 16),
                  _buildInputField('Email', _emailController),
                  const SizedBox(height: 16),
                  _buildInputField(
                    'Mot de Passe',
                    _passwordController,
                    obscure: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    'Confirmer (Mot de passe)',
                    _confirmPasswordController,
                    obscure: true,
                    validator: (value) => value != _passwordController.text
                        ? 'Les mots de passe ne correspondent pas'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : _buildGradientButton(
                          label: 'S\'inscrire',
                          onPressed: () {
                            if (_formKey.currentState!.validate()) _signUp();
                          },
                        ),
                  const SizedBox(height: 20),
                  Text(
                    'OU CONTINUER AVEC',
                    style: theme.textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isGoogleLoading
                      ? const CircularProgressIndicator()
                      : GestureDetector(
                          onTap: _signInWithGoogle,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.2,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/google-icon.png',
                                  height: 30,
                                  width: 30,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Connectez-vous avec Google',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      "Vous avez déjà un compte ? Se connecter",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? darkAccent1 : lightAccent1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String hint,
    TextEditingController controller, {
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(hintText: hint),
      validator: validator ?? (value) => value!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark ? darkButtonGradient : lightButtonGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? darkGlowShadow : lightSoftShadow,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
