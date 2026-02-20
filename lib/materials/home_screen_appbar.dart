import 'package:flutter/material.dart';

class HomeScreenAppbar extends StatelessWidget implements PreferredSizeWidget {
  const HomeScreenAppbar({super.key, required this.data, this.child});
  final String data;
  final Widget? child;
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
              child: Text(data, maxLines: 2, style: TextStyle(fontSize: 20)),
            ),
            Spacer(),
            Expanded(
              child: InkWell(child: CircleAvatar(minRadius: 24, child: child)),
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
