import 'package:equatable/equatable.dart';

class MarchingFeedbackModel extends Equatable {
  final double right_angles;
  final double left_angles;
  final double swing_deviation;
  final double knee_height_deviation;
  final double knee_height;
  final double left_swing_strength;
  final double right_swing_strength;

  MarchingFeedbackModel({
    required this.right_angles,
    required this.left_angles,
    required this.swing_deviation,
    required this.knee_height_deviation,
    required this.knee_height,
    required this.left_swing_strength,
    required this.right_swing_strength,
  });

  MarchingFeedbackModel.init()
      : this(
            right_angles: 0,
            left_angles: 0,
            knee_height_deviation: 0,
            knee_height: 0,
            left_swing_strength: 0,
            right_swing_strength: 0,
            swing_deviation: 0);

  factory MarchingFeedbackModel.fromJson(Map<String, dynamic> json) {
    return MarchingFeedbackModel(
      right_angles: json['right_angles'],
      left_angles: json['left_angles'],
      swing_deviation: json['swing_deviation'],
      knee_height_deviation: json['knee_height_deviation'],
      knee_height: json['knee_height'],
      left_swing_strength: json['left_swing_strength'],
      right_swing_strength: json['right_swing_strength'],
    );
  }

  @override
  List<Object?> get props => [
        right_angles,
        left_angles,
        swing_deviation,
        knee_height_deviation,
        knee_height,
        left_swing_strength,
        right_swing_strength,
      ];
}
