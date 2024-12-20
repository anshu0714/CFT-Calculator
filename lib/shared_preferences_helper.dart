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
        // Only include non-null and non-empty cells
        if ((cell is String && cell.isEmpty)) {
          return false; // Skip empty or null cells
        }
        return true; // Include valid cells
      }).toList();
    }).toList();

    // Convert to JSON and save only non-empty data
    String jsonData = jsonEncode(validatedData);
    await prefs.setString(tableKey, jsonData);
  }

  // Retrieve the full table data with metadata (e.g., length, width, etc.)
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
                return <String, dynamic>{}; // Empty map if invalid
              }
            }).toList();
          } else {
            return <Map<String, dynamic>>[]; // Empty row if invalid
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
        // Handle decoding error if data format is corrupted
        print("Error decoding display data: $e");
        return [];
      }
    }

    // Return an empty table or default structure if no data exists
    return List.generate(14, (index) => List.filled(10, ""));
  }

  // Clear all saved table data (for both display and metadata)
  static Future<void> clearTableData(String tableKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tableKey);
  }

  static Future<List<Map<String, dynamic>>> getSheetsData(
      String partyName) async {
    List<Map<String, dynamic>> sheetsData = []; // Example data format
    // Fetch data from shared preferences here and decode it
    // Example:
    // sheetsData = await someSharedPrefInstance.get('party_sheets_$partyName');
    return sheetsData;
  }
}
