import 'package:flutter/material.dart';

class DashboardSectionHeader extends StatelessWidget {
  final String title;
  const DashboardSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Text(title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold));
}
