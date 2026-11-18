import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_ui.dart';

class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});

  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  final List<Map<String, String>> schools = [
    {
      "title": "Komarovi",
      "image": "assets/komarovi.jfif",
      "url": "https://komarovi.edu.ge/ge",
    },
    {
      "title": "Vekua",
      "image": "assets/vekua42_logo.jfif",
      "url": "https://www.vekua42.edu.ge/",
    },
    {
      "title": "Newton",
      "image": "assets/Logo-newton-5.png",
      "url": "https://newton.edu.ge/",
    },
    {
      "title": "BGA",
      "image": "assets/british_georgian_academy_logo.jfif",
      "url": "https://bga.ge/",
    },
    {
      "title": "European School",
      "image": "assets/europeanschoollogo.png",
      "url": "https://europeanschool.ge/",
    },
    {
      "title": "New School",
      "image": "assets/newschool.png",
      "url": "https://newschoolgeorgia.com/",
    },
    {
      "title": "GAST",
      "image": "assets/georgian american school.jpg",
      "url": "https://gast.edu.ge/",
    },
    {
      "title": "QSI",
      "image": "assets/qsi.jpg",
      "url": "https://tbilisi.qsi.org/",
    },
  ];

  Future<void> launchWebsite(String link) async {
    try {
      final opened = await launchUrl(Uri.parse(link),
          mode: LaunchMode.externalApplication);
      if (opened) return;
    } catch (_) {
      // A device can decline the URL or have no browser available.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Couldn’t open this school’s website. Please try again.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('assets/opportunet1.png',
            height: 55, semanticLabel: 'OpportuNet'),
      ),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          maxWidth: 800,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [brandBlue, Color(0xffb6ebff)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.school_outlined, color: brandInk, size: 32),
                      SizedBox(height: 14),
                      Text('Best Schools in Georgia',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: brandInk)),
                      SizedBox(height: 8),
                      Text(
                        'Explore schools in the country of Georgia and visit their official websites to learn more.',
                        style: TextStyle(
                            fontSize: 14, height: 1.5, color: brandInk),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(builder: (context, constraints) {
                  final textScale =
                      MediaQuery.textScalerOf(context).scale(16) / 16;
                  final minCardWidth = 240 * textScale.clamp(1.0, 1.5);
                  final columns =
                      ((constraints.maxWidth + 14) / (minCardWidth + 14))
                          .floor()
                          .clamp(1, 2);
                  final cardWidth =
                      (constraints.maxWidth - 14 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: schools
                        .map((school) => SizedBox(
                            width: cardWidth, child: _schoolCard(school)))
                        .toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _schoolCard(Map<String, String> school) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.cardColor,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(school['image']!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true),
            ),
            const SizedBox(height: 16),
            Text(school['title']!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => launchWebsite(school['url']!),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  backgroundColor: brandBlue,
                  foregroundColor: brandInk,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text('Visit website',
                    textAlign: TextAlign.center,
                    semanticsLabel: 'Visit ${school['title']} website'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
