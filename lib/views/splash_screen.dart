import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:harulab/views/pose_detection_view.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF273338),
      minimumSize: Size(size.width * 0.85, 36),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: size.height * 0.15),
            Container(
              alignment: Alignment.center,
              width: size.width * 0.7,
              height: size.width * 0.7,
              child: Lottie.asset('assets/walk.json',
                  fit: BoxFit.cover),
            ),
            SizedBox(
              height: 40,
            ),
            const Text(
              '제자리 걷기 테스트',
              style: TextStyle(
                  fontSize: 38.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2),
            ),
            // Container(
            //   width: size.width * 0.7,
            //   child: const Text(
            //     'An exciting app partner for your exercise routine',
            //     textAlign: TextAlign.center,
            //     style: TextStyle(fontSize: 18.0, letterSpacing: -1.1),
            //   ),
            // ),
            Spacer(),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PoseDetectorView()),
                );
              },
              child: Text('시작하기!', style: TextStyle(color: Colors.white),),
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
