import 'package:flutter/material.dart';
import 'package:EduNex/screens/Auth/login.dart' ;
import 'package:EduNex/utils/theme/theme.dart';


import 'screens/student/Layout.dart' as student_layout;
import 'screens/student/profile.dart';
import 'screens/student/courses.dart';
import 'screens/student/course_details.dart';
import 'screens/student/exams.dart';
import 'screens/student/timetable.dart';
import 'screens/student/student_demandes_page.dart';
import 'screens/student/student_announcements_page.dart';
import 'screens/student/student_attendance_page.dart';
import 'screens/student/student_dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduNex',
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/student': (context) => student_layout.StudentLayout(),
        '/profile': (context) => const StudentProfilePage(),
        '/courses': (context) => const StudentCoursesScreen(),
        '/course-details': (context) => const StudentCourseDetailsScreen(courseId: '',),
        '/exams': (context) => const StudentExamsScreen(),
        '/timetable': (context) => const StudentTimetableScreen(),
        '/requests': (context) => const StudentDemandesPage(), 
        '/announcements': (context) => const StudentAnnouncementsPage(),
        '/attendance': (context) => const StudentAttendancePage(),
        '/dashboard': (context) => const StudentDashboardPage(),
    
         },
    );
  }
}


