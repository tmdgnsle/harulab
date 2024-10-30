import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:harulab/cubit/march_model.dart';
import 'package:harulab/cubit/marching_feedback_cubit.dart';
import 'package:harulab/painters/coordinates_translator.dart';
import 'package:harulab/painters/horizontal_line_painter.dart';
import 'package:harulab/painters/pose_painter.dart';

import 'package:harulab/utils.dart' as utils;
import 'package:harulab/views/result_marching.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class MarchingCameraView extends StatefulWidget {
  MarchingCameraView(
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
  State<MarchingCameraView> createState() => _MarchingCameraViewState();
}

class _MarchingCameraViewState extends State<MarchingCameraView> {
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

  double rightKneeXMean = 0;
  double rightKneeYMean = 0;
  double rightKneeZMean = 0;
  double leftKneeXMean = 0;
  double leftKneeYMean = 0;
  double leftKneeZMean = 0;
  double rightAnkleXMean = 0;
  double rightAnkleYMean = 0;
  double rightAnkleZMean = 0;
  double leftAnkleYMean = 0;
  double leftAnkleZMean = 0;
  double rightHipXMean = 0;
  double rightHipYMean = 0;
  double rightHipZMean = 0;
  double leftHipYMean = 0;
  double leftHipZMean = 0;
  double rightWristYMean = 0;
  double rightWristZMean = 0;
  double leftWristYMean = 0;
  double leftWristZMean = 0;

  var rightkneeX;
  var rightkneeY;
  var rightkneeZ;
  var leftkneeX;
  var leftkneeY;
  var leftkneeZ;
  var rightankleX;
  var rightankleY;
  var rightankleZ;
  var leftankleY;
  var leftankleZ;
  var righthipX;
  var righthipY;
  var righthipZ;
  var lefthipY;
  var lefthipZ;
  var rightwristY;
  var rightwristZ;
  var leftwristY;
  var leftwristZ;

  int _remainingSeconds = 60; // 1분 타이머의 초기 값
  int _repetitionTimer = 0;
  Timer? _timer; // 타이머를 제어할 Timer 객체
  int _preparationSeconds = 5; // 5초 준비 시간
  bool _isPreparing = false; // 준비 중인지 여부를 나타내는 플래그
  bool _isInPosition = false;

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
    double rightKneeAngle,
    double leftKneeAngle,
    double leftWristY,
    double rightWristY,
    double leftWristZ,
    double rightWristZ,
    double leftKneeY,
    double rightKneeY,
  ) {
    Map<String, dynamic> dataPoint = {
      "Timestamp": DateTime.now().toUtc().toIso8601String(),
      "rightKneeAngle": rightKneeAngle,
      "leftKneeAngle": leftKneeAngle,
      "leftWrist_Y": leftWristY,
      "rightWrist_Y": rightWristY,
      "leftWrist_Z": leftWristZ,
      "rightWrist_Z": rightWristZ,
      "leftKnee_Y": leftKneeY,
      "rightKnee_Y": rightKneeY,
    };
    jsonData.add(dataPoint);
  }

  void sendData() async {
    try {
      // await _stopLiveFeed();

      context.read<MarchingCounter>().calculateDeviation();
      final bloc = context.read<MarchingCounter>();
      final feedbackCubit = context.read<MarchingFeedbackCubit>();
      await feedbackCubit.sendMarching(jsonData);

      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: feedbackCubit,
          child: ResultMarching(
            counter: bloc.totalCounter,
            standard_deviation: bloc.standard_deviation,
          ),
        ),
      ));
    } catch (e, stackTrace) {
      print('Error in sendData: $e');
      print('Stack trace: $stackTrace');
      // 사용자에게 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void _startTimer() {
    _isPreparing = true;
    _preparationSeconds = 5;
    _remainingSeconds = 60;

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
            _repetitionTimer = (_remainingSeconds / 10).truncate();
          } else {
            _timer?.cancel();
            _cameraReady = false;
            _repetitionTimer = 0;
          }
        }
      });
      if (!_isPreparing && _remainingSeconds == 0) {
        flutterTts.speak('끝났습니다.');
        sendData();
      }
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
  void didUpdateWidget(covariant MarchingCameraView oldWidget) {
    if (widget.customPaint != oldWidget.customPaint) {
      if (widget.customPaint == null) return;
      if (_cameraReady == true && !_isPreparing) {
        final bloc =
            BlocProvider.of<MarchingCounter>(context); // 제자리 걸음 운동 카운터 블록
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

          rightkneeX = rightknee.x;
          rightkneeY = rightknee.y;
          rightkneeZ = rightknee.z;

          leftkneeX = leftknee.x;
          leftkneeY = leftknee.y;
          leftkneeZ = leftknee.z;

          rightankleX = rightankle.x;
          rightankleY = rightankle.y;
          rightankleZ = rightankle.z;

          leftankleY = leftankle.y;
          leftankleZ = leftankle.z;

          righthipX = righthip.x;
          righthipY = righthip.y;
          righthipZ = righthip.z;

          lefthipY = lefthip.y;
          lefthipZ = lefthip.z;

          rightwristY = rightwrist.y;
          rightwristZ = rightwrist.z;

          leftwristY = leftwrist.y;
          leftwristZ = leftwrist.z;

          // 무릎 각도 검증
          if (rightknee != null &&
              rightankle != null &&
              righthip != null &&
              leftwrist != null) {
            smoothingPoint();

            final Offset rightOffKnee = Offset(rightKneeYMean, rightKneeZMean);
            final Offset rightOffAnkle =
                Offset(rightAnkleYMean, rightAnkleZMean);
            final Offset rightOffHip = Offset(rightHipYMean, rightHipZMean);

            final rightKneeAngle =
                utils.angle(rightOffHip, rightOffKnee, rightOffAnkle);

            final Offset leftOffKnee = Offset(leftKneeYMean, leftKneeZMean);
            final Offset leftOffAnkle = Offset(leftAnkleYMean, leftAnkleZMean);
            final Offset leftOffHip = Offset(leftHipYMean, leftHipZMean);

            final leftKneeAngle =
                utils.angle(leftOffHip, leftOffKnee, leftOffAnkle);

            final marchingState = utils.isMarching(rightKneeAngle, bloc.state);

            if (marchingState != null) {
              if (marchingState == MarchingState.legLifted) {
                bloc.setMarchingState(marchingState);
              } else if (marchingState == MarchingState.legLowered) {
                switch (_repetitionTimer) {
                  case 5:
                    bloc.increment1(); // 제자리 걸음 횟수 증가
                    bloc.setMarchingState(MarchingState.neutral);
                    log('10초: ${bloc.counter_1}');
                    break;
                  case 4:
                    bloc.increment2(); // 제자리 걸음 횟수 증가
                    bloc.setMarchingState(MarchingState.neutral);
                    log('20초: ${bloc.counter_2}');
                    break;
                  case 3:
                    bloc.increment3(); // 제자리 걸음 횟수 증가
                    bloc.setMarchingState(MarchingState.neutral);
                    log('30초: ${bloc.counter_3}');
                    break;
                  case 2:
                    bloc.increment4(); // 제자리 걸음 횟수 증가
                    bloc.setMarchingState(MarchingState.neutral);
                    log('40초: ${bloc.counter_4}');
                    break;
                  case 1:
                    bloc.increment5(); // 제자리 걸음 횟수 증가
                    bloc.setMarchingState(MarchingState.neutral);
                    log('50초: ${bloc.counter_5}');
                    break;
                  case 0:
                    bloc.increment6(); // 제자리 걸음 횟수 증가
                    bloc.setMarchingState(MarchingState.neutral);
                    log('총: ${bloc.counter_1}, ${bloc.counter_2}, ${bloc.counter_3}, ${bloc.counter_4}, ${bloc.counter_5}, ${bloc.counter_6}');
                    break;
                } // 상태 초기화
              }
            }
            collectJSONData(
                rightKneeAngle,
                leftKneeAngle,
                leftWristYMean,
                rightWristYMean,
                leftWristZMean,
                rightWristZMean,
                leftKneeYMean,
                rightKneeYMean);
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
      appBar: AppBar(
        title: Text('제자리 걷기 테스트'),
        actions: [
          TextButton(
              onPressed: () {
                BlocProvider.of<MarchingCounter>(context).reset();
                Navigator.of(context).pop();
              },
              child: Text('나가기'))
        ],
      ),
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
              : _controller == null
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Expanded(
                      child: ClipRect(
                        child: CameraPreview(_controller!, child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: HorizontalLinesPainter(
                                        isInPosition: _isInPosition),
                                    size: Size(constraints.maxWidth,
                                        constraints.maxHeight),
                                  ),
                                ),
                                if (widget.customPaint != null)
                                  Positioned.fill(
                                    child: widget.customPaint!,
                                  ),
                              ],
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
                    _counterWidget(),
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

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);

    if (widget.posePainter != null && widget.posePainter!.poses.isNotEmpty) {
      final pose = widget.posePainter!.poses.first;
      final nose = pose.landmarks[PoseLandmarkType.nose];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

      if (nose != null && leftAnkle != null && rightAnkle != null) {
        final normalizedNoseY = translateY(
            nose.y,
            CanvasSize!,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            _controller!.description.lensDirection);

        final normalizedLeftAnkleY = translateY(
            leftAnkle.y,
            CanvasSize!,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            _controller!.description.lensDirection);
        final normalizedRightAnkleY = translateY(
            rightAnkle.y,
            CanvasSize!,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            _controller!.description.lensDirection);

        // 위치 확인 로직 개선
        bool isNoseInPosition =
            normalizedNoseY > topLineY! && normalizedNoseY < bottomLineY!;
        bool areAnklesInPosition = normalizedLeftAnkleY > topLineY! &&
            normalizedLeftAnkleY < bottomLineY! &&
            normalizedRightAnkleY > topLineY! &&
            normalizedRightAnkleY < bottomLineY!;

        bool newIsInPosition = isNoseInPosition && areAnklesInPosition;

        if (newIsInPosition != _isInPosition) {
          setState(() {
            _isInPosition = newIsInPosition;
          });
        }
      }
    }
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
    return ElevatedButton(
      onPressed: _isPreparing
          ? null
          : () async {
              final bloc = BlocProvider.of<MarchingCounter>(context);
              if (_cameraReady == true) {
                bloc.reset();
                _timer?.cancel();
                _remainingSeconds = 60;
              } else {
                bloc.reset();
                _startTimer();
              }
              setState(() {
                _cameraReady = !_cameraReady;
              });
            },
      child: Text(_cameraReady ? '촬영 종료' : '촬영 시작'),
    );
  }

  Widget _remainingTimeWidget() {
    return Column(
      children: [
        Text(
          _isPreparing ? '준비시간' : '측정중',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
          ),
        ),
        Text(
          _isPreparing ? '$_preparationSeconds초' : '${60 - _remainingSeconds}초',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _counterWidget() {
    final bloc = BlocProvider.of<MarchingCounter>(context);
    return Container(
      width: 70,
      decoration: BoxDecoration(
          color: Colors.black54,
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 4.0),
          borderRadius: const BorderRadius.all(Radius.circular(12))),
      child: Text(
        '${bloc.totalCounter}',
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 30.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _switchLiveCameraToggle() => ElevatedButton(
        onPressed: _switchLiveCamera,
        child: Icon(
          Platform.isIOS
              ? Icons.flip_camera_ios_outlined
              : Icons.flip_camera_android_outlined,
          size: 25,
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

  var rightKneeX = ListQueue<double>();
  var rightKneeY = ListQueue<double>();
  var rightKneeZ = ListQueue<double>();
  var leftKneeX = ListQueue<double>();
  var leftKneeY = ListQueue<double>();
  var leftKneeZ = ListQueue<double>();
  var rightAnkleX = ListQueue<double>();
  var rightAnkleY = ListQueue<double>();
  var rightAnkleZ = ListQueue<double>();
  var leftAnkleY = ListQueue<double>();
  var leftAnkleZ = ListQueue<double>();
  var rightHipX = ListQueue<double>();
  var rightHipY = ListQueue<double>();
  var rightHipZ = ListQueue<double>();
  var leftHipY = ListQueue<double>();
  var leftHipZ = ListQueue<double>();
  var rightWristY = ListQueue<double>();
  var rightWristZ = ListQueue<double>();
  var leftWristY = ListQueue<double>();
  var leftWristZ = ListQueue<double>();

  double getMean(ListQueue<double> queue) {
    if (queue.length < smoothingFrame)
      return queue.isNotEmpty ? queue.last : 0.0;

    double sum = queue.reduce((value, element) => value + element);
    queue.removeFirst();
    return sum / smoothingFrame;
  }

  void checkOutlier(double point, ListQueue<double> queue, double mean) {
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
      double correctVal = queue.elementAt(smoothingFrame - 1) +
          sumOfGaps / (smoothingFrame - 1);
      queue.add(correctVal);
    }
  }

  void smoothingPoint() {
    rightKneeXMean = getMean(rightKneeX);
    rightKneeYMean = getMean(rightKneeY);
    rightKneeZMean = getMean(rightKneeZ);

    leftKneeXMean = getMean(leftKneeX);
    leftKneeYMean = getMean(leftKneeY);
    leftKneeZMean = getMean(leftKneeZ);

    rightAnkleXMean = getMean(rightAnkleX);
    rightAnkleYMean = getMean(rightAnkleY);
    rightAnkleZMean = getMean(rightAnkleZ);

    leftAnkleYMean = getMean(leftAnkleY);
    leftAnkleZMean = getMean(leftAnkleZ);

    rightHipXMean = getMean(rightHipX);
    rightHipYMean = getMean(rightHipY);
    rightHipZMean = getMean(rightHipZ);

    leftHipYMean = getMean(leftHipY);
    leftHipZMean = getMean(leftHipZ);

    rightWristYMean = getMean(rightWristY);
    rightWristZMean = getMean(rightWristZ);

    leftWristYMean = getMean(leftWristY);
    leftWristZMean = getMean(leftWristZ);

    checkOutlier(rightkneeX, rightKneeX, rightKneeXMean);
    checkOutlier(rightkneeY, rightKneeY, rightKneeYMean);
    checkOutlier(rightkneeZ, rightKneeZ, rightKneeZMean);

    checkOutlier(leftkneeX, leftKneeX, leftKneeXMean);
    checkOutlier(leftkneeY, leftKneeY, leftKneeYMean);
    checkOutlier(leftkneeZ, leftKneeZ, leftKneeZMean);

    checkOutlier(rightankleX, rightAnkleX, rightAnkleXMean);
    checkOutlier(rightankleY, rightAnkleY, rightAnkleYMean);
    checkOutlier(rightankleZ, rightAnkleZ, rightAnkleZMean);

    checkOutlier(leftankleY, leftAnkleY, leftAnkleYMean);
    checkOutlier(leftankleZ, leftAnkleZ, leftAnkleZMean);

    checkOutlier(righthipX, rightHipX, rightHipXMean);
    checkOutlier(righthipY, rightHipY, rightHipYMean);
    checkOutlier(righthipZ, rightHipZ, rightHipZMean);

    checkOutlier(lefthipY, leftHipY, leftHipYMean);
    checkOutlier(lefthipZ, leftHipZ, leftHipZMean);

    checkOutlier(rightwristY, rightWristY, rightWristYMean);
    checkOutlier(rightwristZ, rightWristZ, rightWristZMean);

    checkOutlier(leftwristY, leftWristY, leftWristYMean);
    checkOutlier(leftwristZ, leftWristZ, leftWristZMean);
  }
}
