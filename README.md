# Custom Table Widget in Flutter

This Flutter project contains a custom table widget, `CustomTable`, which allows users to input and manipulate data within a grid of `TextField` cells. The table supports arithmetic calculations, dynamic focus handling, and scroll synchronization between the header and data rows.

## Features

- **Editable Table**: Each cell is a `TextField`, allowing users to input values or arithmetic expressions.
- **Arithmetic Evaluation**: Supports basic arithmetic operations like addition, subtraction, multiplication, and division. The result is shown immediately in the respective cell.
- **Focus Management**: Uses `FocusNode` for cell-level focus management. The table tracks the currently focused row and column.
- **Scroll Synchronization**: Horizontal scrolling is synchronized between the header and data rows.
- **Data Validation**: Supports validation of arithmetic expressions before evaluating them.
- **Customizable Table Columns**: The table columns are defined by `TableDataHelper.kTableColumnsList` and can be easily customized.

## Dependencies

- `flutter`: The Flutter SDK.
- `expressions`: A package to evaluate arithmetic expressions.
- `linked_scroll_controller`: For synchronizing scroll controllers.
- `flutter/services.dart`: For input validation and handling keyboard events.

## Setup

1. **Install Flutter**:
   - Make sure you have Flutter installed. Follow the official installation guide at [flutter.dev](https://flutter.dev/docs/get-started/install).

2. **Add Dependencies**:
   - In your `pubspec.yaml`, add the following dependencies:
     ```yaml
     dependencies:
       flutter:
         sdk: flutter
       linked_scroll_controller: ^1.0.0
       expressions: ^0.2.8
     ```

3. **Run the Application**:
   - Clone the repository and navigate to the project directory.
   - Run the app using the following command:
     ```bash
     flutter run
     ```

## Widget Overview

### `CustomTable`

This widget is a stateful widget that displays a table with dynamic cells and interactive features.

- **Initialization**: 
  - The widget initializes `FocusNode` and `TextEditingController` objects for each cell in the table.
  - The columns are defined using `TableDataHelper.kTableColumnsList`.

- **Focus Management**:
  - Focus is managed using `FocusNode` and listeners update the `focusedRowIndex` and `focusedColumnIndex`.

- **Text Input Handling**:
  - The `TextField` in each table cell allows users to input values or arithmetic expressions. The `TextEditingController` is used to manage the input.

- **Arithmetic Calculation**:
  - When the user enters an expression, the input is validated and evaluated using the `expressions` package. The result is displayed in the cell.

- **Scroll Synchronization**:
  - The table header and data rows are connected via the `LinkedScrollControllerGroup` to ensure smooth synchronization while scrolling horizontally.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- The `expressions` package is used for evaluating arithmetic expressions.
- The `linked_scroll_controller` package helps synchronize scroll controllers.
