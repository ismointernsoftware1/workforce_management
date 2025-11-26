import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// Enhanced table component with shadcn-style design
class ShadTable extends StatelessWidget {
  const ShadTable({
    super.key,
    required this.columns,
    required this.rows,
    this.headerPadding = const EdgeInsets.all(AppSpacing.md),
    this.cellPadding = const EdgeInsets.all(AppSpacing.md),
  });

  final List<ShadTableColumn> columns;
  final List<ShadTableRow> rows;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry cellPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: headerPadding,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: columns.map((column) {
                return Expanded(
                  flex: column.flex,
                  child: Text(
                    column.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Table Rows
          ...rows.map((row) {
            return Container(
              padding: cellPadding,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: row.cells.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cell = entry.value;
                  if (index >= columns.length) {
                    return const SizedBox.shrink();
                  }
                  return Expanded(
                    flex: columns[index].flex,
                    child: cell,
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ShadTableColumn {
  const ShadTableColumn({
    required this.label,
    this.flex = 1,
  });

  final String label;
  final int flex;
}

class ShadTableRow {
  const ShadTableRow({required this.cells});

  final List<Widget> cells;
}

