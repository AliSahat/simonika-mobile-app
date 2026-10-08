import 'package:flutter/material.dart';

/// A local Google brand asset keeps the sign-in action recognizable offline.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final inactive = onPressed == null && !isLoading;

    // Google's prescribed light/dark brand colors, independent of app accents.
    final foreground =
        dark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F);
    final background = dark ? const Color(0xFF131314) : Colors.white;
    final border = dark ? const Color(0xFF8E918F) : const Color(0xFF747775);

    return Semantics(
      liveRegion: isLoading,
      value: isLoading ? 'Sedang masuk dengan Google' : null,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor:
              isLoading ? background : colors.surfaceContainerHighest,
          disabledForegroundColor:
              isLoading ? foreground : colors.onSurface.withValues(alpha: 0.38),
          overlayColor: foreground,
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          animationDuration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 180),
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: colors.primary, width: 2);
            }
            return BorderSide(
                color: inactive ? colors.outlineVariant : border);
          }),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 32,
              child: isLoading
                  ? Center(
                      child: ExcludeSemantics(
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            value: reducedMotion ? 0.75 : null,
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    )
                  : Opacity(
                      opacity: inactive ? 0.5 : 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: dark
                                ? Colors.transparent
                                : const Color(0xFFE3E3E3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            'assets/branding/google_g.png',
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Lanjutkan dengan Google',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Mirrors the logo slot so the label is optically centered.
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}
