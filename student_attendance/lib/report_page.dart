import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportPage extends StatefulWidget {
  final String reportType; // Identifies if it's daily or monthly


  const ReportPage({super.key,required this.reportType}) ;

  @override
  ReportPageState createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  String? selectedDateOrMonth; // Holds the selected date or month
  bool isPanelOpen = false; // Controls panel visibility
  bool hasRecords = false; // Simulates whether records exist
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<File> csvFiles = [];

  @override
  void initState() {
    super.initState();
    listenToFirestoreChanges();
  }

// Listen to Firestore for real-time updates
  void listenToFirestoreChanges() {
    firestore.collection('attendance').snapshots().listen((snapshot) {
      createCsvFilesForEachRecord(snapshot.docs);
    });
  }

// Create CSV files from Firestore records
  Future<void> createCsvFilesForEachRecord(
      List<QueryDocumentSnapshot> docs) async {
    Directory directory = await getApplicationDocumentsDirectory();
    List<File> updatedFiles = [];

    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data.isEmpty) continue;

// Ensure the CSV has three fixed columns
      List<List<dynamic>> csvData = [
        ["Name", "Registration No.","Branch", "Time"] // Fixed CSV Header
      ];

// Extract student records and format correctly
      data.forEach((key, value) {
        if (key != "uploadedAt" && value is Map<String, dynamic>) {
          csvData.add([
            value["name"] ?? "N/A",
            value["reg_no"] ?? "N/A",
            value["branch"] ?? "N/A",
            value["time"] ?? "N/A"
          ]);
        }
      });

// Convert to CSV format and save
      String csvString = const ListToCsvConverter().convert(csvData);
      String fileName =
          '${doc.id}.csv'; // Ensure filename matches Firestore doc ID
      String filePath = '${directory.path}/$fileName';
      File csvFile = File(filePath);
      await csvFile.writeAsString(csvString);
      updatedFiles.add(csvFile);
    }

    setState(() {
      csvFiles = updatedFiles;
      hasRecords = csvFiles.isNotEmpty; // Update record status
    });
  }

// Download the CSV file to the device


  Future<void> downloadCsvFile(BuildContext context, File file) async {
    // Request storage permission if needed
    if (Platform.isAndroid) {
      var permissionStatus = await Permission.manageExternalStorage.status;

      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        var status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Storage permission is required to download files.")),
          );
          return;
        }
      }
    }

    // Get the correct download directory
    Directory? downloadDirectory = await _getDownloadDirectory();
    if (downloadDirectory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to access the download directory.")),
      );
      return;
    }

    // Create a unique file name
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    String newFilePath = '${downloadDirectory.path}/CSV_${timestamp}.csv';
    File newFile = File(newFilePath);

    // Write the CSV file to the download folder
    await newFile.writeAsBytes(await file.readAsBytes());

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("File downloaded to ${newFile.path}")),
    );

    // Open the file after downloading
    _showOpenWithDialog(context, newFile);
  }

  void _showOpenWithDialog(BuildContext context, File file) {
    bool dontAskAgain = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black, // Black background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Open With",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.file_copy, color: Colors.yellow, size: 32),
                  title: Text("CSV Viewer", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    OpenFile.open(file.path);
                    Navigator.pop(context);
                  },
                ),
                CheckboxListTile(
                  value: dontAskAgain,
                  activeColor: Colors.yellow,
                  checkColor: Colors.black,
                  title: Text("Don't Ask Again", style: TextStyle(color: Colors.white)),
                  onChanged: (value) {
                    setState(() {
                      dontAskAgain = value ?? false;
                    });
                  },
                ),
                Divider(color: Colors.white54), // Light divider for visibility
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.yellow)),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.download, color: Colors.yellow),
                      label: Text("Download More", style: TextStyle(fontSize: 16, color: Colors.white)),
                      onPressed: () async {
                        String url = Platform.isAndroid
                            ? "https://play.google.com/store/search?q=csv+viewer"
                            : "https://apps.apple.com/us/search?term=csv+viewer";
                        Uri uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }


  Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      Directory directory = Directory('/storage/emulated/0/Download'); // Standard Download folder
      if (await directory.exists()) {
        return directory;
      } else {
        return await getExternalStorageDirectory(); // Fallback
      }
    }
    return await getApplicationDocumentsDirectory(); // iOS
  }




// Open the CSV file
  Future<void> openCsvFile(File file) async {
    await OpenFile.open(file.path);
  }

// Delete the CSV file
  Future<void> deleteCsvFile(File file) async {
    if (await file.exists()) {
      await file.delete();
      setState(() {
        csvFiles.remove(file);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.pinkAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(
              'Report',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                setState(() {
                  isPanelOpen = !isPanelOpen;
                });
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      selectedDateOrMonth ?? 'Select an option from the menu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: hasRecords
                          ? _buildRecordsView() // Show records if available
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off,
                              size: 60, color: Colors.white70),
                          SizedBox(height: 10),
                          Text(
                            'No records are available',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            left: isPanelOpen ? 0 : -220,
            top: 0,
            bottom: 0,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.pink.shade100, Colors.orange.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  // Add image at the top of the side panel
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/images/report.png',  // Replace with your image asset path
                      width: 120,  // Define the width of the image
                      height: 120, // Define the height of the image
                      fit: BoxFit.cover,  // Adjust the image scaling
                    ),
                  ),

                  _buildOption('Day', Icons.date_range, _selectDate),
                  _buildOption('Month', Icons.calendar_today, _selectMonth),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/images/report3.png',  // Replace with your image asset path
                      width: 150,  // Define the width of the image
                      height: 150, // Define the height of the image
                      fit: BoxFit.cover,  // Adjust the image scaling
                    ),
                  ),

                  Spacer(), // Pushes Reset & Close buttons to the bottom

                  // RESET BUTTON (Just Above the Close button)
                  if (selectedDateOrMonth != null && selectedDateOrMonth!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(Icons.refresh, color: Colors.yellowAccent),
                        label: Text(
                          "Reset",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedDateOrMonth = null; // Reset filter
                          });
                        },
                      ),
                    ),

                  // CLOSE BUTTON (Below the Reset button)
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        isPanelOpen = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          )



        ],
      ),
    );
  }

  Widget _buildOption(String text, IconData icon, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

// Show date picker for day selection
  void _selectDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.indigo,
            colorScheme: ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              surface: Colors.cyanAccent,
              onSurface: Colors.black87,
            ),
            // dialogBackgroundColor: Colors.blueGrey.shade50,
            dialogTheme: DialogTheme(backgroundColor: Colors.blueGrey.shade50),
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontWeight: FontWeight.bold), // Bold numbers
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        selectedDateOrMonth = DateFormat('yyyy-MM-dd').format(selectedDate);
        isPanelOpen = false;
      });
    }
  }

// Show month picker for month selection
  void _selectMonth() async {
    DateTime now = DateTime.now();
    int currentYear = now.year;

    int? selectedMonth = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor:
          Colors.deepPurple.shade900, // Modern attractive background
          title: Center(
            child: Text(
              'Select a Month',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 12,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.blue, // Stylish modern color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Center(
                      child: Text(
                        DateFormat('MMMM').format(DateTime(0, index + 1)),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop(index + 1);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedMonth != null) {
      setState(() {
        selectedDateOrMonth =
        '${DateFormat('MMMM').format(DateTime(0, selectedMonth))} $currentYear';
        isPanelOpen = false;
      });
    }
  }

// Display the list of CSV files in a ListView
  Widget _buildRecordsView() {
    List<File> filteredFiles = csvFiles;

    if (selectedDateOrMonth != null && selectedDateOrMonth!.isNotEmpty) {
      filteredFiles = csvFiles.where((file) {
        String fileName = file.path.split('/').last; // Extract file name

// Extract the date portion (YYYYMMDD) from file names like attendance_YYYYMMDD_HHMMSS.csv
        RegExp regex = RegExp(r'attendance_(\d{8})_\d{6}\.csv');
        Match? match = regex.firstMatch(fileName);

        if (match != null) {
          String fileDate = match.group(1)!; // Extracted YYYYMMDD

          if (selectedDateOrMonth!.contains('-')) {
// Case: Day Selection (YYYY-MM-DD)
            String formattedDate =
            selectedDateOrMonth!.replaceAll('-', ''); // Convert to YYYYMMDD
            return fileDate == formattedDate;
          } else {
// Case: Month Selection (e.g., "March 2025")
            int selectedMonth =
                DateFormat('MMMM yyyy').parse(selectedDateOrMonth!).month;
            int selectedYear =
                DateFormat('MMMM yyyy').parse(selectedDateOrMonth!).year;

            int fileYear = int.parse(fileDate.substring(0, 4));
            int fileMonth = int.parse(fileDate.substring(4, 6));

            return fileYear == selectedYear && fileMonth == selectedMonth;
          }
        }
        return false; // Ignore files without a proper date format
      }).toList();
    }

    return Column(
      children: [
// If no files match the filter, show "No records available"
        if (filteredFiles.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 60, color: Colors.white70),
                  SizedBox(height: 10),
                  Text(
                    "No records available for $selectedDateOrMonth",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filteredFiles.length,
              itemBuilder: (context, index) {
                File file = filteredFiles[index];
                String fileName = file.path.split('/').last;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    title: Text(fileName,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: FutureBuilder<String>(
                      future: file.readAsString(),
                      builder: (context, snapshot) {
                        String fileContent = snapshot.data ?? "Loading...";
                        return Text(fileContent,
                            maxLines: 3, overflow: TextOverflow.ellipsis);
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.download, color: Colors.green),
                          onPressed: () => downloadCsvFile(context, file),
                        ),
                        IconButton(
                          icon: Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => openCsvFile(file),
                        ),
                        // IconButton(
                        //   icon: Icon(Icons.delete, color: Colors.red),
                        //   onPressed: () => deleteCsvFile(file),
                        // ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool confirmed = await _showDeleteConfirmation(context);
                            if (confirmed) {
                              await deleteAttendanceRecord(file);
                            }
                          },
                        ),

                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> deleteAttendanceRecord(File file) async {
    String fileName = file.path.split('/').last;
    String documentId = fileName.replaceAll('.csv', '');

    try {
      await firestore.collection('attendance').doc(documentId).delete();


      setState(() {
        csvFiles.remove(file);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Attendance record deleted successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete record: $e")),
      );
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Confirmation"),
        content: Text("Are you sure you want to delete this attendance record permanently?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ??
        false;
  }
}
