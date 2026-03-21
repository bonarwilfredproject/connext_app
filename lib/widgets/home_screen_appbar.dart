import 'package:connext_app/constants/style_text.dart';
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
    return AppBar(
      backgroundColor: Color(0xFFF4EEFF),
      title: Padding(
        padding: EdgeInsets.symmetric(vertical: 60.0),
        child: Row(
          children: [
            Expanded(flex: 4, child: title),
            Spacer(),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: CircleAvatar(
                  minRadius: 24,
                  backgroundColor: Color(0xFFF4EEFF),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
