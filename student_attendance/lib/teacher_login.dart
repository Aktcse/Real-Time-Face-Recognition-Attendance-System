import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});
  @override
  TeacherLoginPageState createState() => TeacherLoginPageState();
}

class TeacherLoginPageState extends State<TeacherLoginPage> with RouteAware {
  final TextEditingController loginIdController2 = TextEditingController();
  final TextEditingController passwordController2 = TextEditingController();
  bool _passwordVisible1 = false;

  final List<Map<String, String>> usersLogin2 = [
    {'loginId': 'user2@example.com', 'password': 'password2'},
    {'loginId': 'user2b@example.com', 'password': 'passwordB2'},
    {'loginId': 'user2c@example.com', 'password': 'passwordC2'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      _showContinueDialog();
    } else {
      setState(() {
        loginIdController2.clear();
        passwordController2.clear();
      });
    }
  }

  void _showContinueDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logged In'),
          content: Text('You are still logged in. Do you want to continue?'),
          actions: [
            TextButton(
              child: Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AttendanceDashboard([])),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/login/GCE_College.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              color: Colors.black.withAlpha(150),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/login/login.png',
                      height: 200,
                    ),
                    Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'This is Teachers login page',
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: <Color>[
                                  Colors.orange,
                                  Colors.pink,
                                  Colors.purple,
                                  Colors.blue,
                                  Colors.green,
                                ],
                              ).createShader(Rect.fromLTWH(0.0, 0.0, 400.0, 70.0)),
                          ),
                          speed: Duration(milliseconds: 100),
                        ),
                      ],
                      totalRepeatCount: 1,
                      pause: Duration(milliseconds: 1000),
                      displayFullTextOnTap: true,
                      stopPauseOnTap: true,
                    ),
                    SizedBox(height: 20),
                    _buildLoginBox(
                      title: 'Teacher Login',
                      loginIdController: loginIdController2,
                      passwordController: passwordController2,
                      users: usersLogin2,
                      passwordVisible: _passwordVisible1,
                      togglePasswordVisibility: () {
                        setState(() {
                          _passwordVisible1 = !_passwordVisible1;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginBox({
    required String title,
    required TextEditingController loginIdController,
    required TextEditingController passwordController,
    required List<Map<String, String>> users,
    required bool passwordVisible,
    required VoidCallback togglePasswordVisibility,
  }) {
    return SizedBox(
      width: 330, // Set the width of the login box
      height: 330, // Set the height of the login box
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withAlpha(100),
              blurRadius: 2,
            ),
          ],
          gradient: LinearGradient(
            colors: [
              Colors.blueAccent.withAlpha(80),
              Colors.purpleAccent.withAlpha(80),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [
                      Colors.orangeAccent.withAlpha(200),
                      Colors.white.withAlpha(150)
                    ],
                  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              ),
            ),
            SizedBox(height: 30),
            _buildTextField(
              controller: loginIdController,
              labelText: 'Login ID',
            ),
            SizedBox(height: 30),
            _buildTextField(
              controller: passwordController,
              labelText: 'Password',
              obscureText: !passwordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.blueAccent,
                ),
                onPressed: togglePasswordVisibility,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                String loginId = loginIdController.text.trim();
                String password = passwordController.text.trim();

                if (loginId.isEmpty || password.isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter login ID and password')),
                  );
                  return;
                }

                SharedPreferences prefs = await SharedPreferences.getInstance();

                if (!mounted) return;

                bool? isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

                if (isLoggedIn) {
                  if (!mounted) return;
                  _showContinueDialog();
                  return;
                }

                bool userFound = users.any((user) =>
                user['loginId'] == loginId && user['password'] == password);

                if (userFound) {
                  await prefs.setBool('isLoggedIn', true);
                  await prefs.setString('loginId', loginId);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$title successful!')));

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AttendanceDashboard(cameras)),
                  );
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid login ID or password for $title')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent, // Background color (previously 'primary')
                foregroundColor: Colors.white, // Text color (previously 'onPrimary')
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40), // Padding inside the button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners for the button
                ),
                shadowColor: Colors.blueAccent.withAlpha(150), // Shadow color
                elevation: 10, // Elevation for 3D effect
                side: BorderSide(color: Colors.deepOrange, width: 2), // Border around the button
                visualDensity: VisualDensity.comfortable, // Adjusts the button's density
              ),
              child: Text(
                'Login',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Font size adjustment for better appearance
                ),
              ),
            )

          ],
        ),
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(-3, -3),
          ),
          BoxShadow(
            color: Colors.blueGrey.withAlpha(100),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(
            color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withAlpha(200),
          labelText: labelText,
          labelStyle:
          TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
