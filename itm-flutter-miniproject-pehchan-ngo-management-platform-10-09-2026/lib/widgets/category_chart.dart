import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

/// Pie chart for expense categories
class CategoryPieChart extends StatefulWidget {
  final Map<String, double> categoryData;

  const CategoryPieChart({super.key, required this.categoryData});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryData.isEmpty) {
      return const Center(
        child: Text('No expense data', style: TextStyle(color: AppConstants.textMuted)),
      );
    }

    final entries = widget.categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final value = entry.value.value;
      final isTouched = index == _touchedIndex;
      final color = AppConstants.categoryColor(category);

      return PieChartSectionData(
        value: value,
        color: color,
        radius: isTouched ? 65 : 55,
        title: isTouched ? '${AppConstants.currencySymbol}${_fmt(value)}' : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = -1;
                    } else {
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: entries.map((entry) {
            final color = AppConstants.categoryColor(entry.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${entry.key}: ${AppConstants.currencySymbol}${_fmt(entry.value)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _fmt(double amount) {
    return NumberFormat('#,##,##0', 'en_IN').format(amount);
  }
}

/// Bar chart for yearly monthly breakdown
class YearlyBarChart extends StatelessWidget {
  final List<Map<String, double>> monthlyData; // list of 12 {income, expense}

  const YearlyBarChart({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    // Find max value for scaling
    double maxVal = 1000;
    for (final m in monthlyData) {
      if ((m['income'] ?? 0) > maxVal) maxVal = m['income']!;
      if ((m['expense'] ?? 0) > maxVal) maxVal = m['expense']!;
    }

    final barGroups = List.generate(12, (i) {
      final income = monthlyData[i]['income'] ?? 0;
      final expense = monthlyData[i]['expense'] ?? 0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: income,
            color: AppConstants.incomeColor,
            width: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: expense,
            color: AppConstants.expenseColor,
            width: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        barsSpace: 2,
      );
    });

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: barGroups,
              maxY: maxVal * 1.2,
              gridData: FlGridData(
                show: true,
                horizontalInterval: maxVal / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withValues(alpha: 0.08),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, _) => Text(
                      '${AppConstants.currencySymbol}${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppConstants.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= 12) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          months[idx],
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppConstants.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend('Income', AppConstants.incomeColor),
            const SizedBox(width: 20),
            _legend('Expenses', AppConstants.expenseColor),
          ],
        ),
      ],
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
