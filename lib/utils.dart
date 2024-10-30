import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'cubit/march_model.dart';
import 'cubit/one_leg_model.dart';

Future<String> getAssetPath(String asset) async {
  final path = await getLocalPath(asset);
  await Directory(dirname(path)).create(recursive: true);
  final file = File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(asset);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }
  return file.path;
}

Future<String> getLocalPath(String path) async {
  return '${(await getApplicationSupportDirectory()).path}/$path';
}

double angle(
  Offset firstLandmark,
  Offset midLandmark,
  Offset lastLandmark,
) {
  final radians = math.atan2(
          lastLandmark.dy - midLandmark.dy, lastLandmark.dx - midLandmark.dx) -
      math.atan2(
          firstLandmark.dy - midLandmark.dy, firstLandmark.dx - midLandmark.dx);
  double degrees = radians * 180.0 / math.pi;
  degrees = degrees.abs(); // Angle should never be negative
  if (degrees > 180.0) {
    degrees =
        360.0 - degrees; // Always get the acute representation of the angle
  }
  return degrees;
}

MarchingState? isMarching(double angleKnee, MarchingState current) {
  final thresholdKneeLift = 80.0; // 무릎이 최대로 구부려졌을 때의 각도 임계값
  final thresholdKneeLower = 130.0; // 무릎이 펴지기 시작하는 각도의 임계값

  if (current == MarchingState.neutral && angleKnee < thresholdKneeLift) {
    return MarchingState.legLifted;
  } else if (current == MarchingState.legLifted &&
      angleKnee > thresholdKneeLower) {
    return MarchingState.legLowered;
  } else if (current == MarchingState.legLowered &&
      angleKnee < thresholdKneeLift) {
    // 다시 neutral 상태로 돌아가거나 다른 로직을 적용할 수 있음
    return MarchingState.neutral;
  }
  return null;
}

OneLegState isStanding(
    double legLength, double ankletoAnkle, OneLegState current) {
  final double thresholdpercent = 0.1;
  if (legLength * thresholdpercent < ankletoAnkle) {
    return OneLegState.legLifted;
  } else {
    return OneLegState.legLowered;
  }
}

double measureHipToAnkleLength(double hipY, double ankleY) {
  double distance = (hipY - ankleY).abs();
  return distance;
}

double measureAnkleToAnkleLength(doubleAnkle1Y, doubleAnkle2Y) {
  double distance = (doubleAnkle1Y - doubleAnkle2Y).abs();
  return distance;
}

double calculateMean(List<double> numbers) {
  double sum = numbers.reduce((a, b) => a + b);
  log('평균: ${sum / numbers.length}');
  return sum / numbers.length;
}

double calculateDeviation(List<double> numbers) {
  double mean = calculateMean(numbers);
  double sumOfSquaredDiffs =
      numbers.fold(0, (sum, number) => sum + math.pow(number - mean, 2));
  log('표준편차: ${math.sqrt(sumOfSquaredDiffs / numbers.length)}');
  return math.sqrt(sumOfSquaredDiffs / numbers.length);
}
