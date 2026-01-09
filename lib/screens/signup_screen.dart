import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Meetly/config/theme.dart';
import 'package:Meetly/services/auth_service.dart';
import 'package:Meetly/services/notification_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
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

  // ✅ RGPD checkbox
  bool _acceptedRgpd = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pseudoController.dispose();
    super.dispose();
  }

  void _showRgpdRequiredSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Tu dois accepter les règles RGPD pour créer un compte."),
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    if (value.length < 12) {
      return 'Le mot de passe doit contenir au moins 12 caractères.';
    }

    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialChar =
        RegExp(r'[!@#\$&*~%^()_+=\[\]{};:"\\|,.<>/?-]').hasMatch(value);

    if (!hasNumber) {
      return 'Le mot de passe doit contenir au moins un chiffre.';
    }
    if (!hasSpecialChar) {
      return 'Le mot de passe doit contenir au moins un caractère spécial.';
    }
    return null;
  }

  Future<void> _signUp() async {
    if (!_acceptedRgpd) {
      _showRgpdRequiredSnack();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final pseudo = _pseudoController.text.trim();

      UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'rgpdAccepted': true,
        'rgpdAcceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      await NotificationService.saveFcmToken();
      NotificationService.listenToTokenRefresh();
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_acceptedRgpd) {
      _showRgpdRequiredSnack();
      return;
    }

    setState(() => _isGoogleLoading = true);

    final UserCredential? credential = await _authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    // ✅ EXTRACTION DU User
    final User? user = credential?.user;

    if (user == null) return;

    // ✅ RGPD Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'rgpdAccepted': true,
      'rgpdAcceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    await NotificationService.saveFcmToken();
    NotificationService.listenToTokenRefresh();
    Navigator.pushReplacementNamed(context, '/home');
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
                          offset: const Offset(0, 0),
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

                  const SizedBox(height: 18),

                  // ✅ RGPD checkbox + lien cliquable
                  _buildRgpdRow(theme, isDark),

                  const SizedBox(height: 16),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : _buildGradientButton(
                          label: 'S\'inscrire',
                          onPressed: _signUp,
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
                          child: Opacity(
                            opacity: _acceptedRgpd ? 1 : 0.55,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.2),
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
                        ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
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

  Widget _buildRgpdRow(ThemeData theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _acceptedRgpd,
          onChanged: (v) => setState(() => _acceptedRgpd = v ?? false),
          activeColor: isDark ? darkAccent1 : lightAccent1,
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text("J'accepte la ", style: theme.textTheme.bodyMedium),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/rgpd'),
                child: Text(
                  "politique RGPD",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? darkAccent1 : lightAccent1,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(".", style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
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
