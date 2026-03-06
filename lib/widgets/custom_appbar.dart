import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, this.title, this.onPressed});
  final Widget? title;
  final void Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      leading: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.arrow_back, color: Color(0XFF424874)),
      ),
      backgroundColor: Color(0xFFF4EEFF),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
