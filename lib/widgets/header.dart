import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const Header({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    final panelColor = const Color(0xFF0E1216);

    return AppBar(
      backgroundColor: panelColor,
      title: Text(title, style: GoogleFonts.exo()),
      actions: actions,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
