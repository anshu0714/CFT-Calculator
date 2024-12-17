import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPreferencesHelper {
  static Future<void> saveTableData(List<List<String>> tableData, String tableKey) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonData = jsonEncode(tableData);
    await prefs.setString(tableKey, jsonData);
  }

  static Future<List<List<String>>> getTableData(String tableKey) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString(tableKey);
    if (jsonData != null) {
      List<dynamic> decodedData = jsonDecode(jsonData);
      return decodedData.map((row) => List<String>.from(row)).toList();
    }
    return []; 
  }

  static Future<void> clearTableData(String tableKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tableKey);
  }
}
