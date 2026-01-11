import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RgpdScreen extends StatelessWidget {
  const RgpdScreen({super.key});

  // ==========
  // ⚙️ À MODIFIER PLUS TARD (FAUSSES INFOS POUR L’INSTANT)
  // ==========
  static const String appName = "Meetly";
  static const String companyName = "MEETLY STUDIO (placeholder)";
  static const String legalForm = "SAS (placeholder)";
  static const String companyAddress =
      "10 Rue Exemple, 75000 Paris, France (placeholder)";
  static const String contactEmail = "privacy@meetly.app (placeholder)";
  static const String hostingCountry =
      "Union européenne / États-Unis (selon config)";

  // Cloudinary
  static const String cloudinaryProvider = "Cloudinary Ltd.";
  static const String cloudinaryPurpose =
      "Hébergement et optimisation des images (CDN, redimensionnement, performance).";

  // Firebase
  static const String firebaseProvider =
      "Google Firebase (Google Ireland Ltd.)";
  static const String firebasePurpose =
      "Authentification, base de données Firestore, stockage éventuel, notifications, logs techniques.";

  // ==========
  // Helpers
  // ==========
  Future<void> _openMail(String email) async {
    final uri = Uri.parse("mailto:$email");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Politique de confidentialité (RGPD)"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              _heroCard(isDark),
              const SizedBox(height: 14),
              _sectionTitle(context, "1) Qui sommes-nous ?"),
              _paragraph(context,
                  "$companyName, $legalForm, dont le siège social est situé $companyAddress, est responsable du traitement des données personnelles collectées via l’application $appName (ci-après « l’Application »)."),
              _paragraph(context, "Contact : $contactEmail"),
              _divider(),
              _sectionTitle(context, "2) Résumé (version simple)"),
              _bulletList(context, const [
                "Nous collectons uniquement ce qui est nécessaire pour créer un compte, afficher le feed, permettre les interactions (likes/commentaires), et les messages privés.",
                "Nous utilisons Firebase (auth + base de données) et Cloudinary (images).",
                "Tu peux accéder à tes données, les corriger, les supprimer, ou t’opposer à certains traitements.",
                "Tu peux retirer ton consentement (ex. notifications) à tout moment dans les réglages du téléphone.",
              ]),
              _divider(),
              _sectionTitle(context, "3) Quelles données sont collectées ?"),
              _subTitle(context, "A) Données fournies par l’utilisateur"),
              _bulletList(context, const [
                "Identité de compte : email, pseudo, photo de profil (si ajoutée).",
                "Contenu : posts (texte + images), commentaires, likes, signalements.",
                "Réseau : abonnements / abonnés (following/followers).",
                "Messages privés : contenu des messages envoyés via la messagerie interne.",
              ]),
              _subTitle(context, "B) Données techniques (automatiques)"),
              _bulletList(context, const [
                "Identifiants techniques : identifiant Firebase, token(s) FCM pour notifications.",
                "Logs et diagnostics : informations liées aux erreurs et à la performance (selon paramétrage).",
                "Métadonnées d’usage : interactions nécessaires au fonctionnement (ex. timestamps).",
              ]),
              _paragraph(context,
                  "⚠️ $appName ne collecte pas intentionnellement de données sensibles (santé, opinions politiques, religion, etc.). Si tu publies ce type d’information dans un post ou un message, tu la rends volontairement disponible selon tes réglages et actions."),
              _divider(),
              _sectionTitle(context,
                  "4) Pourquoi collectons-nous ces données ? (finalités)"),
              _bulletList(context, const [
                "Créer et gérer ton compte utilisateur.",
                "Afficher et gérer le feed (posts, commentaires, likes).",
                "Permettre les messages privés entre utilisateurs.",
                "Sécuriser l’Application (anti-abus, modération, signalements, blocage).",
                "Envoyer des notifications (messages privés, likes, commentaires, nouveaux followers) si tu les actives.",
                "Améliorer la stabilité et la performance (diagnostics techniques).",
              ]),
              _divider(),
              _sectionTitle(context, "5) Base légale (RGPD)"),
              _paragraph(
                  context, "Selon les traitements, nous nous appuyons sur :"),
              _bulletList(context, const [
                "L’exécution du contrat : fournir le service (compte, feed, messagerie).",
                "L’intérêt légitime : sécurité, prévention des abus, amélioration du service.",
                "Le consentement : notifications push (tu peux le retirer dans les réglages).",
                "L’obligation légale : conservation limitée en cas de litige, demandes légales, etc.",
              ]),
              _divider(),
              _sectionTitle(
                  context, "6) Avec qui partageons-nous tes données ?"),
              _paragraph(context,
                  "Nous ne vendons pas tes données personnelles. Certaines données peuvent être traitées par des prestataires techniques indispensables :"),
              _subTitle(context, "A) $firebaseProvider"),
              _paragraph(context, firebasePurpose),
              _subTitle(context, "B) $cloudinaryProvider"),
              _paragraph(context, cloudinaryPurpose),
              _paragraph(context,
                  "Ces prestataires peuvent traiter des données depuis $hostingCountry, selon leurs infrastructures et ta configuration. Nous utilisons des clauses contractuelles et mesures de sécurité standard du secteur lorsque cela s’applique."),
              const SizedBox(height: 10),
              _actionRow(
                context,
                label: "Documentation Firebase",
                onTap: () =>
                    _openUrl("https://firebase.google.com/support/privacy"),
              ),
              _actionRow(
                context,
                label: "Documentation Cloudinary (privacy)",
                onTap: () => _openUrl("https://cloudinary.com/privacy"),
              ),
              _divider(),
              _sectionTitle(
                  context, "7) Combien de temps conservons-nous tes données ?"),
              _bulletList(context, const [
                "Compte : tant que ton compte est actif (ou jusqu’à suppression).",
                "Posts / commentaires / likes : tant que tu ne les supprimes pas ou que ton compte est actif.",
                "Messages privés : conservés tant que la conversation existe (ou suppression/sanction/modération).",
                "Données techniques (logs) : durée limitée (ex. quelques jours à quelques mois selon paramétrage).",
                "Signalements et sécurité : conservation limitée selon nécessité (modération, litige).",
              ]),
              _paragraph(context,
                  "Note : certaines données peuvent persister un temps court dans des sauvegardes techniques (backup) avant purge complète."),
              _divider(),
              _sectionTitle(context, "8) Sécurité"),
              _bulletList(context, const [
                "Chiffrement en transit (HTTPS/TLS) pour les communications.",
                "Règles de sécurité Firebase (Firestore Rules) pour limiter l’accès aux données.",
                "Accès restreint aux environnements et aux consoles d’administration.",
                "Système de blocage utilisateur (feed/messages masqués selon logique de l’app).",
              ]),
              _paragraph(context,
                  "Aucune mesure n’est infaillible, mais nous appliquons des standards raisonnables pour protéger tes données."),
              _divider(),
              _sectionTitle(context, "9) Tes droits (RGPD)"),
              _bulletList(context, const [
                "Droit d’accès : obtenir une copie des données te concernant.",
                "Droit de rectification : corriger des informations inexactes.",
                "Droit d’effacement : demander la suppression de tes données (dans les limites légales).",
                "Droit d’opposition : t’opposer à certains traitements (intérêt légitime).",
                "Droit à la limitation : geler temporairement l’utilisation de certaines données.",
                "Droit à la portabilité : recevoir tes données dans un format exploitable (quand applicable).",
              ]),
              _paragraph(context,
                  "Pour exercer tes droits : contacte-nous à $contactEmail. Nous pouvons demander une preuve d’identité si nécessaire (uniquement pour éviter l’usurpation)."),
              const SizedBox(height: 8),
              _primaryButton(
                context,
                label: "Contacter le support RGPD",
                onTap: () => _openMail(contactEmail),
              ),
              _divider(),
              _sectionTitle(context, "10) Notifications (FCM)"),
              _paragraph(context,
                  "$appName peut envoyer des notifications (message privé, like, commentaire, follow). Elles reposent sur les services de notifications Firebase (FCM)."),
              _bulletList(context, const [
                "Tu peux désactiver les notifications à tout moment via les réglages du téléphone.",
                "Le token de notification (FCM token) est stocké pour t’envoyer les notifications demandées.",
              ]),
              _divider(),
              _sectionTitle(context, "11) Contenu publié et modération"),
              _paragraph(context,
                  "Si tu publies du contenu (post/commentaire/image), il peut être visible selon les paramètres de l’application. En cas de signalement, nous pouvons examiner le contenu pour modération."),
              _bulletList(context, const [
                "Nous pouvons retirer/masquer du contenu en cas d’abus.",
                "Nous pouvons restreindre des comptes (ex. blocage, suspension) en cas de violations.",
              ]),
              _divider(),
              _sectionTitle(context, "12) Mineurs"),
              _paragraph(context,
                  "$appName est destiné à un public de 13 ans et plus (placeholder). Si tu es mineur, tu dois avoir l’autorisation d’un parent/tuteur selon la législation de ton pays."),
              _paragraph(context,
                  "Si nous découvrons qu’un enfant nous a fourni des données personnelles sans autorisation, nous prendrons des mesures pour les supprimer."),
              _divider(),
              _sectionTitle(context, "13) Mise à jour de cette politique"),
              _paragraph(context,
                  "Cette politique peut être mise à jour. En cas de modification importante, nous pourrons t’en informer via l’application."),
              _paragraph(
                  context, "Dernière mise à jour : 09/01/2026 (placeholder)."),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "Merci d’utiliser $appName.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ==========
  // UI widgets
  // ==========
  Widget _heroCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.10)),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)]
              : [
                  Colors.black.withOpacity(0.04),
                  Colors.black.withOpacity(0.02)
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Cette page explique comment $appName collecte et utilise tes données personnelles, "
              "et comment tu peux exercer tes droits.",
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _subTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _paragraph(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
    );
  }

  Widget _bulletList(BuildContext context, List<String> items) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("•  "),
                    Expanded(
                      child: Text(
                        e,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: Colors.white.withOpacity(0.10), height: 1),
    );
  }

  Widget _primaryButton(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.mail_outline),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _actionRow(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.12)),
            color: theme.cardColor.withOpacity(0.25),
          ),
          child: Row(
            children: [
              const Icon(Icons.open_in_new, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
