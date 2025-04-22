import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class FileUtils {
  // Export and share a quiz as JSON
  static Future<void> shareQuizAsJson(Map<String, dynamic> quizData, String quizTitle) async {
    try {
      // Convert to JSON
      final jsonString = jsonEncode(quizData);
      
      // Create a formatted file name
      final fileName = '${quizTitle.replaceAll(' ', '_').toLowerCase()}_${DateFormat('yyyyMMdd').format(DateTime.now())}.json';
      
      // Get temp directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      
      // Write the file
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Kahoot Quiz: $quizTitle',
        text: 'Here is my Kahoot quiz! You can import it into your Kahoot app.'
      );
    } catch (e) {
      print('Error sharing quiz as JSON: $e');
      rethrow;
    }
  }
  
  // Parse a JSON file into quiz data
  static Future<Map<String, dynamic>?> parseQuizJsonFile(File file) async {
    try {
      // Read the file
      final jsonString = await file.readAsString();
      
      // Parse the JSON
      final jsonData = jsonDecode(jsonString);
      
      // Validate expected structure
      if (jsonData is Map<String, dynamic> && 
          jsonData.containsKey('quiz') && 
          jsonData.containsKey('questions')) {
        return jsonData;
      } else {
        throw FormatException('Invalid quiz JSON format');
      }
    } catch (e) {
      print('Error parsing quiz JSON: $e');
      return null;
    }
  }
} 