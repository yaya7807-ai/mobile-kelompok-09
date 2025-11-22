import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartWidget extends StatelessWidget {
  const PieChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(centerSpaceRadius: 40, sectionsSpace: 2, sections: _dummy()),
    );
  }

  List<PieChartSectionData> _dummy() {
    return [
      PieChartSectionData(
        value: 17,
        color: Colors.blue,
        title: "17%",
        radius: 55,
      ),
      PieChartSectionData(
        value: 27,
        color: Colors.orange,
        title: "27%",
        radius: 55,
      ),
      PieChartSectionData(
        value: 37,
        color: Colors.green,
        title: "37%",
        radius: 55,
      ),
      PieChartSectionData(
        value: 20,
        color: Colors.red,
        title: "20%",
        radius: 55,
      ),
    ];
  }
}
