import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fouralot/l10n/app_localizations.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<StatefulWidget> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  String _markdownContent = '';

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.infoTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.bugRequestTitle,
                  style: const TextStyle(
                      fontSize: 20.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.joinDiscordTitle,
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () =>
                    _openDiscord(context),
                  child: Image.asset('assets/icons/discord.png', height: 150),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.sendEmailTitle,
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _sendEmail(context),
                  child: Text(
                    l10n.supportEmail,
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.privacyTitle,
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: MarkdownBody(
                    data: _markdownContent,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white70, height: 1.4),
                      h1: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      h2: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      h3: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      listBullet: const TextStyle(color: Colors.white70),
                      a: const TextStyle(color: Color(0xFF4ECDC4)),
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

  Future<void> _loadMarkdown() async {
    final String policyPath = Platform.localeName.contains('it')
        ? 'assets/privacy/privacy_it.md'
        : 'assets/privacy/privacy_en.md';
    final String content = await rootBundle.loadString(policyPath);
    if (!mounted) {
      return;
    }
    setState(() {
      _markdownContent = content;
    });
  }

  Future<void> _openDiscord(BuildContext context) async {
    final l10n = context.l10n;
    final Uri url = Uri.parse(l10n.discordUrl);
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showError(context, l10n.urlError(url.toString()));
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final l10n = context.l10n;
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: l10n.supportEmail,
      queryParameters: {'subject': l10n.supportSubject},
    );
    final ok = await launchUrl(emailUri);
    if (!ok && context.mounted) {
      _showError(context, l10n.urlError(l10n.supportEmail));
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
