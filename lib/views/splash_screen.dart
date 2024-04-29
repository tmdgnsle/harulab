import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:harulab/views/pose_detection_view.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF273338),
      minimumSize: Size(size.width * 0.85, 36),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: size.height * 0.15),
            Container(
              alignment: Alignment.center,
              width: size.width * 0.7,
              height: size.width * 0.7,
              child: Lottie.asset('assets/push-up-animation.json',
                  fit: BoxFit.cover),
            ),
            const SizedBox(
              height: 40,
            ),
            const Text(
              'Push Up Counter',
              style: TextStyle(
                  fontSize: 38.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2),
            ),
            SizedBox(
              width: size.width * 0.7,
              child: const Text(
                'An exciting app partner for your exercise routine',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.0, letterSpacing: -1.1),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PoseDetectorView(isOneLeg: true,)),
                );
              },
              child: const Text('one leg'),
            ),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PoseDetectorView(isOneLeg: false,)),
                );
              },
              child: const Text('march'),
            ),
            SizedBox(
              height: size.height * 0.03,
            ),
          ],
        ),
      ),
    );
  }
}
