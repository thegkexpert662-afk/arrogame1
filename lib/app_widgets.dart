import 'package:flutter/material.dart';

const bg = Color(0xFFFFF8E8), brown = Color(0xFF70461F), orange = Color(0xFFF08A24), blue = Color(0xFF39A8F5);

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? trailing;
  const AppScaffold({super.key, required this.title, required this.body, this.trailing});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: brown),
            onPressed: () => Navigator.pop(context),
          ),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(title, style: const TextStyle(color: brown, fontWeight: FontWeight.bold)),
          ),
          actions: [if (trailing != null) trailing!],
        ),
        body: SafeArea(top: false, child: body),
      );
}

Widget primary(BuildContext c, String text, VoidCallback? onTap) => SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: brown,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onTap,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );

Widget softButton(String text, IconData icon, VoidCallback? onTap) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: brown,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onPressed: onTap,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28),
                const SizedBox(height: 4),
                Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
