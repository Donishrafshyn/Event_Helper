import 'package:event/Userdashboard.dart';
import 'package:event/login.dart';
import 'package:event/resetpass.dart';
import 'package:event/signup.dart';
import 'package:event/verifymail.dart';
import 'package:flutter/material.dart';
import 'package:event/home.dart';


import 'Providerdashboard.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:ProviderDashboard(provider: {}, services: [], bookings: [], notifications: [], onHome: () {  }, onLogout: () {  }, onUpdateBookingStatus: (String id, String status) {  },),
      debugShowCheckedModeBanner: false,
    );
  }
}
