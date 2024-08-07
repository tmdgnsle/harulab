import 'package:equatable/equatable.dart';

class MarchingFeedbackModel extends Equatable {
  final double swing_height;
  final double deviation;
  final double knee_height;
  final double left_swing;
  final double right_swing;
  final double mean_amplitude;

  MarchingFeedbackModel(
      {required this.swing_height,
      required this.deviation,
      required this.knee_height,
      required this.left_swing,
      required this.right_swing,
      required this.mean_amplitude});

  MarchingFeedbackModel.init()
      : this(
            deviation: 0,
            knee_height: 0,
            left_swing: 0,
            mean_amplitude: 0,
            right_swing: 0,
            swing_height: 0);

  factory MarchingFeedbackModel.fromJson(Map<String, dynamic> json) {
    return MarchingFeedbackModel(
        swing_height: json['swing_height'],
        deviation: json['deviation'],
        knee_height: json['knee_height'],
        left_swing: json['left_swing'],
        right_swing: json['right_swing'],
        mean_amplitude: json['mean_amplitude']);
  }

  @override
  List<Object?> get props => [
        swing_height,
        deviation,
        knee_height,
        left_swing,
        right_swing,
        mean_amplitude
      ];
}
