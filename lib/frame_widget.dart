import 'package:flutter/material.dart';

class FrameWidget extends StatelessWidget {
  final String frameName;
  final List<Map<String, dynamic>> frameRanges;
  final List<Map<String, dynamic>> tableData;
  final bool showThickness;

  const FrameWidget({
    super.key,
    required this.frameName,
    required this.frameRanges,
    required this.tableData,
    required this.showThickness,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            frameName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...frameRanges.map((frame) {
          double start = frame['start'];
          double end = frame['end'];
          double amount = frame['amount'];
          String woodType = frame['woodType'];
          String category = frame['category'];

          if (!showThickness) {
            Map<String, List<Map<String, dynamic>>> groupedByThickness =
                groupDataByThickness(tableData, start, end, woodType, category);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: groupedByThickness.entries.map((entry) {
                String thickness = entry.key;
                List<Map<String, dynamic>> thicknessData = entry.value;

                double totalCFT = calculateTotalCFT(thicknessData);
                double totalAmount = totalCFT * amount;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Thickness: $thickness',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    buildTable(thicknessData, totalCFT, amount, totalAmount),
                  ],
                );
              }).toList(),
            );
          } else {
            List<Map<String, dynamic>> filteredData = tableData.where((row) {
              double length =
                  double.tryParse(row['length']?.toString() ?? '') ?? 0.0;
              return length >= start &&
                  (end.isFinite ? length <= end : true) &&
                  row['woodType'] == woodType &&
                  row['category'] == category;
            }).toList();

            filteredData.sort((a, b) {
              double thicknessA =
                  double.tryParse(a['thickness']?.toString() ?? '') ?? 0.0;
              double thicknessB =
                  double.tryParse(b['thickness']?.toString() ?? '') ?? 0.0;
              double lengthA =
                  double.tryParse(a['length']?.toString() ?? '') ?? 0.0;
              double lengthB =
                  double.tryParse(b['length']?.toString() ?? '') ?? 0.0;

              if (thicknessA != thicknessB) {
                return thicknessA.compareTo(thicknessB);
              }
              return lengthA.compareTo(lengthB);
            });

            double totalCFT = calculateTotalCFT(filteredData);
            double totalAmount = totalCFT * amount;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTable(filteredData, totalCFT, amount, totalAmount),
              ],
            );
          }
        }),
      ],
    );
  }

  Map<String, List<Map<String, dynamic>>> groupDataByThickness(
    List<Map<String, dynamic>> data,
    double start,
    double end,
    String woodType,
    String category,
  ) {
    return data.where((row) {
      double length = double.tryParse(row['length']?.toString() ?? '') ?? 0.0;
      return length >= start &&
          (end.isFinite ? length <= end : true) &&
          row['woodType'] == woodType &&
          row['category'] == category;
    }).fold<Map<String, List<Map<String, dynamic>>>>({}, (map, row) {
      String thickness = row['thickness']?.toString() ?? 'Unknown';
      map.putIfAbsent(thickness, () => []).add(row);
      return map;
    });
  }

  double calculateTotalCFT(List<Map<String, dynamic>> data) {
    return data.fold(0.0, (sum, row) {
      double length = double.tryParse(row['length']?.toString() ?? '') ?? 0.0;
      double width = double.tryParse(row['width']?.toString() ?? '') ?? 0.0;
      double thickness =
          double.tryParse(row['thickness']?.toString() ?? '') ?? 0.0;
      double value = double.tryParse(row['value']?.toString() ?? '') ?? 0.0;
      return sum + (length * width * thickness * value) / 144;
    });
  }

  Widget buildTable(List<Map<String, dynamic>> data, double totalCFT,
      double rate, double totalAmount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey),
        columnWidths: const {
          0: FixedColumnWidth(90),
          1: FixedColumnWidth(90),
          2: FixedColumnWidth(90),
          3: FixedColumnWidth(90),
          4: FixedColumnWidth(90),
          5: FixedColumnWidth(90),
          6: FixedColumnWidth(90),
          7: FixedColumnWidth(90),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.blueAccent.shade100),
            children: [
              tableHeaderCell("Length"),
              tableHeaderCell("Width"),
              tableHeaderCell("Thickness"),
              tableHeaderCell("Quantity"),
              tableHeaderCell("CFT"),
              tableHeaderCell("CFT Total"),
              tableHeaderCell("Rate"),
              tableHeaderCell("Total Amount"),
            ],
          ),
          ...data.map((row) {
            double length =
                double.tryParse(row['length']?.toString() ?? '') ?? 0.0;
            double width =
                double.tryParse(row['width']?.toString() ?? '') ?? 0.0;
            double thickness =
                double.tryParse(row['thickness']?.toString() ?? '') ?? 0.0;
            double value =
                double.tryParse(row['value']?.toString() ?? '') ?? 0.0;
            double cft = (length * width * thickness * value) / 144;
            return TableRow(
              children: [
                tableCell(length.toStringAsFixed(2)),
                tableCell(width.toStringAsFixed(2)),
                tableCell(thickness.toStringAsFixed(2)),
                tableCell(value.toStringAsFixed(2)),
                tableCell(cft.toStringAsFixed(2)),
                tableCell(""),
                tableCell(""),
                tableCell(""),
              ],
            );
          }),
          TableRow(
            decoration: BoxDecoration(color: Colors.blueAccent.shade100),
            children: [
              tableCell(""),
              tableCell(""),
              tableCell(""),
              tableCell(""),
              tableCell(""),
              tableCell(totalCFT.toStringAsFixed(2)),
              tableCell(rate.toStringAsFixed(2)),
              tableCell(totalAmount.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }
}
