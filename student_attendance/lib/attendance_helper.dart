import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AttendanceHelper {
  /// Fetches the latest attendance file info with date, student count, and filename.
  static Future<Map<String, dynamic>?> getLatestAttendanceInfo() async {
    try {
      Directory directory = await getApplicationDocumentsDirectory();
      List<FileSystemEntity> files = directory.listSync();

      List<File> csvFiles = files
          .where((file) => file.path.endsWith('.csv'))
          .map((file) => File(file.path))
          .toList();

      if (csvFiles.isEmpty) return null;

      // Sort by full datetime extracted from filename (newest first)
      csvFiles.sort((a, b) => _extractDateTime(b.path).compareTo(_extractDateTime(a.path)));

      File latestFile = csvFiles.first;
      String fileName = latestFile.path.split('/').last;

      // Read lines to get student count (excluding header)
      List<String> lines = await latestFile.readAsLines();
      int studentCount = lines.length > 1 ? lines.length - 1 : 0;

      // Format the date as dd-MM-yyyy HH:mm:ss
      String date = _formatDate(fileName);

      return {
        'date': date,
        'studentCount': studentCount,
        'fileName': fileName,
      };
    } catch (e) {
      print('Error fetching latest attendance info: $e');
      return null;
    }
  }

  // Extracts full DateTime (including hours, minutes, seconds) from filename.
  static DateTime _extractDateTime(String path) {
    String fileName = path.split('/').last;
    // Regex matches filenames like attendance_20240519_153045.csv
    RegExp regex = RegExp(r'attendance_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\.csv');
    Match? match = regex.firstMatch(fileName);
    if (match != null) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour = int.parse(match.group(4)!);
      int minute = int.parse(match.group(5)!);
      int second = int.parse(match.group(6)!);
      return DateTime(year, month, day, hour, minute, second);
    }
    return DateTime(1970, 1, 1); // Fallback date
  }

  /// Formats the date and time extracted from filename as a readable string.
  static String _formatDate(String fileName) {
    RegExp regex = RegExp(r'attendance_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\.csv');
    Match? match = regex.firstMatch(fileName);

    if (match != null) {
      int hour24 = int.parse(match.group(4)!);
      int minute = int.parse(match.group(5)!);
      int day = int.parse(match.group(3)!);
      int month = int.parse(match.group(2)!);
      int year = int.parse(match.group(1)!);

      final suffix = hour24 >= 12 ? 'PM' : 'AM';
      final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;

      String formattedTime = '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
      String formattedDate = '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year';

      return '$formattedDate $formattedTime';
    }


    return 'Unknown';
  }
}
