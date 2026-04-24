import 'package:connext_app/constants/app_theme.dart';
import 'package:flutter/material.dart';

enum ConnextAppBarVariant { minimal, hero }

class ConnextAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ConnextAppBar({
    super.key,
    this.variant = ConnextAppBarVariant.minimal,
    this.title,
    this.leading,
    this.onLeadingPressed,
    this.actions,
    this.centerTitle,
  });

  final ConnextAppBarVariant variant;
  final Widget? title;
  final Widget? leading;
  final VoidCallback? onLeadingPressed;
  final List<Widget>? actions;
  final bool? centerTitle;

  bool get _isHero => variant == ConnextAppBarVariant.hero;

  @override
  Widget build(BuildContext context) {
    final backgroundGradient = _isHero
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0D1F), Color(0xFF171A33), Color(0xFF23264D)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E1024), Color(0xFF171A33)],
          );

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle ?? !_isHero,
      titleSpacing: 16,
      leading:
          leading ??
          (onLeadingPressed != null
              ? IconButton(
                  onPressed: onLeadingPressed,
                  icon: const Icon(Icons.arrow_back, color: AppTheme.secondary),
                )
              : null),
      actions: actions,
      title: title,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: backgroundGradient)),
          if (_isHero)
            Positioned(
              right: -36,
              top: -36,
              child: IgnorePointer(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.third.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_isHero)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.third.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
