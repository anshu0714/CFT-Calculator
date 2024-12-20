import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For encoding and decoding JSON
import 'customtable.dart';

class LoadPage extends StatefulWidget {
  final String partyName; // Party name to differentiate the data

  const LoadPage({super.key, required this.partyName});

  @override
  LoadPageState createState() => LoadPageState();
}

class LoadPageState extends State<LoadPage> {
  // List to store dynamically added sheets
  List<Widget> sheets = [];
  List<String> categories = ["Patia", "Pava", "Create a New Category"];
  List<String> woodTypes = ["Kikar", "Sheesham", "Babool"]; // Wood types

  @override
  void initState() {
    super.initState();
    _loadSheets(); // Load saved sheets when the page is initialized
  }

  // Load sheets from SharedPreferences using the party name as a key
  Future<void> _loadSheets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedSheets =
        prefs.getString(widget.partyName); // Use partyName as key
    if (savedSheets != null) {
      // Decode the saved JSON data into a list of sheet data
      List<dynamic> sheetList = json.decode(savedSheets);
      setState(() {
        sheets = sheetList.map((sheetData) {
          return CustomTable(
            tableThickness: sheetData['thickness'],
            categoryName: sheetData['category'],
            woodType: sheetData['woodType'], // Add wood type
            partyName: widget.partyName,
          );
        }).toList();
      });
    }
  }

  void _removeSheet(int index) {
    setState(() {
      sheets.removeAt(index);
    });
    _saveSheets(); // Save the updated list of sheets
  }

  // Save sheets to SharedPreferences using the party name as a key
  Future<void> _saveSheets() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, String>> sheetData = sheets.map((sheet) {
      return {
        'thickness': (sheet as CustomTable).tableThickness,
        'category': (sheet).categoryName,
        'woodType': (sheet).woodType, // Save wood type
      };
    }).toList();

    String encodedSheets = json.encode(sheetData);
    await prefs.setString(widget.partyName,
        encodedSheets); // Save data with the party name as the key
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Load Page - ${widget.partyName}"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(20),
                  itemCount:
                      sheets.length + 1, // Add one for the "Add Sheet" button
                  itemBuilder: (context, index) {
                    if (index < sheets.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Sheet ${index + 1}",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _removeSheet(index); // Remove sheet
                                  },
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                // Navigate to the full sheet view by accessing the sheet directly
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
                                          .woodType, // Pass wood type
                                      partyName: widget.partyName,
                                    ),
                                  ),
                                ).then((_) {
                                  // Trigger a rebuild when returning from CustomTable
                                  setState(() {
                                    _loadSheets(); // Reload sheets after edit
                                  });
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                clipBehavior: Clip.hardEdge,
                                height: 250,
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey, width: 2),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: sheets[index], // Non-editable preview
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ElevatedButton(
                        onPressed: () {
                          _showAddSheetDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          "Add Sheet".toUpperCase(),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              letterSpacing: 0.5),
                        ),
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 80), // To ensure space for the bottom button
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text("Sort & Load".toUpperCase(),
                  style: TextStyle(
                      color: Colors.white, fontSize: 16, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog for adding a new sheet
  void _showAddSheetDialog() {
    String? selectedCategory;
    String? selectedWoodType; // For the selected wood type
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
                    style: TextStyle(color: Colors.teal),
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
                          woodType: selectedWoodType!, // Add wood type
                          partyName: widget.partyName,
                        ));
                      });

                      _saveSheets(); // Save the updated list of sheets

                      // Close the dialog after adding the sheet
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
                    style: TextStyle(color: Colors.teal),
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
