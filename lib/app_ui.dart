import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';

export 'l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Community post categories are stored in English; this only changes the label.
String postCategoryLabel(BuildContext context, String name) =>
    switch (name.toLowerCase()) {
      "all" => context.l10n.all,
      "math" => context.l10n.catMath,
      "coding" => context.l10n.catCoding,
      "arts" => context.l10n.catArts,
      "languages" => context.l10n.catLanguages,
      "career" => context.l10n.catCareer,
      "general" => context.l10n.catGeneral,
      _ => name,
    };

const brandBlue = Color(0xff84d6fe);
const brandInk = Color(0xff17394e);
// Icon/accent blue. Use brandInk or colorScheme roles for text: brandBlue is too
// light to read as text on white.
const brandBlueDark = Color(0xff2b88b4);

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff17658b),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        dark ? const Color(0xff12171c) : const Color(0xfff4f9fc),
    appBarTheme: AppBarTheme(backgroundColor: scheme.surface),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandBlue,
        foregroundColor: brandInk,
        minimumSize: const Size(48, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brandBlue,
      foregroundColor: brandInk,
    ),
  );
}

class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ContentWidth({super.key, required this.child, this.maxWidth = 1100});
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(width: double.infinity, child: child),
        ),
      );
}

class BusyIndicator extends StatelessWidget {
  const BusyIndicator({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: brandInk),
      );
}

class LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const LoadError({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
}

class AppLogo extends StatelessWidget {
  final double height;
  const AppLogo({super.key, this.height = 55});
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/opportunet1.png',
        height: height,
        fit: BoxFit.contain,
        semanticLabel: 'OpportuNet',
      );
}
