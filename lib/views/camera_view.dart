import 'dart:collection';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:harulab/models/march_model.dart';
import 'package:harulab/painters/pose_painter.dart';
import 'package:harulab/utils.dart' as utils;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraView extends StatefulWidget {
  CameraView(
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
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
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

  List<List<dynamic>> rows = [];

  double rightKneeXMean = 0;
  double rightKneeYMean = 0;
  double rightAnkleXMean = 0;
  double rightAnkleYMean = 0;
  double rightHipXMean = 0;
  double rightHipYMean = 0;

  var firstAngle = 0.0;
  var secondAngle = 0.0;

  var kneeX;
  var kneeY;
  var ankleX;
  var ankleY;
  var hipX;
  var hipY;

  Future<void> requestPermissions() async {
    await [Permission.camera, Permission.storage].request();
  }

  void saveCSV(double kneeAngle, double? kneeHeight, String fileName) async {
    Directory? directory =
        await getExternalStorageDirectory(); // Scoped to your app's directory
    if (directory == null) {
      print('Cannot find the directory');
      return;
    }

    String filePath = '${directory.path}/$fileName.csv';
    File file = File(filePath);
    List<dynamic> row = [DateTime.now().toString(), kneeAngle, kneeHeight];
    String csvData = const ListToCsvConverter().convert([row]);

    try {
      await file.writeAsString('$csvData\n',
          mode: FileMode.append, flush: true);
      print('CSV data saved successfully to $filePath');
    } catch (e) {
      print('Failed to save CSV data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
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
  void didUpdateWidget(covariant CameraView oldWidget) {
    final Size size = MediaQuery.of(context).size;
    if (widget.customPaint != oldWidget.customPaint) {
      if (widget.customPaint == null) return;
      if (_cameraReady == true) {
        final bloc =
            BlocProvider.of<MarchingCounter>(context); // 제자리 걸음 운동 카운터 블록
        for (final pose in widget.posePainter!.poses) {
          PoseLandmark getPoseLandmark(PoseLandmarkType type) {
            final PoseLandmark joint = pose.landmarks[type]!;
            return joint;
          }

          // 오른쪽 다리의 포즈 랜드마크 추출
          var knee = getPoseLandmark(PoseLandmarkType.rightKnee);
          var ankle = getPoseLandmark(PoseLandmarkType.rightAnkle);
          var hip = getPoseLandmark(PoseLandmarkType.rightHip);

          kneeX = knee.x;
          kneeY = knee.y;
          ankleX = ankle.x;
          ankleY = ankle.y;
          hipX = hip.x;
          hipY = hip.y;

          // 무릎 각도 검증
          if (knee != null && ankle != null && hip != null) {
            smoothingPoint(size);

            final Offset offKnee = Offset(rightKneeXMean, rightKneeYMean);
            final Offset offAnkle = Offset(rightAnkleXMean, rightAnkleYMean);
            final Offset offHip = Offset(rightHipXMean, rightHipYMean);

            final kneeAngle = utils.angle(offHip, offKnee, offAnkle);

            final marchingState = utils.isMarching(kneeAngle, bloc.state);
            print('Knee Angle: ${kneeAngle.toStringAsFixed(2)}');
            saveCSV(kneeAngle, null, 'kneeAngleSmoothing');

            if (marchingState != null) {
              if (marchingState == MarchingState.legLifted) {
                bloc.setMarchingState(marchingState);
                if (secondAngle < kneeAngle && secondAngle < firstAngle) {
                  saveCSV(secondAngle, kneeY, 'marchingTime');
                }
              } else if (marchingState == MarchingState.legLowered) {
                bloc.increment(); // 제자리 걸음 횟수 증가
                bloc.setMarchingState(MarchingState.neutral); // 상태 초기화
              }
            }
            firstAngle = secondAngle;
            print('First Angle: $firstAngle');
            secondAngle = kneeAngle;
            print('Second Angle: $secondAngle');
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
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: _changingCameraLens
                ? Center(
                    child: const Text('Changing camera lens'),
                  )
                : CameraPreview(
                    _controller!,
                    child: widget.customPaint,
                  ),
          ),
          _counterWidget(),
          _backButton(),
          _switchLiveCameraToggle(),
          _detectionViewModeToggle(),
          _zoomControl(),
          _exposureControl(),
          _cameraButton(),
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
        onPressed: () async {
          final bloc = BlocProvider.of<MarchingCounter>(context);
          if (_cameraReady == true) {
            bloc.reset();
          }
          setState(() {
            _cameraReady = !_cameraReady;
          });
        },
        child: Text(_cameraReady ? '촬영 종료' : '촬영 시작'),
      ),
    );
  }

  Widget _counterWidget() {
    final bloc = BlocProvider.of<MarchingCounter>(context);
    return Positioned(
      left: 0,
      right: 0,
      top: 50,
      child: Container(
        width: 70,
        child: Column(
          children: [
            const Text(
              'Counter',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            Container(
              width: 70,
              decoration: BoxDecoration(
                  color: Colors.black54,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 4.0),
                  borderRadius: const BorderRadius.all(Radius.circular(12))),
              child: Text(
                '${bloc.counter}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backButton() => Positioned(
        top: 40,
        left: 8,
        child: SizedBox(
          height: 50.0,
          width: 50.0,
          child: FloatingActionButton(
            heroTag: Object(),
            onPressed: () {
              BlocProvider.of<MarchingCounter>(context).reset();
              Navigator.of(context).pop();
            },
            backgroundColor: Colors.black54,
            child: Icon(
              Icons.arrow_back_ios_outlined,
              size: 20,
            ),
          ),
        ),
      );

  Widget _detectionViewModeToggle() => Positioned(
        bottom: 8,
        left: 8,
        child: SizedBox(
          height: 50.0,
          width: 50.0,
          child: FloatingActionButton(
            heroTag: Object(),
            onPressed: widget.onDetectorViewModeChanged,
            backgroundColor: Colors.black54,
            child: Icon(
              Icons.photo_library_outlined,
              size: 25,
            ),
          ),
        ),
      );

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

  Widget _zoomControl() => Positioned(
        bottom: 16,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 250,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Slider(
                    value: _currentZoomLevel,
                    min: _minAvailableZoom,
                    max: _maxAvailableZoom,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    onChanged: (value) async {
                      setState(() {
                        _currentZoomLevel = value;
                      });
                      await _controller?.setZoomLevel(value);
                    },
                  ),
                ),
                Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        '${_currentZoomLevel.toStringAsFixed(1)}x',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _exposureControl() => Positioned(
        top: 40,
        right: 8,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 250,
          ),
          child: Column(children: [
            Container(
              width: 55,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    '${_currentExposureOffset.toStringAsFixed(1)}x',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: SizedBox(
                  height: 30,
                  child: Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    onChanged: (value) async {
                      setState(() {
                        _currentExposureOffset = value;
                      });
                      await _controller?.setExposureOffset(value);
                    },
                  ),
                ),
              ),
            )
          ]),
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

  var rightKneeX = ListQueue<double>();
  var rightKneeY = ListQueue<double>();
  var rightAnkleX = ListQueue<double>();
  var rightAnkleY = ListQueue<double>();
  var rightHipX = ListQueue<double>();
  var rightHipY = ListQueue<double>();

  double getMean(ListQueue<double> queue) {
    if (queue.length < smoothingFrame)
      return queue.isNotEmpty ? queue.last : 0.0;

    double sum = queue.reduce((value, element) => value + element);
    queue.removeFirst();
    return sum / smoothingFrame;
  }

  void checkOutlier(
      double point, ListQueue<double> queue, double mean, double maximum) {
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
        double correctVal = queue.elementAt(smoothingFrame - 1) +
            sumOfGaps / (smoothingFrame - 1);
        queue.add(correctVal);
      }
    }
  }

  void smoothingPoint(Size size) {
    rightKneeXMean = getMean(rightKneeX);
    rightKneeYMean = getMean(rightKneeY);
    rightAnkleXMean = getMean(rightAnkleX);
    rightAnkleYMean = getMean(rightAnkleY);
    rightHipXMean = getMean(rightHipX);
    rightHipYMean = getMean(rightHipY);

    log('$rightKneeXMean , $rightKneeYMean , $rightAnkleXMean , $rightAnkleYMean , $rightHipXMean , $rightHipYMean');

    checkOutlier(kneeX, rightKneeX, rightKneeXMean, size.width);
    checkOutlier(kneeY, rightKneeY, rightKneeYMean, size.height);
    checkOutlier(ankleX, rightAnkleX, rightAnkleXMean, size.width);
    checkOutlier(ankleY, rightAnkleY, rightAnkleYMean, size.height);
    checkOutlier(hipX, rightHipX, rightHipXMean, size.width);
    checkOutlier(hipY, rightHipY, rightHipYMean, size.height);
  }
}
