import 'package:connext_app/widgets/connext_app_bar.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, this.title, this.onPressed});
  final Widget? title;
  final void Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return ConnextAppBar(
      variant: ConnextAppBarVariant.minimal,
      title: title,
      onLeadingPressed: onPressed,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
