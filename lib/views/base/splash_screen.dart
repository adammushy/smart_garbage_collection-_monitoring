import 'package:flutter/material.dart';
import 'package:flutter_project_template/constants/dimensions.dart';
import 'package:flutter_project_template/constants/images.dart';
import 'package:flutter_project_template/views/screens/onboarding/onboarding-screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: Dimensions.quarterScreenHeight(context),
            ),
            Image.asset(
              Images.splashImage,
              height: 200,
            ),
            const Text("Temp App"),
          ],
        ),
      ),
    );
  }
}
