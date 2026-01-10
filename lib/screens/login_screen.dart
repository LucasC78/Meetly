import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Meetly/services/auth_service.dart';
import 'package:Meetly/config/theme.dart';
import 'package:Meetly/services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _errorMessage;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus(); // Fermer le clavier
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Si connexion réussie
      await NotificationService.saveFcmToken();
      NotificationService.listenToTokenRefresh();
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      print('Firebase Error Code: ${e.code}');
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun utilisateur trouvé avec cet email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Mot de passe incorrect. Veuillez réessayer.';
          break;
        case 'invalid-email':
          message = 'Adresse email invalide.';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé.';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Réessayez plus tard.';
          break;
        case 'network-request-failed':
          message = 'Problème de connexion Internet.';
          break;
        default:
          message = 'Une erreur est survenue.';
          break;
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false; // 👈 Reviens à l’état normal en cas d’erreur
      });
    } catch (e) {
      // Pour toutes les autres erreurs
      setState(() {
        _errorMessage = 'Erreur inconnue : $e';
        _isLoading = false; // 👈 Ici aussi
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _errorMessage = null;
      _isGoogleLoading = true;
    });

    final user = await _authService.signInWithGoogle();

    setState(() {
      _isGoogleLoading = false;
    });

    if (user != null) {
      await NotificationService.saveFcmToken();
      NotificationService.listenToTokenRefresh();
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Ne rien faire : l'utilisateur a juste annulé
      debugPrint("Connexion Google annulée par l'utilisateur.");
    }
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
            child: Column(
              children: [
                Text(
                  'Se Connecter',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                    shadows: [
                      Shadow(
                        color: theme.colorScheme.secondary.withOpacity(0.6),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildInputField('Email', _emailController, theme),
                const SizedBox(height: 20),
                _buildInputField(
                  'Mot de passe',
                  _passwordController,
                  theme,
                  obscure: true,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft, // 👈 aligne à gauche
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: Text(
                      'Mot de passe oublié ?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _isLoading
                    ? const CircularProgressIndicator()
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient:
                              isDark ? darkButtonGradient : lightButtonGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isDark ? darkGlowShadow : lightSoftShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                            ), // ↑ hauteur
                          ),
                          child: const Text(
                            'Connexion',
                            style: TextStyle(
                              fontSize:
                                  18, // 👈 ajuste ici (16–20 pour un bon impact visuel)
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                            color: isDark
                                ? Colors.black
                                : Colors.white, // ✅ light/dark
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.12),
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                            ],
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
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black, // ✅ texte lisible
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: Text(
                    "Vous n'avez pas de compte ? S'inscrire",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String hint,
    TextEditingController controller,
    ThemeData theme, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(hintText: hint),
    );
  }
}
