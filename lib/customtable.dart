// ignore_for_file: deprecated_member_use
import 'package:cft_calculator/table_data_helper.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:flutter/services.dart';
import "package:expressions/expressions.dart";

class CustomTable extends StatefulWidget {
  const CustomTable({super.key});

  @override
  State<CustomTable> createState() => _CustomTableState();
}

class _CustomTableState extends State<CustomTable> {
  LinkedScrollControllerGroup controllerGroup = LinkedScrollControllerGroup();

  ScrollController? headerScrollController;
  ScrollController? dataScrollController;

  // List of FocusNodes for the TextFields in the data table
  List<List<FocusNode>> focusNodes = [];

  // List of TextEditingControllers for each cell
  List<List<TextEditingController>> controllers = [];

  // Variables to track the currently focused row and column
  int? focusedRowIndex;
  int? focusedColumnIndex;

  @override
  void initState() {
    super.initState();
    headerScrollController = controllerGroup.addAndGet();
    dataScrollController = controllerGroup.addAndGet();
    _initializeFocusNodes();
    _initializeControllers();
  }

  // Initialize FocusNodes for each row and column
  void _initializeFocusNodes() {
    focusNodes = List.generate(14, (rowIndex) {
      return List.generate(
        TableDataHelper.kTableColumnsList.length - 1,
        (colIndex) => FocusNode(),
      );
    });

    // Add listeners to update focusedRowIndex and focusedColumnIndex
    for (int rowIndex = 0; rowIndex < focusNodes.length; rowIndex++) {
      for (int colIndex = 0;
          colIndex < focusNodes[rowIndex].length;
          colIndex++) {
        focusNodes[rowIndex][colIndex].addListener(() {
          setState(() {
            if (focusNodes[rowIndex][colIndex].hasFocus) {
              focusedRowIndex = rowIndex;
              focusedColumnIndex = colIndex;
            }
          });
        });
      }
    }
  }

  // Initialize TextEditingControllers for each cell
  void _initializeControllers() {
    controllers = List.generate(14, (rowIndex) {
      return List.generate(
        TableDataHelper.kTableColumnsList.length -
            1, // Exclude the first column
        (colIndex) => TextEditingController(),
      );
    });
  }

  @override
  void dispose() {
    // Dispose of FocusNodes and TextEditingControllers to prevent memory leaks
    for (var row in focusNodes) {
      for (var focusNode in row) {
        focusNode.dispose();
      }
    }
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  // Function to handle arithmetic calculation based on the input text
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

          controllers[rowIndex][colIndex].text = "$result ($trimmedText)";
        } else {
          controllers[rowIndex][colIndex].text = "Invalid Expression";
        }
      } catch (e) {
        controllers[rowIndex][colIndex].text = "Error";
      }
    }
  }

// Function to check if the expression is valid
  bool _isValidExpression(String expression) {
    final validExpression = RegExp(r'^[\d+\-*/().\s]+$');
    return validExpression.hasMatch(expression);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CFT Table"),
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
                                                border: InputBorder.none,
                                              ),
                                              textAlign: TextAlign.center,
                                              textInputAction:
                                                  TextInputAction.next,
                                              onSubmitted: (_) {
                                                _handleCalculation(
                                                    index, colIndex);
                                                _moveFocus(index, colIndex);
                                              },
                                              keyboardType: TextInputType
                                                  .text, // Use the text keyboard
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(
                                                  RegExp(r'^[\d+\-*/().]*$'),
                                                ),
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
                            headingRowColor:
                                WidgetStatePropertyAll(Colors.teal.shade200),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            tableHeader()
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
