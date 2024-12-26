// ignore_for_file: deprecated_member_use
import 'package:cft_calculator/table_data_helper.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:flutter/services.dart';
import "package:expressions/expressions.dart";
import 'shared_preferences_helper.dart';

class CustomTable extends StatefulWidget {
  final String tableThickness;
  final String categoryName;
  final String woodType;
  final String partyName;
  const CustomTable(
      {super.key,
      required this.tableThickness,
      required this.categoryName,
      required this.woodType,
      required this.partyName});

  @override
  State<CustomTable> createState() => _CustomTableState();
}

class _CustomTableState extends State<CustomTable> {
  LinkedScrollControllerGroup controllerGroup = LinkedScrollControllerGroup();
  ScrollController? headerScrollController;
  ScrollController? dataScrollController;

  List<List<FocusNode>> focusNodes = [];
  List<List<TextEditingController>> controllers = [];
  List<List<String>> originalExpressions = [];

  int? focusedRowIndex;
  int? focusedColumnIndex;

  String get tableKey =>
      "${widget.tableThickness}_${widget.categoryName}_${widget.woodType}_${widget.partyName}";

  @override
  void initState() {
    super.initState();
    headerScrollController = controllerGroup.addAndGet();
    dataScrollController = controllerGroup.addAndGet();
    _initializeFocusNodes();
    _initializeControllers();
    _loadTableData();
    _saveTableKey();
  }

  void _saveTableKey() async {
    await SharedPreferencesHelper.addTableKey(tableKey);
  }

  void _initializeFocusNodes() {
    focusNodes = List.generate(14, (rowIndex) {
      return List.generate(
        TableDataHelper.kTableColumnsList.length - 1,
        (colIndex) => FocusNode(),
      );
    });

    for (int rowIndex = 0; rowIndex < focusNodes.length; rowIndex++) {
      for (int colIndex = 0;
          colIndex < focusNodes[rowIndex].length;
          colIndex++) {
        focusNodes[rowIndex][colIndex].addListener(() {
          setState(() {
            if (focusNodes[rowIndex][colIndex].hasFocus) {
              focusedRowIndex = rowIndex;
              focusedColumnIndex = colIndex;
              if (controllers[rowIndex][colIndex].text.contains('(')) {
                controllers[rowIndex][colIndex].text =
                    originalExpressions[rowIndex][colIndex];
              }
            }
          });
        });
      }
    }
  }

  void _initializeControllers() {
    controllers = List.generate(14, (rowIndex) {
      return List.generate(
        TableDataHelper.kTableColumnsList.length - 1,
        (colIndex) => TextEditingController(),
      );
    });
    originalExpressions = List.generate(14, (rowIndex) {
      return List.generate(
        TableDataHelper.kTableColumnsList.length - 1,
        (colIndex) => "",
      );
    });
  }

  void _loadTableData() async {
    List<List<Map<String, dynamic>>> savedDataWithMetadata =
        await SharedPreferencesHelper.getTableDataWithMetadata(tableKey);

    if (savedDataWithMetadata.isNotEmpty) {
      for (int rowIndex = 0;
          rowIndex < savedDataWithMetadata.length;
          rowIndex++) {
        for (int colIndex = 0;
            colIndex < savedDataWithMetadata[rowIndex].length;
            colIndex++) {
          String cellValue =
              savedDataWithMetadata[rowIndex][colIndex]['value'] ?? '';
          controllers[rowIndex][colIndex].text = cellValue;
        }
      }
    }
  }

  void _saveTableData() async {
    List<List<String>> tableData = List.generate(14, (rowIndex) {
      return List.generate(
        TableDataHelper.kTableColumnsList.length - 1,
        (colIndex) => controllers[rowIndex][colIndex].text,
      );
    });
    await SharedPreferencesHelper.saveTableDataForDisplay(tableData, tableKey);
  }

  void _saveTableDataWithLengthAndWidth() async {
    List<List<Map<String, dynamic>>> tableDataWithLengthWidth =
        List.generate(14, (rowIndex) {
      return List.generate(
        TableDataHelper.kTableColumnsList.length - 1,
        (colIndex) {
          String cellValue = controllers[rowIndex][colIndex].text;
          if (cellValue.isNotEmpty) {
            double length = 1.5 + (rowIndex * 0.5);

            String? columnTitle =
                TableDataHelper.kTableColumnsList[colIndex + 1].title;
            double width = 0.0;
            double thickness = double.tryParse(widget.tableThickness) ?? 0.0;

            if (columnTitle != null) {
              width = double.tryParse(columnTitle) ?? 0.0;
            }

            return {
              'value': cellValue,
              'length': length,
              'width': width,
              'thickness': thickness,
              'category': widget.categoryName,
              'woodType': widget.woodType,
            };
          } else {
            return {
              'value': '',
              'length': 0.0,
              'width': 0.0,
              'thickness': 0.0,
              'category': widget.categoryName,
              'woodType': widget.woodType,
            };
          }
        },
      );
    });

    List<List<Map<String, dynamic>>> nonEmptyData = tableDataWithLengthWidth
        .map((row) => row.where((cell) => cell['value'] != '').toList())
        .where((row) => row.isNotEmpty)
        .toList();

    print(nonEmptyData);

    await SharedPreferencesHelper.saveTableDataWithMetadata(
        tableKey, tableDataWithLengthWidth);
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All Data'),
          content: Text(
              'Are you sure you want to clear all the data? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.black38)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearData();
              },
              child: Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _clearData() async {
    await SharedPreferencesHelper.clearTableData(tableKey);
    await SharedPreferencesHelper.removeTableKey(tableKey);

    setState(() {
      // Reset the controllers to empty
      controllers = List.generate(14, (rowIndex) {
        return List.generate(
          TableDataHelper.kTableColumnsList.length - 1,
          (colIndex) => TextEditingController(),
        );
      });
    });
  }

  void _handleCalculation(int rowIndex, int colIndex) {
    String enteredText = controllers[rowIndex][colIndex].text;

    List<String> operators = ['+', '-', '*', '/'];

    if (enteredText.isNotEmpty &&
        operators.any((op) => enteredText.contains(op))) {
      try {
        String trimmedText = enteredText.replaceAll(RegExp(r'\s+'), '');

        if (_isValidExpression(trimmedText)) {
          final expression = Expression.parse(trimmedText);
          final evaluator = ExpressionEvaluator();
          final result = evaluator.eval(expression, {});

          originalExpressions[rowIndex][colIndex] = trimmedText;
          controllers[rowIndex][colIndex].text = "$result ($trimmedText)";
        } else {
          controllers[rowIndex][colIndex].text = "Invalid Expression";
        }
      } catch (e) {
        controllers[rowIndex][colIndex].text = "Error";
      }
    }
  }

  bool _isValidExpression(String expression) {
    final validExpression = RegExp(r'^[\d+\-*/().\s]+$');
    return validExpression.hasMatch(expression);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Text("${widget.tableThickness}_",
                style: TextStyle(color: Colors.black)),
            Text("${widget.categoryName}_",
                style: TextStyle(color: Colors.black)),
            Text(widget.woodType, style: TextStyle(color: Colors.black)),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {
              _showConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.teal.shade200,
                      border: Border(
                          right: BorderSide(color: Colors.black, width: 0.5)),
                    ),
                    child: DataTable(
                      columnSpacing: 0,
                      columns: TableDataHelper.kTableColumnsList
                          .getRange(0, 1)
                          .map((e) {
                        return DataColumn(
                          label: SizedBox(
                            width: e.width ?? 0,
                            child: Text(
                              e.title ?? "",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }).toList(),
                      rows: List.generate(
                        14,
                        (index) {
                          double value = 1.5 + (index * 0.5);
                          return DataRow(cells: [
                            DataCell(SizedBox(
                                width:
                                    TableDataHelper.kTableColumnsList[0].width,
                                child: Text(
                                  "$value",
                                  textAlign: TextAlign.center,
                                ))),
                          ]);
                        },
                      ),
                      headingRowColor:
                          WidgetStatePropertyAll(Colors.teal.shade500),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: dataScrollController,
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (RawKeyEvent event) {
                            if (event
                                .isKeyPressed(LogicalKeyboardKey.backspace)) {
                              _moveFocusBackwards();
                            }
                          },
                          child: DataTable(
                            columnSpacing: 0,
                            columns: TableDataHelper.kTableColumnsList
                                .getRange(
                                    1, TableDataHelper.kTableColumnsList.length)
                                .map((e) {
                              return DataColumn(
                                label: SizedBox(
                                  width: e.width ?? 0,
                                  child: Text(
                                    e.title ?? "",
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }).toList(),
                            rows: List.generate(
                              14,
                              (index) {
                                return DataRow(
                                  color: focusedRowIndex == index
                                      ? MaterialStateProperty.all(
                                          Colors.grey.shade200)
                                      : null,
                                  cells: [
                                    ...List.generate(
                                      TableDataHelper.kTableColumnsList.length -
                                          1,
                                      (colIndex) {
                                        return DataCell(Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                width: 0.5,
                                                color: Colors.black),
                                            color:
                                                focusedColumnIndex == colIndex
                                                    ? Colors.grey.shade200
                                                    : Colors.transparent,
                                          ),
                                          child: SizedBox(
                                            width: TableDataHelper
                                                .kTableColumnsList[colIndex + 1]
                                                .width,
                                            child: TextField(
                                              controller: controllers[index]
                                                  [colIndex],
                                              focusNode: focusNodes[index]
                                                  [colIndex],
                                              decoration: InputDecoration(
                                                  border: InputBorder.none),
                                              textAlign: TextAlign.center,
                                              textInputAction:
                                                  TextInputAction.next,
                                              onChanged: (_) {
                                                _saveTableData();
                                                _saveTableDataWithLengthAndWidth();
                                              },
                                              onSubmitted: (_) {
                                                _handleCalculation(
                                                    index, colIndex);
                                                _moveFocus(index, colIndex);
                                              },
                                              onTap: () {
                                                if (controllers[index][colIndex]
                                                    .text
                                                    .contains('(')) {
                                                  controllers[index][colIndex]
                                                          .text =
                                                      originalExpressions[index]
                                                          [colIndex];
                                                }
                                              },
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: true,
                                                      signed: true),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(
                                                        r'^[\d\+\-\*\/\(\)\s]+$')),
                                              ],
                                            ),
                                          ),
                                        ));
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            tableHeader(),
          ],
        ),
      ),
    );
  }

  Widget tableHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.teal.shade200,
            border: Border(
                right: BorderSide(
              color: Colors.white,
              width: 0.5,
            )),
          ),
          child: DataTable(
            columnSpacing: 0,
            columns: TableDataHelper.kTableColumnsList.getRange(0, 1).map((e) {
              return DataColumn(
                  label: SizedBox(
                width: e.width ?? 0,
                child: Text(
                  e.title ?? "",
                  textAlign: TextAlign.center,
                ),
              ));
            }).toList(),
            rows: [],
            headingRowColor: WidgetStatePropertyAll(Colors.teal.shade500),
          ),
        ),
        Expanded(
            child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            controller: headerScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 0,
              columns: TableDataHelper.kTableColumnsList
                  .getRange(1, TableDataHelper.kTableColumnsList.length)
                  .map((e) {
                return DataColumn(
                    label: SizedBox(
                  width: e.width ?? 0,
                  child: Text(
                    e.title ?? "",
                    textAlign: TextAlign.center,
                  ),
                ));
              }).toList(),
              rows: [],
              headingRowColor: WidgetStatePropertyAll(Colors.teal.shade200),
            ),
          ),
        ))
      ],
    );
  }

  @override
  void dispose() {
    // Dispose of controllers and focus nodes to prevent memory leaks
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var row in focusNodes) {
      for (var focusNode in row) {
        focusNode.dispose();
      }
    }
    super.dispose();
  }

  void _moveFocus(int rowIndex, int colIndex) {
    if (colIndex < TableDataHelper.kTableColumnsList.length - 2) {
      FocusScope.of(context).requestFocus(focusNodes[rowIndex][colIndex + 1]);
    } else if (rowIndex < 13) {
      FocusScope.of(context).requestFocus(focusNodes[rowIndex + 1][0]);
    }
  }

  void _moveFocusBackwards() {
    for (var rowIndex = 0; rowIndex < focusNodes.length; rowIndex++) {
      for (var colIndex = 0;
          colIndex < focusNodes[rowIndex].length;
          colIndex++) {
        if (focusNodes[rowIndex][colIndex].hasFocus) {
          if (controllers[rowIndex][colIndex].text.isEmpty) {
            if (colIndex == 0 && rowIndex > 0) {
              FocusScope.of(context).requestFocus(focusNodes[rowIndex - 1]
                  [focusNodes[rowIndex - 1].length - 1]);
            } else if (colIndex > 0) {
              FocusScope.of(context)
                  .requestFocus(focusNodes[rowIndex][colIndex - 1]);
            }
          }
          return;
        }
      }
    }
  }
}
