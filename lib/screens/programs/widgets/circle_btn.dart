import 'package:flutter/material.dart';

class CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const CircleBtn({required this.icon, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
