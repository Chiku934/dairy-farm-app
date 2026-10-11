import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AppTableColumn {
  final String title;
  final double? width;
  final TextAlign textAlign;
  final bool isSortable;

  const AppTableColumn({
    required this.title,
    this.width,
    this.textAlign = TextAlign.left,
    this.isSortable = false,
  });
}

class AppDataTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<List<Widget>> rows;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int>? onPageChanged;
  final String? emptyMessage;
  final bool isLoading;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.pageSize = 10,
    this.onPageChanged,
    this.emptyMessage = 'No records found',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppElevation.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scrollable table container
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 34,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header Row
                  Container(
                    color: AppColors.surfaceNeutral,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: columns.map((col) {
                        Widget text = Text(
                          col.title.toUpperCase(),
                          textAlign: col.textAlign,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        );

                        if (col.width != null) {
                          return SizedBox(width: col.width, child: text);
                        }
                        return Expanded(child: text);
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),

                  // Table Rows
                  if (isLoading) ...[
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary700,
                          ),
                        ),
                      ),
                    ),
                  ] else if (rows.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          emptyMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ...rows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final rowCells = entry.value;
                      final isLast = index == rows.length - 1;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            color: index.isEven
                                ? AppColors.cardSurface
                                : AppColors.surfaceWarm,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: rowCells.asMap().entries.map((cellEntry) {
                                final colIndex = cellEntry.key;
                                final cellWidget = cellEntry.value;
                                final col = columns[colIndex];

                                if (col.width != null) {
                                  return SizedBox(
                                    width: col.width,
                                    child: cellWidget,
                                  );
                                }
                                return Expanded(child: cellWidget);
                              }).toList(),
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                              height: 1,
                              color: AppColors.borderSubtle,
                            ),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          // Pagination Bar
          if (totalPages > 1 || totalItems > 0) ...[
            const Divider(height: 1, color: AppColors.borderSubtle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Showing ${((currentPage - 1) * pageSize) + (totalItems > 0 ? 1 : 0)} - ${(currentPage * pageSize).clamp(0, totalItems)} of $totalItems',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        color: currentPage > 1
                            ? AppColors.textMain
                            : AppColors.textDisabled,
                        onPressed: currentPage > 1 && onPageChanged != null
                            ? () => onPageChanged!(currentPage - 1)
                            : null,
                        splashRadius: 18,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceNeutral,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$currentPage / $totalPages',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        color: currentPage < totalPages
                            ? AppColors.textMain
                            : AppColors.textDisabled,
                        onPressed:
                            currentPage < totalPages && onPageChanged != null
                                ? () => onPageChanged!(currentPage + 1)
                                : null,
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
