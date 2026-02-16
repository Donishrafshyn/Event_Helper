import 'package:event/Servicedetail.dart';
import 'package:event/Userdashboard.dart';
import 'package:event/bookingform.dart';
import 'package:event/login.dart';
import 'package:event/resetpass.dart';
import 'package:event/servicelist.dart';
import 'package:event/signup.dart';
import 'package:event/verifymail.dart';
import 'package:flutter/material.dart';
import 'package:event/home.dart';


import 'Admindashboard.dart';
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
      home:ServiceList(services: [], category: '', onBack: () {  }, onSelectService: (String serviceId) {  },),
      debugShowCheckedModeBanner: false,
    );
  }
}
