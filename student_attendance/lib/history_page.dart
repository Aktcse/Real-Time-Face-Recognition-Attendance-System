import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  HistoryPageState createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  List<File> csvFiles = [];
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Map<String, String> reportDates = {};

  @override
  void initState() {
    super.initState();
    loadCsvFiles();
    listenToFirestoreChanges();
  }

  void listenToFirestoreChanges() {
    firestore.collection('attendance').snapshots().listen((snapshot) {
      loadCsvFiles();
    });
  }

  Future<void> loadCsvFiles() async {
    Directory directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = directory.listSync();

    List<File> csvList =
    files
        .where((file) => file.path.endsWith('.csv'))
        .map((file) => File(file.path))
        .toList();

    // Sort files by full extracted datetime (newest first)
    csvList.sort(
          (a, b) => extractDateTimeFromFileName(b.path).compareTo(extractDateTimeFromFileName(a.path)),
    );

    Map<String, String> dates = {};
    for (var file in csvList) {
      String fileName = file.path.split('/').last;
      String extractedDate = extractFormattedDateFromFileName(fileName);
      dates[fileName] = extractedDate;
    }

    setState(() {
      csvFiles = csvList;
      reportDates = dates;
    });
  }

  DateTime extractDateTimeFromFileName(String filePath) {
    String fileName = filePath.split('/').last;
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
    return DateTime(1970, 1, 1); // Default fallback date for invalid format
  }

  String extractFormattedDateFromFileName(String fileName) {
    RegExp regex = RegExp(r'attendance_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\.csv');
    Match? match = regex.firstMatch(fileName);

    if (match != null) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int hour24 = int.parse(match.group(4)!);
      int minute = int.parse(match.group(5)!);
      int second = int.parse(match.group(6)!);

      // Convert 24-hour to 12-hour format with AM/PM
      final suffix = hour24 >= 12 ? 'PM' : 'AM';
      final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;

      // Format time as h:mm AM/PM (seconds omitted for cleaner look)
      String formattedTime = '$hour12:${minute.toString().padLeft(2, '0')} $suffix';

      // Format date as dd-MM-yyyy
      String formattedDate = '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year';

      return '$formattedDate $formattedTime';
    }
    return 'Unknown'; // Fallback if pattern doesn’t match
  }

  Future<int> getNumberOfRows(File file) async {
    try {
      List<String> lines = await file.readAsLines();
      return lines.length > 1 ? lines.length - 1 : 0;
    } catch (e) {
      debugPrint("Error reading file: $e");
      return 0;
    }
  }

  Future<void> saveReportDate(File file) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String fileName = file.path.split('/').last;
    String extractedDate = extractFormattedDateFromFileName(fileName);
    await prefs.setString(fileName, extractedDate);
  }

  Future<void> deleteCsvFile(File file) async {
    if (await file.exists()) {
      await file.delete();
      setState(() {
        csvFiles.remove(file);
      });
    }
  }

  Future<void> clearAllFiles() async {
    for (var file in csvFiles) {
      if (await file.exists()) {
        await file.delete();
      }
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      csvFiles.clear();
      reportDates.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.pinkAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Clear All Records"),
                content: Text(
                  "Are you sure you want to delete all history records?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      await clearAllFiles();
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/history.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          csvFiles.isNotEmpty
              ? ListView.builder(
            itemCount: csvFiles.length,
            itemBuilder: (context, index) {
              File file = csvFiles[index];
              String fileName = file.path.split('/').last;
              String reportDate = reportDates[fileName] ?? 'Unknown';
              return FutureBuilder<int>(
                future: getNumberOfRows(file),
                builder: (context, snapshot) {
                  int studentCount = snapshot.data ?? 0;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: ListTile(
                          title: Text(
                            fileName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.limeAccent,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(60),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          subtitle: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(60),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'Students: $studentCount | Report Date: $reportDate',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteCsvFile(file),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          )
              : Center(
            child: Text(
              'No records available',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                shadows: [
                  Shadow(color: Colors.black.withAlpha(60), blurRadius: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
