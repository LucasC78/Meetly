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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ Recharge l’état du user pour être sûr d’avoir emailVerified à jour
      await credential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _errorMessage = "Erreur: utilisateur introuvable.";
          _isLoading = false;
        });
        return;
      }

      // ✅ Si email non vérifié => on bloque l’accès au Home
      if (!user.emailVerified) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/verify-email');
        return;
      }

      // ✅ OK => token + home
      await NotificationService.saveFcmToken();
      NotificationService.listenToTokenRefresh();

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
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

      if (!mounted) return;
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur inconnue : $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _errorMessage = null;
      _isGoogleLoading = true;
    });

    try {
      // ⚠️ Chez toi AuthService.signInWithGoogle() renvoie parfois UserCredential?
      // Ici on gère les 2 cas: UserCredential? ou User?
      final result = await _authService.signInWithGoogle();

      // ---- Normalisation ----
      User? user;
      if (result is UserCredential) {
        user = result.user;
      } else if (result is User) {
        user = result;
      }

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      if (user == null) {
        // utilisateur a annulé
        debugPrint("Connexion Google annulée par l'utilisateur.");
        return;
      }

      // ✅ Google = généralement déjà vérifié
      await user.reload();
      final current = FirebaseAuth.instance.currentUser;

      // ✅ token + home
      await NotificationService.saveFcmToken();
      NotificationService.listenToTokenRefresh();

      if (!mounted) return;

      // Si jamais un jour ce n'est pas vérifié (rare), on redirige quand même.
      if (current != null && !current.emailVerified) {
        Navigator.pushReplacementNamed(context, '/verify-email');
        return;
      }

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGoogleLoading = false;
        _errorMessage = "Erreur Google: $e";
      });
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
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
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
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: const Text(
                            'Connexion',
                            style: TextStyle(
                              fontSize: 18,
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
                            color: isDark ? Colors.black : Colors.white,
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
                                  color: isDark ? Colors.white : Colors.black,
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
