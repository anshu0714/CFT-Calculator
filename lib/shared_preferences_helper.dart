import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPreferencesHelper {
  // Save the full table data with metadata (e.g., length, width, etc.)
  static Future<void> saveTableDataWithMetadata(
      String tableKey, List<List<Map<String, dynamic>>> tableData) async {
    final prefs = await SharedPreferences.getInstance();

    // Filter out empty or null cells before saving
    List<List<Map<String, dynamic>>> validatedData = tableData.map((row) {
      return row.where((cell) {
        if ((cell is String && cell.isEmpty)) {
          return false;
        }
        return true;
      }).toList();
    }).toList();

    String jsonData = jsonEncode(validatedData);
    await prefs.setString(tableKey, jsonData);
  }

  // Retrieve the full table data with metadata (e.g., length, width, etc.)
  static Future<List<List<Map<String, dynamic>>>> getTableDataWithMetadata(
      String tableKey) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString(tableKey);

    if (jsonData != null) {
      try {
        List<dynamic> decodedData = jsonDecode(jsonData);

        return decodedData.map((row) {
          if (row is List) {
            return row.map((cell) {
              // Only return valid cells
              if (cell is Map<String, dynamic>) {
                return cell;
              } else {
                return <String, dynamic>{};
              }
            }).toList();
          } else {
            return <Map<String, dynamic>>[];
          }
        }).toList();
      } catch (e) {
        print("Error decoding metadata data: $e");
        return [];
      }
    }

    return [];
  }

  // Save only the display data (strings) for the table
  static Future<void> saveTableDataForDisplay(
      List<List<String>> tableData, String tableKey) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonData = jsonEncode(tableData);
    await prefs.setString(tableKey, jsonData);
  }

  // Retrieve the display data (strings only) for the table
  static Future<List<List<String>>> getTableDataForDisplay(
      String tableKey) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString(tableKey);

    if (jsonData != null) {
      try {
        List<dynamic> decodedData = jsonDecode(jsonData);
        return decodedData.map((row) {
          return List<String>.from(row.map((e) => e.toString()));
        }).toList();
      } catch (e) {
        print("Error decoding display data: $e");
        return [];
      }
    }

    return List.generate(14, (index) => List.filled(10, ""));
  }

  // Clear all saved table data (for both display and metadata)
  static Future<void> clearTableData(String tableKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tableKey);
  }

  // Add table key to the list
  static Future<void> addTableKey(String tableKey) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> tableKeys = prefs.getStringList('table_keys') ?? [];
    if (!tableKeys.contains(tableKey)) {
      tableKeys.add(tableKey);
      await prefs.setStringList('table_keys', tableKeys);
    }
  }

// Retrieve all saved table keys
  static Future<List<String>> getTableKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('table_keys') ?? [];
  }

// Remove a table key from the list
  static Future<void> removeTableKey(String tableKey) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> tableKeys = prefs.getStringList('table_keys') ?? [];
    tableKeys.remove(tableKey);
    await prefs.setStringList('table_keys', tableKeys);
  }
}
