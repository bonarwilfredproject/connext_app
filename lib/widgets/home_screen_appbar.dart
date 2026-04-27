import 'package:connext_app/widgets/connext_app_bar.dart';
import 'package:flutter/material.dart';

class HomeScreenAppbar extends StatelessWidget implements PreferredSizeWidget {
  const HomeScreenAppbar({
    super.key,
    required this.title,
    this.child,
    this.onTap,
  });
  final Widget title;
  final Widget? child;
  final Function()? onTap;
  @override
  Widget build(BuildContext context) {
    return ConnextAppBar(
      variant: ConnextAppBarVariant.hero,
      title: Row(
        children: [
          Expanded(flex: 4, child: title),
          const SizedBox(width: 12),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF73E8D7), Color(0xFF00C2FF)],
                ),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                minRadius: 24,
                backgroundColor: const Color(0xFF171A33),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
