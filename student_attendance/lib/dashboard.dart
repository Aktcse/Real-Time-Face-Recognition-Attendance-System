import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:camera/camera.dart';
import 'role_selection.dart';
import 'report_page.dart';
import 'history_page.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'camera_screen.dart';
import 'dart:async';
import 'package:marquee/marquee.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'attendance_helper.dart'; // Import the helper file

class AttendanceDashboard extends StatefulWidget {
  final List<CameraDescription> cameras; // Pass cameras list

  const AttendanceDashboard(this.cameras, {super.key});

  @override
  AttendanceDashboardState createState() => AttendanceDashboardState();
}

class AttendanceDashboardState extends State<AttendanceDashboard> {
  final PageController _pageController = PageController();
  late VideoPlayerController _controller;
  int totalStudentsPresent = 0;

  String latestDate = '';
  int studentCount = 0;
  bool isLoading = true;

  bool _showSuccessPopupNextSubmit = false;


  int _currentPage = 0;
  late Timer _timer;

  final List<Map<String, String>> _slides = [
    {"image": 'assets/images/slide/ai-based-face.png', "title": "Welcome To Dashboard"},
    {"image": 'assets/images/slide/mouse-recorder-3.png', "title": "Smart Face Attendance"},
    {"image": 'assets/images/slide/classroom.jpg', "title": "AI-Powered Classroom Attention Monitoring"},
    {"image": 'assets/images/slide/rock-solid-measures.jpg', "title": "Advanced Biometric Authentication for Secure Access"},
    {"image": 'assets/images/slide/Sca01.jpg', "title": "Smart Classroom Attendance with Facial Recognition"},
    {"image": 'assets/images/slide/cloud.jpeg', "title": "Secure Storage with Firebase"},
    {"image": 'assets/images/slide/management.jpeg', "title": "Smart AI Analytics"},
    {"image": 'assets/images/slide/verify.jpg', "title": "Facial ID Verification"},
  ];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/dash_vid.mp4')
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
    _startAutoSlide();
    fetchLatestAttendance();
  }

  Future<void> fetchLatestAttendance() async {
    final latestInfo = await AttendanceHelper.getLatestAttendanceInfo();
    if (latestInfo != null) {
      setState(() {
        latestDate = latestInfo['date'];
        studentCount = latestInfo['studentCount'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_currentPage < _slides.length - 1) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(seconds: 3),
          curve: Curves.easeInOutCubic,
        );
      } else {
        // Pause on the last slide before resetting
        Future.delayed(Duration(seconds: 5), () {
          _currentPage = 0;
          _pageController.jumpToPage(0); // Instantly go to first slide
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents default back navigation
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        bool shouldPop = await _showBackDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackgroundImage(),
            _buildOverlay(),
            // Foreground UI layout
            Column(
              children: [
                // Scrollable + static content combined
                Expanded(child: _buildContent(context)),
                // Fixed bottom buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                  child: _buildBottomButtons(context),
                ),
                // _buildBottomButtons(context),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // Builds the background image container.
  Widget _buildBackgroundImage() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/dashboard/face.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Adds a semi-transparent overlay to darken the background.
  Widget _buildOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withAlpha(50),
    );
  }

  // Contains the main content, including the title, attendance section, and scrollable content
  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50),
          _buildTitle(),
          SizedBox(height: 20),
          _buildAttendanceSection(context),
          Divider(
            color: Colors.deepOrangeAccent,
            thickness: 1,
          ),

          // Only this part scrolls
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 1),
              children: [
                _buildScrollableContent(context),
                // SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // Displays the main dashboard title.
  Widget _buildTitle() {
    return Center(
      child: Text(
        'Dashboard',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // Contains the attendance label and the user icon button.
  Widget _buildAttendanceSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Student Attendance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Padding(padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                _showUserPopup(context);
              },
              child: Icon(Icons.person, color: Colors.yellowAccent, size: 24.0),
            ),
          ),
        ],
      ),
    );
  }

  // Handles the scrollable section of the screen, including carousels and marquee text.
  Widget _buildScrollableContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          _buildMarquee(),
          SizedBox(height: 10),
          _buildImageCarousel(),
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: _buildStartFaceRecognitionButton(context),
          ),
          SizedBox(height: 10),
          studentPresenceBox(isLoading, studentCount, latestDate, Colors.lightGreenAccent),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: _studentdata(context),
          ),
          SizedBox(height: 10),
          buildMyImage1(),
          buildMyImage2(context),
          buildMyImage3(),
          buildMyVideo1(),
        ],
      ),
    );
  }



  // Builds the image carousel with a smooth page indicator.
  Widget _buildImageCarousel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withAlpha(70), blurRadius: 2),
        ],
      ),
      padding: EdgeInsets.all(6),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            _slides[index]["image"]!,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            color: Colors.black.withAlpha((0.3 * 255).toInt()),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(
                              16,
                            ), // Adjust padding as needed
                            child: Align(
                              alignment:
                              Alignment
                                  .bottomLeft, // Align it to the bottom left
                              child: Text(
                                _slides[index]["title"]!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          SmoothPageIndicator(
            controller: _pageController,
            count: _slides.length,
            effect: WormEffect(
              activeDotColor: Colors.blueAccent,
              dotColor: Colors.white.withAlpha(100),
              dotHeight: 12,
              dotWidth: 12,
              spacing: 8,
            ),
          ),
        ],
      ),
    );
  }

  // Adds the scrolling marquee text.
  Widget _buildMarquee() {
    return Padding(
      padding: const EdgeInsets.only(top: 1.0),
      child: Center(
        child: SizedBox(
          height: 30,
          child: Container(
            // padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(180), // Semi-transparent background
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Marquee(
              text:
              'AI Based Attendance System   +   Automates the attendance process   +   Time-Saving  +  Accuracy and Reliability ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: 100.0,
              velocity: 50.0,
              pauseAfterRound: Duration(seconds: 1),
              startPadding: 10.0,
              accelerationDuration: Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          ),
        ),
      ),
    );
  }

  // Builds the button to navigate to the face recognition screen.
  Widget _buildStartFaceRecognitionButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          // final result = await Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => FaceCameraPage()),
          // );

          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const FaceCameraPage()),
          );

          if (result == true) {
            setState(() {
              _showSuccessPopupNextSubmit = true;
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Remove default color
          shadowColor: Colors.blueAccent, // Add shadow for 3D effect
          elevation: 35, // Elevation for 3D look
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Rounded corners
          ),
          padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 40.0),
          // side: BorderSide(color: Colors.blueAccent, width: 2), // Border color
          textStyle: TextStyle(
            fontWeight: FontWeight.bold, // Bold text
            fontSize: 18, // Increase text size
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: 250, maxHeight: 55),
            alignment: Alignment.center,
            child: Text(
              "Start Face Recognition",
              style: TextStyle(
                color: Colors.white, // White text color
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget studentPresenceBox(bool isLoading, int studentCount, String latestDate, Color textColor) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : latestDate.isNotEmpty
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Number of Students Present: $studentCount",
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Date: $latestDate",
            style: TextStyle(
              color: Colors.amber,
              fontSize: 14,
            ),
          ),
        ],
      )
          : Text(
        'No attendance records found.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }



  Widget _studentdata(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/upload'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
          shadowColor: Colors.deepPurpleAccent.withAlpha(50),
          backgroundColor: Colors.transparent,
          // Remove default background color
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blueAccent,
                Colors.cyanAccent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.indigoAccent.withAlpha(100),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            constraints: BoxConstraints(minWidth: 200, minHeight: 55),
            alignment: Alignment.center,
            child: Text(
              'Student Data',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.1,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget buildMyImage1() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30.0, 10.0, 0.0, 2.0),
      child: Center(
        child: Image.asset(
          'assets/images/dashboard/dash3.png',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }


  // Function to build the widget with onTap behavior
  Widget buildMyImage2(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(30),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                final youtubeUrl = Uri.parse('https://youtu.be/YX8BzK_LU0E');

                final canLaunch = await canLaunchUrl(youtubeUrl);
                debugPrint('Can launch YouTube URL: $canLaunch');

                if (canLaunch) {
                  final success = await launchUrl(
                    youtubeUrl,
                    mode: LaunchMode.externalApplication,
                  );
                  debugPrint('Launch success: $success');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open YouTube video.')),
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  'assets/images/dashboard/dash1.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: AnimatedTextKit(
                repeatForever: true,
                pause: const Duration(seconds: 20),
                animatedTexts: [
                  TypewriterAnimatedText(
                    'A smart and secure face recognition system that instantly identifies individuals with precision, convenience, and confidence.',
                    textStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                    speed: const Duration(milliseconds: 100),
                    cursor: '|',
                  ),
                ],
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildMyImage3() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(30),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animated typewriter text on the left
            Expanded(
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'A fast, beautiful, and cross-platform Flutter app built with Android Studio—bringing seamless performance and sleek UI to your fingertips!',
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                    speed: const Duration(milliseconds: 100),
                    cursor: '|',
                  ),
                ],
                repeatForever: true,
                pause: const Duration(seconds: 20), // Pause between loops
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
              ),
            ),

            const SizedBox(width: 12),

            // Clickable image on the right
            GestureDetector(
              onTap: () async {
                final docUrl = Uri.parse('https://flutter.dev/multi-platform/mobile'); // Your link here

                if (await canLaunchUrl(docUrl)) {
                  await launchUrl(docUrl, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch $docUrl';
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  'assets/images/dashboard/dash2.png',
                  width: 175,
                  height: 175,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildMyVideo1() {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Center(
        child: _controller.value.isInitialized
            ? Container(
          width: 500,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(200), // Semi-transparent background
            borderRadius: BorderRadius.circular(20.0), // Curved edges
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0), // Curves the video as well
            child: Opacity(
              opacity: 0.8, // Apply opacity to the whole container
              child: SizedBox.expand(
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        )
            : CircularProgressIndicator(),
      ),
    );
  }



  // Contains the buttons at the bottom of the screen, like "History", "Report", and "Submit".
  Widget _buildBottomButtons(BuildContext context) {
    // final args = ModalRoute.of(context)?.settings.arguments;
    // final fromPage = args is String ? args : null;
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.0),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            // color: Colors.white.withAlpha(400),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.yellowAccent, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.transparent.withAlpha(500),
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBottomButton(context, Icons.history, 'History', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(),
                  ),
                );
              }),
              SizedBox(width: 10),
              _buildBottomButton(context, Icons.flag, 'Report', () {
                _showReportOptions(context);
              }),
              SizedBox(width: 10),
              _buildBottomButton(context, Icons.send, 'Submit', () {
                if (_showSuccessPopupNextSubmit) {
                  _showSuccessDialoge(context);
                  setState(() {
                    _showSuccessPopupNextSubmit = false; // Reset
                  });
                }
                else{
                  // Optionally show message or do nothing
                  print("Submit tapped but not after FaceCameraPage.");
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialoge(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: const Text('Student data uploaded successfully 💐💐!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }



// A helper function that builds each individual button in the bottom section.
  Widget _buildBottomButton(BuildContext context, IconData icon, String text, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.indigoAccent,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Confirmation Dialog on Back Press
  Future<bool> _showBackDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Text(
            'You are still logged in. Do you want to go back without logging out?',
          ),
          actions: [
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ??
        false;
  }

  // Function to show report options

  void _showReportOptions(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allows tapping outside to close
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Select Report Type',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),

                // Report Upload Option
                InkWell(
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _uploadCsvToFirestore();
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent.withAlpha(50),
                      child: Icon(Icons.cloud_upload, color: Colors.blueAccent),
                    ),
                    title: Text(
                      'Report Upload',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  ),
                ),
                Divider(thickness: 1),

                // Report Download Option
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportPage(reportType: 'download'),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.greenAccent.withAlpha(50),
                      child: Icon(Icons.download_for_offline, color: Colors.green),
                    ),
                    title: Text(
                      'Report Download',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  ),
                ),
                Divider(thickness: 1),

                // Close Button
                SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.pink,
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  Future<void> _uploadCsvToFirestore() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No file selected!')));
        return;
      }

      // Extract file path and name
      String filePath = result.files.single.path!;
      File file = File(filePath);
      String fileName =
          result.files.single.name; // Example: attendance_20250623_234512.csv

      // Remove the ".csv" extension to get the document ID
      String documentId = fileName.replaceAll('.csv', '');

      // Read CSV file content
      String fileContent = await file.readAsString();
      List<List<dynamic>> csvData = const CsvToListConverter().convert(
        fileContent,
      );

      if (csvData.isEmpty || csvData.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV file is empty or only contains headers!'),
          ),
        );
        return;
      }

      // Prepare data map
      Map<String, dynamic> attendanceData = {
        'uploadedAt': FieldValue.serverTimestamp(),
      };

      for (int i = 1; i < csvData.length; i++) {
        if (csvData[i].length < 3) continue;

        String name = csvData[i][0].toString().trim();
        String regNo = csvData[i][1].toString().trim();
        String time = csvData[i][2].toString().trim();

        if (name.isEmpty || regNo.isEmpty || time.isEmpty) continue;

        // Store data as student_1, student_2, etc.
        attendanceData["student_$i"] = {
          'name': name,
          'reg_no': regNo,
          'time': time,
        };
      }

      // Upload to Firestore with document ID same as CSV file name (without .csv)
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(documentId)
          .set(attendanceData);

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading CSV: $e')));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload Successful'),
          content: Text('The CSV file has been uploaded successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to show user popup////
  void _showUserPopup(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String loginId = prefs.getString('loginId') ?? 'Guest';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_circle, size: 60, color: Colors.blueAccent),
              SizedBox(height: 10),
              Text(
                loginId,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),

                      shadowColor: Colors.red.withAlpha(50), // Simple shadow
                      elevation: 5, // Elevation for shadow effect
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Sign Out',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      await prefs.remove('loginId');
                      await prefs.remove('isLoggedIn');

                      if (!context.mounted) return;

                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => RoleSelectionPage()),
                            (route) => false,
                      );
                    },
                  ),
                ),
                SizedBox(width: 10), // Space between buttons
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      shadowColor: Colors.blue.withAlpha(50), // Simple shadow
                      elevation: 5, // Elevation for shadow effect
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Close',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
