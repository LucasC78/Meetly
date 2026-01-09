import 'package:flutter/material.dart';

class RgpdScreen extends StatelessWidget {
  const RgpdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("RGPD"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            // ✅ Mets ici tes règles RGPD
            "Politique RGPD\n\n"
            "1) Données collectées : email, pseudo, photo de profil...\n"
            "2) Finalité : permettre la création de compte, l'utilisation de l'app...\n"
            "3) Conservation : tant que le compte est actif.\n"
            "4) Droits : accès, rectification, suppression.\n"
            "5) Contact : support@tondomaine.com\n\n"
            "En utilisant Meetly, vous acceptez cette politique.",
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
