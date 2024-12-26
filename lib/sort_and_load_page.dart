import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_preferences_helper.dart';

class SortAndLoadPage extends StatefulWidget {
  final List<Map<String, String>> mergedSheetData;

  const SortAndLoadPage({
    super.key,
    required this.mergedSheetData,
  });

  @override
  SortAndLoadPageState createState() => SortAndLoadPageState();
}

class SortAndLoadPageState extends State<SortAndLoadPage> {
  List<Map<String, dynamic>> tableData = [];
  List<String> woodTypes = [];
  List<String> categories = [];
  Map<String, List<Map<String, dynamic>>> frames = {};
  double? selectedStartLength;
  double? selectedEndLength;
  String? selectedWoodType;
  TextEditingController frameNameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  bool isFrameNameVisible = false;

  @override
  void initState() {
    super.initState();
    loadTableData();
  }

  Future<void> loadTableData() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.mergedSheetData.isNotEmpty) {
      String partyName = widget.mergedSheetData[0]['partyName'] ?? '';
      Set<String> allKeys = prefs.getKeys();
      List<String> matchingKeys =
          allKeys.where((key) => key.contains(partyName)).toList();
      List<Map<String, dynamic>> aggregatedData = [];
      Set<String> woodSet = {};
      Set<String> categorySet = {};

      for (String key in matchingKeys) {
        List<List<Map<String, dynamic>>>? loadedData =
            await SharedPreferencesHelper.getTableDataWithMetadata(key);
        for (var row in loadedData) {
          for (var cell in row) {
            if (cell['value'] != null && cell['value'] != '') {
              aggregatedData.add({
                'length': cell['length'],
                'width': cell['width'],
                'thickness': cell['thickness'],
                'value': cell['value'],
                'woodType': cell['woodType'],
                'category': cell['category'],
              });
              woodSet.add(cell['woodType']);
              categorySet.add(cell['category']);
            }
          }
        }
      }

      setState(() {
        tableData = aggregatedData;
        woodTypes = woodSet.toList();
        categories = categorySet.toList();
        selectedStartLength = getAvailableLengths().isNotEmpty
            ? getAvailableLengths().first
            : null;
        selectedWoodType = woodTypes.isNotEmpty ? woodTypes.first : null;
      });
    }
  }

  List<double> getAvailableLengths() {
    return tableData
        .map((row) => double.tryParse(row['length'].toString()) ?? 0.0)
        .toSet()
        .toList()
      ..sort();
  }

  void addFrame() {
    if (selectedStartLength == null ||
        selectedEndLength == null ||
        amountController.text.isEmpty ||
        selectedWoodType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    double amount = double.tryParse(amountController.text) ?? 0.0;
    // Check if the category name is entered, else generate it
    String categoryName = frameNameController.text.isEmpty
        ? "${selectedWoodType ?? 'Unknown'} ${selectedStartLength?.toStringAsFixed(2)}-${selectedEndLength?.toStringAsFixed(2)}"
        : frameNameController.text;

    Map<String, dynamic> newFrame = {
      'start': selectedStartLength,
      'end': selectedEndLength,
      'categoryName': categoryName,
      'amount': amount,
      'woodType': selectedWoodType,
    };

    setState(() {
      if (!frames.containsKey(categoryName)) {
        frames[categoryName] = [];
      }
      frames[categoryName]!.add(newFrame);

      // Update `selectedStartLength` to the next available length after `selectedEndLength`
      List<double> availableLengths = getAvailableLengths();
      int endIndex = availableLengths.indexOf(selectedEndLength!);

      if (endIndex != -1 && endIndex + 1 < availableLengths.length) {
        selectedStartLength = availableLengths[endIndex + 1];
      } else {
        selectedStartLength = null; // No more lengths available
      }

      // Reset other fields
      selectedEndLength = null;
      frameNameController.clear();
      amountController.clear();
      selectedWoodType = null;
      isFrameNameVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<double> availableLengths = getAvailableLengths();
    return Scaffold(
      appBar: AppBar(title: Text("Sort & Load")),
      body: Column(
        children: [
          // Dropdown for wood type selection
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // Distribute buttons evenly
              children: woodTypes.map((woodType) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedWoodType =
                          woodType; // Set the selected wood type on tap
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: selectedWoodType == woodType
                          ? Colors.blue
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selectedWoodType == woodType
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                    child: Text(
                      woodType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: selectedWoodType == woodType
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Dropdowns for selecting length range
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Edit Icon
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      isFrameNameVisible = !isFrameNameVisible;
                    });
                  },
                ),
                // "From" Dropdown
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 56, // Set fixed height for equal height of fields
                    child: DropdownButton<double>(
                      hint: Text("From"),
                      value: selectedStartLength,
                      onChanged: (value) {
                        setState(() {
                          selectedStartLength = value;
                          selectedEndLength = null; // Reset end length
                        });
                      },
                      items: availableLengths
                          .map(
                            (length) => DropdownMenuItem<double>(
                              value: length,
                              child: Text(length.toString()),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // "To" Dropdown
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 56, // Set fixed height for equal height of fields
                    child: DropdownButton<double>(
                      hint: Text("To"),
                      value: selectedEndLength,
                      onChanged: (value) {
                        if (value != null &&
                            value > (selectedStartLength ?? 0)) {
                          setState(() {
                            selectedEndLength = value;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Select a valid 'To Length' greater than 'From Length'"),
                            ),
                          );
                        }
                      },
                      items: availableLengths
                          .where((length) =>
                              selectedStartLength == null ||
                              length > selectedStartLength!)
                          .map(
                            (length) => DropdownMenuItem<double>(
                              value: length,
                              child: Text(length.toString()),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // "Rate" TextField
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 56, // Set fixed height for equal height of fields
                    child: TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        hintText:
                            "Rate", // Use hintText (placeholder) instead of labelText
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 10.0), // Adjust vertical padding
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            ),
          ),

// Frame Name Field - only visible when 'isFrameNameVisible' is true
          if (isFrameNameVisible)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: frameNameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
            ),

          ElevatedButton(onPressed: addFrame, child: Text("Add")),
          // Display frames
          Expanded(
            child: frames.isEmpty
                ? Center(child: Text("No frames added yet"))
                : ListView(
                    children: frames.entries.map((entry) {
                      String frameName = entry.key;
                      List<Map<String, dynamic>> frameRanges = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              frameName,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...frameRanges.map((frame) {
                            double start = frame['start'];
                            double end = frame['end'];
                            double amount = frame['amount'];
                            String woodType = frame['woodType'];

                            List<Map<String, dynamic>> filteredData =
                                tableData.where(
                              (row) {
                                double length =
                                    double.tryParse(row['length'].toString()) ??
                                        0.0;
                                return length >= start &&
                                    length <= end &&
                                    row['woodType'] == woodType;
                              },
                            ).toList();

                            double totalCFT =
                                filteredData.fold(0.0, (sum, row) {
                              double length =
                                  double.tryParse(row['length'].toString()) ??
                                      0.0;
                              double width =
                                  double.tryParse(row['width'].toString()) ??
                                      0.0;
                              double thickness = double.tryParse(
                                      row['thickness'].toString()) ??
                                  0.0;
                              double value =
                                  double.tryParse(row['value'].toString()) ??
                                      0.0;
                              return sum +
                                  (length * width * thickness * value) / 144;
                            });

                            double totalAmount = totalCFT * amount;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
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
                                        decoration: BoxDecoration(
                                            color: Colors.blueAccent.shade100),
                                        children: [
                                          tableHeaderCell("Length"),
                                          tableHeaderCell("Width"),
                                          tableHeaderCell("Thickness"),
                                          tableHeaderCell("Quantity"),
                                          tableHeaderCell("CFT"),
                                          tableHeaderCell("CFT Total"),
                                          tableHeaderCell("Rate"),
                                          tableHeaderCell("Total Amount")
                                        ],
                                      ),
                                      ...filteredData.map((row) {
                                        double length = double.tryParse(
                                                row['length'].toString()) ??
                                            0.0;
                                        double width = double.tryParse(
                                                row['width'].toString()) ??
                                            0.0;
                                        double thickness = double.tryParse(
                                                row['thickness'].toString()) ??
                                            0.0;
                                        double value = double.tryParse(
                                                row['value'].toString()) ??
                                            0.0;
                                        double cft = (length *
                                                width *
                                                thickness *
                                                value) /
                                            144;

                                        return TableRow(
                                          children: [
                                            tableCell(length.toString()),
                                            tableCell(width.toString()),
                                            tableCell(thickness.toString()),
                                            tableCell(value.toString()),
                                            tableCell(cft.toStringAsFixed(2)),
                                            tableCell(""),
                                            tableCell(""),
                                            tableCell(""),
                                          ],
                                        );
                                      }).toList(),
                                      TableRow(
                                        decoration: BoxDecoration(
                                            color: Colors.blueAccent.shade100),
                                        children: [
                                          tableCell(""),
                                          tableCell(""),
                                          tableCell(""),
                                          tableCell(""),
                                          tableCell(""),
                                          tableCell(
                                              totalCFT.toStringAsFixed(2)),
                                          tableCell(amount.toString()),
                                          tableCell(
                                              totalAmount.toStringAsFixed(2)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ),
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
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
