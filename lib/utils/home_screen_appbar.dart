import 'package:connext_app/utils/style_text.dart';
import 'package:flutter/material.dart';

class HomeScreenAppbar extends StatelessWidget implements PreferredSizeWidget {
  const HomeScreenAppbar({
    super.key,
    required this.data,
    this.child,
    this.onTap,
  });
  final String data;
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
            Expanded(
              flex: 4,
              child: Text(data, maxLines: 2, style: styleText()),
            ),
            Spacer(),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: CircleAvatar(minRadius: 24, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
