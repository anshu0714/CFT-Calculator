import 'package:cft_calculator/shared_preferences_helper.dart';
import 'package:cft_calculator/sort_and_load_page.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'customtable.dart';

class LoadPage extends StatefulWidget {
  final String partyName;

  const LoadPage({super.key, required this.partyName});

  @override
  LoadPageState createState() => LoadPageState();
}

class LoadPageState extends State<LoadPage> {
  // List to store dynamically added sheets
  List<Widget> sheets = [];
  List<String> categories = ["Patia", "Pava", "Create a New Category"];
  List<String> woodTypes = ["Kikar", "Sheesham", "Babool"];

  @override
  void initState() {
    super.initState();
    _loadSheets();
  }

  // Load sheets from SharedPreferences using the party name as a key
  Future<void> _loadSheets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedSheets = prefs.getString(widget.partyName);
    if (savedSheets != null) {
      List<dynamic> sheetList = json.decode(savedSheets);
      setState(() {
        sheets = sheetList.map((sheetData) {
          return CustomTable(
            tableThickness: sheetData['thickness'],
            categoryName: sheetData['category'],
            woodType: sheetData['woodType'],
            partyName: widget.partyName,
          );
        }).toList();
      });
    }
  }

  void _removeSheet(int index) async {
    final CustomTable sheet = sheets[index] as CustomTable;
    final String tableKey =
        "${sheet.tableThickness}_${sheet.categoryName}_${sheet.woodType}_${widget.partyName}";

    setState(() {
      sheets.removeAt(index);
    });

    await SharedPreferencesHelper.clearTableData(tableKey);
    await SharedPreferencesHelper.removeTableKey(tableKey);

    // Save the updated list of sheets
    _saveSheets();
  }

  // Save sheets to SharedPreferences using the party name as a key
  Future<void> _saveSheets() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, String>> sheetData = sheets.map((sheet) {
      return {
        'thickness': (sheet as CustomTable).tableThickness,
        'category': (sheet).categoryName,
        'woodType': (sheet).woodType,
      };
    }).toList();

    String encodedSheets = json.encode(sheetData);
    await prefs.setString(widget.partyName, encodedSheets);
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete this sheet?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeSheet(index);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Load Page - ${widget.partyName}"),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(20),
                  itemCount: sheets.length + 1,
                  itemBuilder: (context, index) {
                    if (index < sheets.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 61, 61, 61),
                            border: Border.all(
                                color: const Color.fromARGB(255, 61, 61, 61),
                                width: 2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomTable(
                                        tableThickness:
                                            (sheets[index] as CustomTable)
                                                .tableThickness,
                                        categoryName:
                                            (sheets[index] as CustomTable)
                                                .categoryName,
                                        woodType: (sheets[index] as CustomTable)
                                            .woodType,
                                        partyName: widget.partyName,
                                      ),
                                    ),
                                  ).then((_) {
                                    // Trigger a rebuild when returning from CustomTable
                                    setState(() {
                                      _loadSheets();
                                    });
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                  clipBehavior: Clip.hardEdge,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey, width: 0),
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(5),
                                        topRight: Radius.circular(5)),
                                  ),
                                  child: sheets[index],
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      "Sheet ${index + 1}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(index);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Container(
                        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                        height: 200,
                        width: MediaQuery.of(context).size.width,
                        child: DottedBorder(
                          borderType: BorderType.RRect,
                          strokeWidth: 2,
                          dashPattern: [8, 4],
                          radius: Radius.circular(5),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Container(
                              width: double.infinity,
                              color: Colors.white,
                              child: TextButton(
                                onPressed: () {
                                  _showAddSheetDialog();
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_rounded,
                                      color: Colors.black,
                                      size: 70,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Add Sheet".toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 24,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 80),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (sheets.isNotEmpty) {
                    List<Map<String, String>> mergedSheetData =
                        sheets.map((sheet) {
                      return {
                        'thickness': (sheet as CustomTable).tableThickness,
                        'category': (sheet).categoryName,
                        'woodType': (sheet).woodType,
                        'partyName': widget.partyName,
                      };
                    }).toList();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SortAndLoadPage(
                          mergedSheetData: mergedSheetData,
                        ),
                      ),
                    ).then((_) {
                      // Trigger a rebuild after returning from SortAndLoadPage
                      setState(() {
                        _loadSheets();
                      });
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please add a sheet first!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text("Sort & Load".toUpperCase(),
                    style: TextStyle(
                        fontSize: 20,
                        letterSpacing: 0.5,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog for adding a new sheet
  void _showAddSheetDialog() {
    String? selectedCategory;
    String? selectedWoodType;
    TextEditingController thicknessController = TextEditingController();
    TextEditingController newCategoryController = TextEditingController();
    bool showNewCategoryField = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text("Add Sheet"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: thicknessController,
                    decoration: InputDecoration(labelText: "Thickness"),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      dialogSetState(() {
                        selectedCategory = value;
                        showNewCategoryField = value == "Create a New Category";
                      });
                    },
                    decoration: InputDecoration(labelText: "Category"),
                  ),
                  if (showNewCategoryField)
                    TextField(
                      controller: newCategoryController,
                      decoration:
                          InputDecoration(labelText: "New Category Name"),
                    ),
                  // Wood type dropdown
                  DropdownButtonFormField<String>(
                    value: selectedWoodType,
                    items: woodTypes.map((woodType) {
                      return DropdownMenuItem(
                        value: woodType,
                        child: Text(woodType),
                      );
                    }).toList(),
                    onChanged: (value) {
                      dialogSetState(() {
                        selectedWoodType = value;
                      });
                    },
                    decoration: InputDecoration(labelText: "Wood Type"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (thicknessController.text.isNotEmpty &&
                        (selectedCategory != null &&
                            (selectedCategory != "Create a New Category" ||
                                newCategoryController.text.isNotEmpty)) &&
                        selectedWoodType != null) {
                      if (selectedCategory == "Create a New Category") {
                        setState(() {
                          categories.insert(categories.length - 1,
                              newCategoryController.text);
                        });
                        dialogSetState(() {
                          selectedCategory = newCategoryController.text;
                          showNewCategoryField = false;
                        });
                      }

                      setState(() {
                        sheets.add(CustomTable(
                          tableThickness: thicknessController.text,
                          categoryName: selectedCategory!,
                          woodType: selectedWoodType!,
                          partyName: widget.partyName,
                        ));
                      });

                      _saveSheets();
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text("Please fill all fields before adding."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Add",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
