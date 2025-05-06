// This file is intentionally left blank.

import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'about_page.dart'; // Import the AboutPage
import 'help_support_page.dart'; // Import the HelpSupportPage

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text('Home')), // Home Page
    Center(child: Text('YouTube')), // YouTube Page
    Center(child: Text('Search')), // Search Page
    Center(child: Text('Favorites')), // Favorites Page
    ProfilePage(), // Updated Profile Page
    BcaSemesterPage(semester: 1, notes: 'Notes for BCA 1st Semester'),
    BcaSemesterPage(semester: 2, notes: 'Notes for BCA 2nd Semester'),
    BcaSemesterPage(semester: 3, notes: 'Notes for BCA 3rd Semester'),
    BcaSemesterPage(semester: 4, notes: 'Notes for BCA 4th Semester'),
    BcaSemesterPage(semester: 5, notes: 'Notes for BCA 5th Semester'),
    BcaSemesterPage(semester: 6, notes: 'Notes for BCA 6th Semester'),
    BcaSemesterPage(semester: 7, notes: 'Notes for BCA 7th Semester'),
    BcaSemesterPage(semester: 8, notes: 'Notes for BCA 8th Semester'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anish Library',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Anish Library',
            style: TextStyle(
              fontFamily: 'Bauhaus 93',
              color: Colors.white,
              fontSize: 24,

              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 3,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          titleSpacing: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                // Add search functionality here
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                // Add notification functionality here
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[200]!, Colors.purple[200]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  height: 150,
                  child: UserAccountsDrawerHeader(
                    accountName: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '  ANISH LIBRARY',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Bauhaus 93',
                          ),
                        ),
                      ],
                    ),
                    accountEmail: Text(''),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: Text(
                    'Contact Us',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'Our Website',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'Facebook Page',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'Instagram',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'BCA ENTRANCE QUESTIONS',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'BCA I SEMESTER',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'BCA II SEMESTER',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'BCA III SEMESTER',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'BCA IV SEMESTER',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'BCA V SEMESTER',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'BCA VI SEMESTER',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'BCA VII SEMESTER',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'BCA VIII SEMESTER',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            // Upward Navigation
            ...(_currentIndex == 0
                ? [
                  Container(
                    height: 50,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _currentIndex = 0; // Explore
                                });
                              },
                              child: Text('Explore'),
                            ),
                          ),
                          // BCA Semesters
                          for (int i = 1; i <= 8; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _currentIndex =
                                        i + 4; // Adjust index for BCA semesters
                                  });
                                },
                                child: Text('BCA $i Sem'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ]
                : []),
            // Current Page
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          items: <Widget>[
            Icon(Icons.home, size: 30),
            Icon(Icons.play_circle_fill, size: 30),
            Icon(Icons.search, size: 30),
            Icon(Icons.favorite, size: 30),
            Icon(Icons.person, size: 30),
          ],
          color: Colors.blue,
          buttonBackgroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: Duration(milliseconds: 300),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class BcaSemesterPage extends StatelessWidget {
  final int semester;
  final String notes;

  BcaSemesterPage({required this.semester, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(notes));
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[200]!, Colors.purple[200]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'Anish',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    'anishlibrary.com',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 32),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.info),
                          title: Text('About'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AboutPage(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Settings'),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: Icon(Icons.support_agent),
                          title: Text('Help and Support'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HelpSupportPage(),
                              ),
                            );
                          },
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.logout, color: Colors.red),
                          title: Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
