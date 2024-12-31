import 'package:cft_calculator/frame_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cft_calculator/shared_preferences_helper.dart';

class SortLoadPage extends StatefulWidget {
  final List<Map<String, String>> mergedSheetData;
  const SortLoadPage({super.key, required this.mergedSheetData});

  @override
  SortLoadPageState createState() => SortLoadPageState();
}

class SortLoadPageState extends State<SortLoadPage> {
  Map<String, Set<String>> woodCategoriesMap = {};
  Map<String, String?> selectedCategories = {};
  Map<String, Map<String, List<Map<String, dynamic>>>> rowConfigurations = {};
  List<Map<String, dynamic>> tableData = [];
  List<Map<String, dynamic>> rowData = [];
  List<double> allAvailableLengths = [];
  List<Map<String, dynamic>> framesData = [];
  Map<String, Map<String, bool>> categoryCheckboxStates = {};

  @override
  void initState() {
    super.initState();
    loadTableData();
  }

  Future<void> loadTableData() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.mergedSheetData.isEmpty) return;

    String partyName = widget.mergedSheetData[0]['partyName'] ?? '';
    Set<String> allKeys = prefs.getKeys();
    List<String> matchingKeys =
        allKeys.where((key) => key.contains(partyName)).toList();

    List<Map<String, dynamic>> aggregatedData = [];
    for (String key in matchingKeys) {
      var loadedData =
          await SharedPreferencesHelper.getTableDataWithMetadata(key);
      for (var row in loadedData) {
        for (var cell in row) {
          String? woodType = cell['woodType'];
          String? category = cell['category'];

          if (woodType?.isNotEmpty ?? false) {
            woodCategoriesMap.putIfAbsent(woodType!, () => <String>{});
            if (category?.isNotEmpty ?? false) {
              woodCategoriesMap[woodType]!.add(category!);
            }
            rowData.add({
              'woodType': woodType,
              'category': category ?? '',
              'length': cell['length']?.toString() ?? '',
              'thickness': cell['thickness']?.toString() ?? '',
            });
          }

          if (cell['value']?.isNotEmpty ?? false) {
            aggregatedData.add({
              'length': cell['length'],
              'width': cell['width'],
              'thickness': cell['thickness'],
              'value': cell['value'],
              'woodType': woodType,
              'category': category,
            });
          }
        }
      }
    }

    allAvailableLengths = rowData
        .map((row) => double.tryParse(row['length'] ?? '') ?? 0.0)
        .where((length) => length > 0)
        .toSet()
        .toList()
      ..sort();

    initializeRowConfigurations();
    setState(() {
      tableData = aggregatedData;
    });
  }

  void initializeRowConfigurations() {
    for (var woodType in woodCategoriesMap.keys) {
      selectedCategories[woodType] = woodCategoriesMap[woodType]!.first;
      rowConfigurations[woodType] = {};
      for (var category in woodCategoriesMap[woodType]!) {
        rowConfigurations[woodType]![category] = [
          {
            'startLength': allAvailableLengths.first,
            'endLength': null,
            'rateControllers': <String, TextEditingController>{},
            'frameNameController': TextEditingController(),
            'isFrameNameVisible': false,
          }
        ];
      }

      categoryCheckboxStates[woodType] = {};
      for (var category in woodCategoriesMap[woodType]!) {
        categoryCheckboxStates[woodType]![category] = true;
      }
    }
  }

  bool canAddRow(String woodType, String category) {
    var currentConfigs = rowConfigurations[woodType]?[category];
    if (currentConfigs == null || currentConfigs.isEmpty) {
      return allAvailableLengths.isNotEmpty;
    }

    double largestLength = allAvailableLengths.last;
    var lastRow = currentConfigs.last;
    if (lastRow['endLength'] != null) {
      return lastRow['endLength'] != largestLength ||
          allAvailableLengths.any((length) => length > lastRow['endLength']);
    }

    return allAvailableLengths.isNotEmpty;
  }

  Widget buildConfigRow(Map<String, dynamic> config, String woodType) {
    String? selectedCategory = selectedCategories[woodType];

    List<double> filteredThicknesses = rowData
        .where((row) =>
            row['woodType'] == woodType &&
            row['category'] == selectedCategory &&
            row['thickness'] != null)
        .map((row) => double.tryParse(row['thickness'] ?? '0') ?? 0)
        .where((thickness) => thickness > 0)
        .toSet()
        .toList()
      ..sort();

    bool sameRate =
        categoryCheckboxStates[woodType]?[selectedCategories[woodType]] ?? true;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    config['isFrameNameVisible'] =
                        !(config['isFrameNameVisible'] ?? false);
                  });
                },
              ),
              SizedBox(
                width: 100,
                height: 56,
                child: buildDropdown(config, "From"),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 56,
                width: 100,
                child: buildDropdown(config, "To"),
              ),
              const SizedBox(width: 10),
              if (sameRate)
                SizedBox(
                  height: 56,
                  width: 100,
                  child: TextField(
                    controller: config['rateControllers']['default'] ??=
                        TextEditingController(),
                    decoration: InputDecoration(hintText: "Rate"),
                    keyboardType: TextInputType.number,
                  ),
                )
              else
                Row(
                  children: filteredThicknesses.map((thickness) {
                    return Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                      width: 100,
                      height: 56,
                      child: TextField(
                        controller: config['rateControllers']
                            [thickness.toString()] ??= TextEditingController(),
                        decoration:
                            InputDecoration(hintText: "Rate $thickness"),
                        keyboardType: TextInputType.number,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          if (config['isFrameNameVisible'] == true)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextField(
                  controller: config['frameNameController'],
                  decoration: const InputDecoration(hintText: "Name"),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void logAllRowData() {
    framesData.clear();
    rowConfigurations.forEach((woodType, categoryConfigs) {
      categoryConfigs.forEach((category, configs) {
        for (var config in configs) {
          String startLength = (config['startLength'] ?? '').toString();
          String endLength = (config['endLength'] ?? '').toString();
          Map<String, TextEditingController> rateControllers =
              config['rateControllers']
                  as Map<String, TextEditingController>; 

          if (categoryCheckboxStates[woodType]?[category] ?? true) {
            double rate =
                double.tryParse(rateControllers['default']?.text ?? '') ?? 0.0;
            String frameName = (config['frameNameController']?.text?.isEmpty ??
                    true)
                ? '${woodType}_$category (${startLength.isNotEmpty ? startLength : "0"}-${endLength.isNotEmpty ? endLength : "Max"})'
                : config['frameNameController']!.text;
            framesData.add({
              'frameName': frameName,
              'start': double.tryParse(startLength) ?? 0.0,
              'end': double.tryParse(endLength) ?? double.infinity,
              'amount': rate,
              'woodType': woodType,
              'category': category,
            });
          } else {
            rateControllers.forEach((thickness, controller) {
              double rate = double.tryParse(controller.text) ?? 0.0;
              String frameName = (config['frameNameController']
                          ?.text
                          ?.isEmpty ??
                      true)
                  ? '${woodType}_$category ($thickness: ${startLength.isNotEmpty ? startLength : "0"}-${endLength.isNotEmpty ? endLength : "Max"})'
                  : config['frameNameController']!.text;
              framesData.add({
                'frameName': frameName,
                'start': double.tryParse(startLength) ?? 0.0,
                'end': double.tryParse(endLength) ?? double.infinity,
                'amount': rate,
                'woodType': woodType,
                'category': category,
                'thickness': thickness,
              });
            });
          }
        }
      });
    });
    setState(() {});
    for (var frame in framesData) {
      print("Frame: $frame");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sort And Load')),
      body: woodCategoriesMap.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: woodCategoriesMap.entries.map((entry) {
                String woodType = entry.key;
                Set<String> categories = entry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(woodType,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Wrap(
                            children: categories.map((category) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCategories[woodType] = category;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 5),
                                  decoration: BoxDecoration(
                                    color:
                                        selectedCategories[woodType] == category
                                            ? Colors.blue
                                            : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selectedCategories[woodType] ==
                                              category
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: selectedCategories[woodType] ==
                                              category
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              children: [
                                ...?rowConfigurations[woodType]
                                        ?[selectedCategories[woodType]]
                                    ?.map((config) {
                                  return buildConfigRow(config, woodType);
                                }),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(
                              child: Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.add_circle_outline_outlined,
                                        color: Colors.black,
                                        size: 24),
                                    onPressed: canAddRow(woodType,
                                            selectedCategories[woodType]!)
                                        ? () {
                                            setState(() {
                                              double lastEndLength =
                                                  rowConfigurations[woodType]?[
                                                              selectedCategories[
                                                                  woodType]]!
                                                          .last['endLength'] ??
                                                      0.0;
                                              rowConfigurations[woodType]?[
                                                      selectedCategories[
                                                          woodType]]!
                                                  .add({
                                                'startLength':
                                                    allAvailableLengths
                                                        .firstWhere((length) =>
                                                            length >
                                                            lastEndLength),
                                                'endLength': null,
                                                'rateControllers': {},
                                                'frameNameController':
                                                    TextEditingController(),
                                                'isFrameNameVisible': false,
                                              });
                                            });
                                          }
                                        : null,
                                  ),
                                  buildCategoryCheckbox(woodType),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            logAllRowData();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text("Frames Data")),
                  body: ListView(
                    children: framesData.map((frame) {
                      return FrameWidget(
                        frameName: frame['frameName'],
                        frameRanges: [
                          {
                            'start': frame['start'],
                            'end': frame['end'],
                            'amount': frame['amount'],
                            'woodType': frame['woodType'],
                            'category': frame['category'],
                          }
                        ],
                        tableData: tableData,
                        showThickness: categoryCheckboxStates[frame['woodType']]
                                ?[frame['category']] ??
                            true,
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
          child: Text("Submit"),
        ),
      ),
    );
  }

  Widget buildDropdown(Map<String, dynamic> config, String label) {
    return SizedBox(
      height: 56,
      width: 100,
      child: DropdownButton<double>(
        hint: Text(label),
        value: config[label == "From" ? 'startLength' : 'endLength'],
        onChanged: (value) {
          setState(() {
            if (label == "From") {
              config['startLength'] = value;
              config['endLength'] = null;
            } else {
              config['endLength'] = value;
            }
          });
        },
        items: allAvailableLengths
            .where((length) =>
                label == "From" ||
                (config['startLength'] == null ||
                    length > config['startLength']))
            .map((length) => DropdownMenuItem<double>(
                value: length, child: Text(length.toString())))
            .toList(),
      ),
    );
  }

  Widget buildCategoryCheckbox(String woodType) {
    return Row(
      children: [
        Checkbox(
          value: categoryCheckboxStates[woodType]
                  ?[selectedCategories[woodType]] ??
              true,
          onChanged: (bool? value) {
            setState(() {
              categoryCheckboxStates[woodType]?[selectedCategories[woodType]!] =
                  value ?? true;
            });
          },
        ),
        Text("Same rate for all thicknesses"),
      ],
    );
  }
}
