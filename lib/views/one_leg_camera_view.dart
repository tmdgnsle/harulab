import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:harulab/cubit/one_leg_feedback_cubit.dart';
import 'package:harulab/cubit/one_leg_model.dart';

import 'package:harulab/painters/pose_painter.dart';
import 'package:harulab/utils.dart' as utils;
import 'package:harulab/views/result_one_leg.dart';
import 'package:permission_handler/permission_handler.dart';

class OneLegCameraView extends StatefulWidget {
  OneLegCameraView(
      {Key? key,
      required this.customPaint,
      required this.onImage,
      required this.posePainter,
      this.onCameraFeedReady,
      this.onDetectorViewModeChanged,
      this.onCameraLensDirectionChanged,
      this.initialCameraLensDirection = CameraLensDirection.back})
      : super(key: key);

  final PosePainter? posePainter;
  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;

  @override
  State<OneLegCameraView> createState() => _OneLegCameraViewState();
}

class _OneLegCameraViewState extends State<OneLegCameraView> {
  FlutterTts flutterTts = FlutterTts();
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  bool _changingCameraLens = false;
  bool _cameraReady = false;

  PoseLandmark? p1;
  PoseLandmark? p2;
  PoseLandmark? p3;

  double rightKneeYMean = 0;
  double leftKneeYMean = 0;
  double rightAnkleYMean = 0;
  double leftAnkleYMean = 0;
  double rightHipYMean = 0;
  double leftHipYMean = 0;
  double rightWristXMean = 0;
  double rightWristYMean = 0;
  double leftWristXMean = 0;
  double leftWristYMean = 0;
  double rightElbowXMean = 0;
  double rightElbowYMean = 0;
  double leftElbowXMean = 0;
  double leftElbowYMean = 0;
  double rightShoulderXMean = 0;
  double rightShoulderYMean = 0;
  double leftShoulderXMean = 0;
  double leftShoulderYMean = 0;

  var rightkneeY;
  var leftkneeY;
  var rightankleY;
  var leftankleY;
  var righthipY;
  var lefthipY;
  var rightwristX;
  var rightwristY;
  var leftwristX;
  var leftwristY;
  var rightelbowX;
  var rightelbowY;
  var leftelbowX;
  var leftelbowY;
  var rightshoulderX;
  var rightshoulderY;
  var leftshoulderX;
  var leftshoulderY;

  int _remainingSeconds = 60; // 1분 타이머의 초기 값
  Timer? _timer; // 타이머를 제어할 Timer 객체
  Timer? _timer2;
  int _standingSeconds = 0;

  int _preparationSeconds = 5; // 5초 준비 시간
  bool _isPreparing = false; // 준비 중인지 여부를 나타내는 플래그

  List<Map<String, dynamic>> jsonData = [];

  Future<void> requestPermissions() async {
    await [Permission.camera, Permission.storage].request();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("ko-KR"); // 또는 원하는 언어로 설정
    await flutterTts.setSpeechRate(0.5); // 말하는 속도 조절 (0.0 ~ 1.0)
    await flutterTts.setVolume(1.0); // 볼륨 설정 (0.0 ~ 1.0)
    await flutterTts.setPitch(1.0); // 음높이 설정 (0.5 ~ 2.0)
  }

  void collectJSONData(
    double rightAnkleY,
    double leftAnkleY,
    double rightHipY,
    double leftHipY,
    double rightKneeY,
    double leftKneeY,
    double rightShoulderX,
    double rightShoulderY,
    double leftShoulderX,
    double leftShoulderY,
    double rightWristX,
    double rightWristY,
    double leftWristX,
    double leftWristY,
    double rightElbowX,
    double rightElbowY,
    double leftElbowX,
    double leftElbowY,
  ) {
    Map<String, dynamic> dataPoint = {
      "Timestamp": DateTime.now().toUtc().toIso8601String(),
      "rightAnkle Y": rightAnkleY,
      "leftAnkle Y": leftAnkleY,
      "rightHip Y": rightHipY,
      "leftHip Y": leftHipY,
      "rightKnee Y": rightKneeY,
      "leftKnee Y": leftKneeY,
      "rightShoulder X": rightShoulderX,
      "rightShoulder Y": rightShoulderY,
      "leftShoulder X": leftShoulderX,
      "leftShoulder Y": leftShoulderY,
      "rightWrist X": rightWristX,
      "rightWrist Y": rightWristY,
      "leftWrist X": leftWristX,
      "leftWrist Y": leftWristY,
      "rightElbow X": rightElbowX,
      "rightElbow Y": rightElbowY,
      "leftElbow X": leftElbowX,
      "leftElbow Y": leftElbowY,
    };
    jsonData.add(dataPoint);
  }

  void sendData() async {
    final bloc = BlocProvider.of<OneLegStanding>(context);
    await context.read<OneLegFeedbackCubit>().sendMarching(jsonData);
    Navigator.of(context).push(MaterialPageRoute(
        builder: ((context) => ResultOneLeg(
              standingTimer: bloc.standingTimer,
            ))));
  }

  void _startTimer() {
    final bloc = BlocProvider.of<OneLegStanding>(context);
    _remainingSeconds = 60; // 타이머 초기화
    _isPreparing = true;
    _preparationSeconds = 5;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_isPreparing) {
          if (_preparationSeconds > 0) {
            flutterTts.speak(_preparationSeconds.toString());
            _preparationSeconds--;
          } else {
            _isPreparing = false;
            flutterTts.speak("시작합니다.");
          }
        } else {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer!.cancel(); // 타이머 취소
            _cameraReady = false; // _cameraReady를 false로 설정
            _remainingSeconds = 60;
            bloc.setTime(_standingSeconds);
            _standingSeconds = 0;
          }
        }
      });
      if (!_isPreparing && _remainingSeconds == 0) {
        flutterTts.speak('끝났습니다.');
        sendData();
      }
    });
  }

  void _standingTimer() {
    _standingSeconds = 0;
    final bloc = BlocProvider.of<OneLegStanding>(context);
    _timer2 = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (bloc.standing == true) {
          _standingSeconds++;
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _initTts();
    requestPermissions().then((_) => _initialize());
  }

  void _initialize() async {
    if (_cameras.isEmpty) {
      try {
        _cameras = await availableCameras();
      } catch (e) {
        print('Available cameras error: $e');
      }
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void didUpdateWidget(covariant OneLegCameraView oldWidget) {
    final Size size = MediaQuery.of(context).size;
    if (widget.customPaint != oldWidget.customPaint) {
      if (widget.customPaint == null) return;
      if (_cameraReady == true && !_isPreparing) {
        final bloc =
            BlocProvider.of<OneLegStanding>(context); // 제자리 걸음 운동 카운터 블록
        for (final pose in widget.posePainter!.poses) {
          PoseLandmark getPoseLandmark(PoseLandmarkType type) {
            final PoseLandmark joint = pose.landmarks[type]!;
            return joint;
          }

          // 오른쪽 다리의 포즈 랜드마크 추출
          var rightknee = getPoseLandmark(PoseLandmarkType.rightKnee);
          var leftknee = getPoseLandmark(PoseLandmarkType.leftKnee);

          var rightankle = getPoseLandmark(PoseLandmarkType.rightAnkle);
          var leftankle = getPoseLandmark(PoseLandmarkType.leftAnkle);

          var righthip = getPoseLandmark(PoseLandmarkType.rightHip);
          var lefthip = getPoseLandmark(PoseLandmarkType.leftHip);

          var rightwrist = getPoseLandmark(PoseLandmarkType.rightWrist);
          var leftwrist = getPoseLandmark(PoseLandmarkType.leftWrist);

          var rightelbow = getPoseLandmark(PoseLandmarkType.rightElbow);
          var leftelbow = getPoseLandmark(PoseLandmarkType.leftElbow);

          var rightshoulder = getPoseLandmark(PoseLandmarkType.rightShoulder);
          var leftshoulder = getPoseLandmark(PoseLandmarkType.leftShoulder);

          rightkneeY = rightknee.y;

          leftkneeY = leftknee.y;

          rightankleY = rightankle.y;

          leftankleY = leftankle.y;

          righthipY = righthip.y;

          lefthipY = lefthip.y;

          rightwristX = rightwrist.x;
          rightwristY = rightwrist.y;

          leftwristX = leftwrist.x;
          leftwristY = leftwrist.y;

          rightelbowX = rightelbow.x;
          rightelbowY = rightelbow.y;

          leftelbowX = leftelbow.x;
          leftelbowY = leftelbow.y;

          rightshoulderX = rightshoulder.x;
          rightshoulderY = rightshoulder.y;

          leftshoulderX = leftshoulder.x;
          leftshoulderY = leftshoulder.y;

          if (rightknee != null &&
              rightankle != null &&
              leftankle != null &&
              righthip != null &&
              rightwrist != null) {
            smoothingPoint();

            final legLength =
                utils.measureHipToAnkleLength(leftHipYMean, leftAnkleYMean);
            final ankletoAnkle = utils.measureAnkleToAnkleLength(
                rightAnkleYMean, leftAnkleYMean);

            final oneLegState =
                utils.isStanding(legLength, ankletoAnkle, bloc.state);

            print('oneLegtState: $oneLegState');

            collectJSONData(
                rightAnkleYMean,
                leftAnkleYMean,
                rightHipYMean,
                leftHipYMean,
                rightKneeYMean,
                leftKneeYMean,
                rightShoulderXMean,
                rightShoulderYMean,
                leftShoulderXMean,
                leftShoulderYMean,
                rightWristXMean,
                rightWristYMean,
                leftWristXMean,
                leftWristYMean,
                rightElbowXMean,
                rightElbowYMean,
                leftElbowXMean,
                leftElbowYMean);

            if (oneLegState == OneLegState.legLifted) {
              bloc.lift();
              bloc.setOneLegState(oneLegState);
            } else if (oneLegState == OneLegState.legLowered) {
              bloc.low();
              bloc.setOneLegState(oneLegState);
            }
          }
        }
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _liveFeedBody(),
    );
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) return Container();
    if (_controller == null) return Container();
    if (_controller?.value.isInitialized == false) return Container();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _changingCameraLens
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Expanded(
                  child: ClipRect(
                    child: CameraPreview(_controller!, child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size:
                              Size(constraints.maxWidth, constraints.maxHeight),
                        );
                      },
                    )),
                  ),
                ),
          Container(
            child: Column(
              children: [
                Icon(Icons.heart_broken),
                Text('화면에 몸 전체가 나오도록 해주세요'),
                Text('평소 걸음걸이로 걸어주세요'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _remainingTimeWidget(),
                    _standingWidget(),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _cameraButton(),
                    _switchLiveCameraToggle(),
                  ],
                ),
                _guideVideoButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideVideoButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 0),
      ),
      onPressed: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '가이드 영상',
            style: TextStyle(fontSize: 12, color: Colors.black),
          ),
          Icon(
            Icons.play_circle_filled,
            color: Colors.grey,
            size: 15,
          ),
        ],
      ),
    );
  }

  Widget _cameraButton() {
    return Positioned(
      left: 0,
      right: 0,
      top: 100,
      child: FloatingActionButton(
        onPressed: _isPreparing
            ? null
            : () async {
                final bloc = BlocProvider.of<OneLegStanding>(context);
                if (_cameraReady == true) {
                  bloc.low();
                  _timer!.cancel();
                  _timer2?.cancel();
                  _remainingSeconds = 60;
                  bloc.setTime(_standingSeconds);
                } else {
                  _startTimer();
                  _standingTimer();
                }
                setState(() {
                  _cameraReady = !_cameraReady;
                });
              },
        child: Text(_cameraReady ? '촬영 종료' : '촬영 시작'),
      ),
    );
  }

  Widget _remainingTimeWidget() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          _isPreparing
              ? '준비시간: $_preparationSeconds'
              : '남은시간: ${Duration(seconds: _remainingSeconds).toString().split('.').first.padLeft(8, '0')}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _standingWidget() {
    final bloc = BlocProvider.of<OneLegStanding>(context);
    return Positioned(
      left: 0,
      right: 0,
      top: 50,
      child: Container(
        width: 70,
        child: Column(
          children: [
            const Text(
              'Standing',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            Container(
              width: 100,
              decoration: BoxDecoration(
                  color: const Color.fromARGB(137, 20, 15, 15),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 4.0),
                  borderRadius: const BorderRadius.all(Radius.circular(12))),
              child: Text(
                '${bloc.standing}: ${_standingSeconds}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchLiveCameraToggle() => Positioned(
        bottom: 8,
        right: 8,
        child: SizedBox(
          height: 50.0,
          width: 50.0,
          child: FloatingActionButton(
            heroTag: Object(),
            onPressed: _switchLiveCamera,
            backgroundColor: Colors.black54,
            child: Icon(
              Platform.isIOS
                  ? Icons.flip_camera_ios_outlined
                  : Icons.flip_camera_android_outlined,
              size: 25,
            ),
          ),
        ),
      );

  Future _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      // Set to ResolutionPreset.high. Do NOT set it to ResolutionPreset.max because for some phones does NOT work.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.getMinZoomLevel().then((value) {
        _currentZoomLevel = value;
        _minAvailableZoom = value;
      });
      _controller?.getMaxZoomLevel().then((value) {
        _maxAvailableZoom = value;
      });
      _currentExposureOffset = 0.0;
      _controller?.getMinExposureOffset().then((value) {
        _minAvailableExposureOffset = value;
      });
      _controller?.getMaxExposureOffset().then((value) {
        _maxAvailableExposureOffset = value;
      });
      _controller?.startImageStream(_processCameraImage).then((value) {
        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady!();
        }
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }
      });
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/android/src/main/java/com/google_mlkit_commons/InputImageConverter.java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/ios/Classes/MLKVisionImage%2BFlutterPlugin.m
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/example/lib/vision_detector_views/painters/coordinates_translator.dart
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    // print(
    //     'lensDirection: ${camera.lensDirection}, sensorOrientation: $sensorOrientation, ${_controller?.value.deviceOrientation} ${_controller?.value.lockedCaptureOrientation} ${_controller?.value.isCaptureOrientationLocked}');
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      // print('rotationCompensation: $rotationCompensation');
    }
    if (rotation == null) return null;
    // print('final rotation: $rotation');

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  int smoothingFrame = 3; // 평균을 계산하기 위해 사용할 프레임 수

  var rightKneeY = ListQueue<double>();
  var leftKneeY = ListQueue<double>();
  var rightAnkleY = ListQueue<double>();
  var leftAnkleY = ListQueue<double>();
  var rightHipY = ListQueue<double>();
  var leftHipY = ListQueue<double>();
  var rightWristX = ListQueue<double>();
  var rightWristY = ListQueue<double>();
  var leftWristX = ListQueue<double>();
  var leftWristY = ListQueue<double>();
  var rightElbowX = ListQueue<double>();
  var rightElbowY = ListQueue<double>();
  var leftElbowX = ListQueue<double>();
  var leftElbowY = ListQueue<double>();
  var rightShoulderX = ListQueue<double>();
  var rightShoulderY = ListQueue<double>();
  var leftShoulderX = ListQueue<double>();
  var leftShoulderY = ListQueue<double>();

  double getMean(ListQueue<double> queue) {
    if (queue.length < smoothingFrame) {
      return queue.isNotEmpty ? queue.last : 0.0;
    }

    double sum = queue.reduce((value, element) => value + element);
    queue.removeFirst();
    return sum / smoothingFrame;
  }

  void checkOutlier(double point, ListQueue<double> queue, double mean) {
    if (queue.length < smoothingFrame) {
      queue.add(point);
    } else if ((point - queue.elementAt(smoothingFrame - 2)).abs() <= 300) {
      queue.add(point);
    } else {
      double sumOfGaps = 0.0;
      for (int i = 0; i < smoothingFrame - 2; i++) {
        double gap = queue.elementAt(i + 1) - queue.elementAt(i);
        sumOfGaps += gap;
      }
      double correctVal = queue.elementAt(smoothingFrame - 1) +
          sumOfGaps / (smoothingFrame - 1);
      queue.add(correctVal);
    }
  }

  void smoothingPoint() {
    rightKneeYMean = getMean(rightKneeY);

    leftKneeYMean = getMean(leftKneeY);

    rightAnkleYMean = getMean(rightAnkleY);

    leftAnkleYMean = getMean(leftAnkleY);

    rightHipYMean = getMean(rightHipY);

    leftHipYMean = getMean(leftHipY);

    rightWristXMean = getMean(rightWristX);
    rightWristYMean = getMean(rightWristY);

    leftWristXMean = getMean(leftWristX);
    leftWristYMean = getMean(leftWristY);

    rightElbowXMean = getMean(rightElbowX);
    rightElbowYMean = getMean(rightElbowY);

    leftElbowXMean = getMean(leftElbowX);
    leftElbowYMean = getMean(leftElbowY);

    rightShoulderXMean = getMean(rightShoulderX);
    rightShoulderYMean = getMean(rightShoulderY);

    leftShoulderXMean = getMean(leftShoulderX);
    leftShoulderYMean = getMean(leftShoulderY);

    checkOutlier(rightkneeY, rightKneeY, rightKneeYMean);

    checkOutlier(leftkneeY, leftKneeY, leftKneeYMean);

    checkOutlier(rightankleY, rightAnkleY, rightAnkleYMean);

    checkOutlier(leftankleY, leftAnkleY, leftAnkleYMean);

    checkOutlier(righthipY, rightHipY, rightHipYMean);

    checkOutlier(lefthipY, leftHipY, leftHipYMean);

    checkOutlier(rightwristX, rightWristX, rightWristXMean);
    checkOutlier(rightwristY, rightWristY, rightWristYMean);

    checkOutlier(leftwristX, leftWristX, leftWristXMean);
    checkOutlier(leftwristY, leftWristY, leftWristYMean);

    checkOutlier(rightelbowX, rightElbowX, rightElbowXMean);
    checkOutlier(rightelbowY, rightElbowY, rightElbowYMean);

    checkOutlier(leftelbowX, leftElbowX, leftElbowXMean);
    checkOutlier(leftelbowY, leftElbowY, leftElbowYMean);

    checkOutlier(rightshoulderX, rightShoulderX, rightshoulderX);
    checkOutlier(rightshoulderY, rightShoulderY, rightshoulderY);

    checkOutlier(leftshoulderX, leftShoulderX, leftshoulderX);
    checkOutlier(leftshoulderY, leftShoulderY, leftshoulderY);
  }
}
