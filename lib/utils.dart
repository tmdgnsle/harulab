import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:harulab/models/march_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
  PoseLandmark firstLandmark,
  PoseLandmark midLandmark,
  PoseLandmark lastLandmark,
) {
  final radians = math.atan2(
          lastLandmark.y - midLandmark.y, lastLandmark.x - midLandmark.x) -
      math.atan2(
          firstLandmark.y - midLandmark.y, firstLandmark.x - midLandmark.x);
  double degrees = radians * 180.0 / math.pi;
  degrees = degrees.abs(); // Angle should never be negative
  if (degrees > 180.0) {
    degrees =
        360.0 - degrees; // Always get the acute representation of the angle
  }
  return degrees;
}

MarchingState? isMarching(double angleKnee, MarchingState current) {
  const thresholdKneeLift = 90.0; // 무릎이 최대로 구부려졌을 때의 각도 임계값
  const thresholdKneeLower = 160.0; // 무릎이 펴지기 시작하는 각도의 임계값

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


Map<PoseLandmarkType, ListQueue<double>> landmarkQueues = {
  PoseLandmarkType.rightKnee: ListQueue<double>(smoothingFrame),
  PoseLandmarkType.rightAnkle: ListQueue<double>(smoothingFrame),
  PoseLandmarkType.rightHip: ListQueue<double>(smoothingFrame),
  // 추가 랜드마크에 대해서도 동일하게 적용
};
int smoothingFrame = 3;  // 예를 들어 평균을 계산하기 위해 사용할 프레임 수

double getMean(ListQueue<double> queue) {
  if (queue.length < smoothingFrame) return queue.isNotEmpty ? queue.last : 0.0;

  double sum = queue.reduce((value, element) => value + element);
  queue.removeFirst();
  return sum / smoothingFrame;
}

void checkOutlier(double point, ListQueue<double> queue, double mean, double maximum) {
  if (point <= maximum) {
    if (queue.length < smoothingFrame) {
      queue.add(point);
    } else if ((point - queue.elementAt(smoothingFrame - 2)).abs() <= 100) {
      queue.add(point);
    } else {
      double sumOfGaps = 0.0;
      for (int i = 0; i < smoothingFrame - 2; i++) {
        double gap = queue.elementAt(i + 1) - queue.elementAt(i);
        sumOfGaps += gap;
      }
      double correctVal = queue.elementAt(smoothingFrame - 1) + sumOfGaps / (smoothingFrame - 1);
      queue.add(correctVal);
    }
  }
}

//한 발서기 로직

