import 'package:flutter/material.dart';

/// Single tree node widget with dispatch badge indicator.
///
/// Shows location name, type label, and a colored dispatch dot on the right.
/// Indents by [depth] × 16px. Shows expand/collapse chevron when [hasChildren]
/// is true. Calls [onTap] when the name area is tapped and [onExpand] when
/// the chevron is tapped.
///
/// @realizes UML::LocationTreeTile
class LocationTreeTile extends StatelessWidget {
  final String id;
  final String name;
  final String type;
  final String dispatchStatus;
  final int depth;
  final bool isExpanded;
  final bool hasChildren;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;

  const LocationTreeTile({
    super.key,
    required this.id,
    required this.name,
    required this.type,
    required this.dispatchStatus,
    required this.depth,
    this.isExpanded = false,
    this.hasChildren = false,
    this.isSelected = false,
    this.onTap,
    this.onExpand,
  });

  Color get _dotColor {
    switch (dispatchStatus) {
      case 'ready':
        return Colors.green;
      case 'incomplete':
        return Colors.orange;
      case 'stale':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 16.0 + depth * 16.0,
          right: 8,
          top: 6,
          bottom: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : null,
        ),
        child: Row(
          children: [
            if (hasChildren)
              GestureDetector(
                onTap: onExpand,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              )
            else
              const SizedBox(width: 22),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (type.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dotColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
