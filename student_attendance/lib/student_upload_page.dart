import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadStudentPage extends StatefulWidget {
  @override
  UploadStudentPageState createState() => UploadStudentPageState();
}

class UploadStudentPageState extends State<UploadStudentPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _studentData;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 6))..repeat(reverse: true);
    _color1 = ColorTween(begin: Colors.purple, end: Colors.blue).animate(_controller);
    _color2 = ColorTween(begin: Colors.orange, end: Colors.pink).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showUploadPanel() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Upload',
      transitionDuration: Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => UploadFloatingPanel(),
      transitionBuilder: (_, anim, __, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim.value),
          child: Opacity(opacity: anim.value, child: child),
        );
      },
    );
  }

  Future<void> _searchStudent() async {
    String input = _searchController.text.trim();
    if (input.isEmpty) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('reg_no', isEqualTo: input)
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('name', isEqualTo: input)
            .get();
      }

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _studentData = snapshot.docs.first.data() as Map<String, dynamic>;
        });
      } else {
        setState(() {
          _studentData = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student not found')),
        );
      }
    } catch (e) {
      print('Error searching student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching student')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color1.value ?? Colors.purple, _color2.value ?? Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 🟦 Static Header
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withAlpha(40),
                              Colors.white.withAlpha(30)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Upload and View',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black45)
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 🟨 Scrollable Body
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.only(bottom: 100),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8,
                                            offset: Offset(2, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter Reg No or Name',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _searchStudent,
                                    child: Text('Search'),
                                  ),
                                ],
                              ),
                            ),

                            if (_studentData != null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Card(
                                  elevation: 10,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  color: Colors.white.withAlpha(250),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Name: ${_studentData!['name']}',
                                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                                  Text('Reg No: ${_studentData!['reg_no']}',
                                                      style: TextStyle(fontSize: 18)),
                                                  Text('Branch: ${_studentData!['branch']}',
                                                      style: TextStyle(fontSize: 18)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.redAccent),
                                              tooltip: 'Delete Student',
                                              onPressed: () => _confirmAndDeleteStudent(_studentData!['reg_no']),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              _studentData!['photo_url'],
                                              height: 180,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ]
                            else ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 200),
                                child: Center(
                                  child: Text(
                                    'Tap the + button to upload student',
                                    style: TextStyle(fontSize: 16, color: Colors.tealAccent),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ➕ Floating Button
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: FloatingActionButton(
                      onPressed: _showUploadPanel,
                      child: Icon(Icons.add),
                      tooltip: 'Add Student',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDeleteStudent(String regNo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Student'),
        content: Text('Are you sure you want to delete this student permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('students').doc(regNo).delete();
        setState(() => _studentData = null);
        _searchController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student deleted successfully')),
        );
      } catch (e) {
        print('Delete error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete student')),
        );
      }
    }
  }

}

class UploadFloatingPanel extends StatefulWidget {
  @override
  _UploadFloatingPanelState createState() => _UploadFloatingPanelState();
}

class _UploadFloatingPanelState extends State<UploadFloatingPanel> {
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _branchController = TextEditingController();
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _uploadStudentData() async {
    final name = _nameController.text.trim();
    final regNo = _regNoController.text.trim();
    final branch = _branchController.text.trim();

    if (name.isEmpty || regNo.isEmpty || branch.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields and pick an image'),
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cloudName = 'dhj2b9eiq';
      final preset = 'flutter_unsigned_upload';

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = preset
        ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode != 200) throw Exception('Cloudinary upload failed');

      final imageUrl = json.decode(body)['secure_url'];

      await FirebaseFirestore.instance.collection('students').doc(regNo).set({
        'name': name,
        'reg_no': regNo,
        'branch': branch,
        'photo_url': imageUrl,
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 12,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Upload', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),

                // Name Field
                TextField(
                  controller: _nameController,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // Reg No Field
                TextField(
                  controller: _regNoController,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Registration No.',
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // Branch Field
                TextField(
                  controller: _branchController,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Branch',
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Pick Image
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image),
                  label: Text('Pick Image'),
                ),
                SizedBox(height: 10),

                if (_imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_imageFile!, height: 150),
                  ),
                SizedBox(height: 20),

                // Upload & Cancel
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  Column(
                    children: [
                      Center(
                        child: ElevatedButton(
                          onPressed: _uploadStudentData,
                          child: Text(
                            'Upload',
                            style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent,
                            minimumSize: Size(200, 45), // reduced width
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
