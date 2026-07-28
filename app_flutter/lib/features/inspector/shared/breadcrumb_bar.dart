import 'package:flutter/material.dart';

/// A single item in a [BreadcrumbBar] representing a path segment.
///
/// Each item has an [id] for identification, a [label] for display, and an
/// optional [onTap] callback. Items with no [onTap] are rendered as non-clickable
/// (typically the last/current item).
class BreadcrumbItem {
  final String id;
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.id, required this.label, this.onTap});
}

/// Renders a horizontal scrollable breadcrumb trail: Item1 > Item2 > Item3.
///
/// The last item is rendered bold and non-clickable. Middle items are clickable
/// with blue text. Between each item a chevron_right icon is displayed as a
/// separator.
///
/// @realizes UML::BreadcrumbBar
class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            GestureDetector(
              onTap: items[i].onTap,
              child: Text(
                items[i].label,
                style: TextStyle(
                  fontSize: 12,
                  color: i == items.length - 1
                      ? Colors.white
                      : Colors.blue.shade300,
                  fontWeight: i == items.length - 1
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
