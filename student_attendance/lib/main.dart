import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dashboard.dart'; // Import Dashboard
import 'splash_screen.dart'; // Import SplashScreen
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'admin_login.dart';
import 'teacher_login.dart';
import 'role_selection.dart';
import 'secondary_splash.dart';
import 'student_upload_page.dart';


final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
List<CameraDescription> cameras = []; // Global variable for cameras

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Moved before Firebase initialization

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,                    // ✅ White status bar background
    statusBarIconBrightness: Brightness.light,        // ✅ Dark icons (for contrast on white)
    systemNavigationBarColor: Colors.black,          // Optional: white nav bar too
    systemNavigationBarIconBrightness: Brightness.light,
  ));


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    cameras = await availableCameras(); // ✅ Assign to global variable after Firebase init
  } catch (e) {
    cameras = []; // ✅ Fail-safe mechanism
  }

  runApp(MyApp(cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp(this.cameras, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(cameras), // ✅ Pass cameras to SplashScreen
      navigatorObservers: [routeObserver],
      routes: {
        // '/login': (context) => LoginPage(), // ✅ Ensure LoginPage accepts cameras if needed
        '/role': (context) => RoleSelectionPage(),
        '/secondary': (context) => SecondarySplashPage(),
        '/admin': (context) => AdminLoginPage(),
        '/teacher': (context) => TeacherLoginPage(),
        '/dashboard': (context) => AttendanceDashboard(cameras), // ✅ Ensure Dashboard supports cameras
        '/upload': (context) => UploadStudentPage(),
      },
    );
  }
}
