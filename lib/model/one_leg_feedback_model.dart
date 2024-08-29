import 'package:equatable/equatable.dart';

class OneLegFeedbackModel extends Equatable {
  final double liftHeight;
  final double liftHeightConsistency;
  final Stable stable;

  OneLegFeedbackModel({
    required this.liftHeight,
    required this.liftHeightConsistency,
    required this.stable,
  });

  OneLegFeedbackModel.init()
      : this(
            liftHeight: 0,
            liftHeightConsistency: 0,
            stable: Stable(
                shoulder: BodyPartData(stdX: [], stdY: []),
                wrist: BodyPartData(stdX: [], stdY: []),
                elbow: BodyPartData(stdX: [], stdY: [])));

  factory OneLegFeedbackModel.fromJson(Map<String, dynamic> json) {
    return OneLegFeedbackModel(
      liftHeight: json['lift_height'],
      liftHeightConsistency: json['lift_height_consistency'],
      stable: Stable.fromJson(json['stable']),
    );
  }

  @override
  List<Object?> get props => [liftHeight, liftHeightConsistency, stable];
}

class Stable {
  final BodyPartData shoulder;
  final BodyPartData wrist;
  final BodyPartData elbow;

  Stable({
    required this.shoulder,
    required this.wrist,
    required this.elbow,
  });

  factory Stable.fromJson(Map<String, dynamic> json) {
    return Stable(
      shoulder: BodyPartData.fromJson(json['shoulder']),
      wrist: BodyPartData.fromJson(json['wrist']),
      elbow: BodyPartData.fromJson(json['elbow']),
    );
  }
}

class BodyPartData {
  final List<double> stdX;
  final List<double> stdY;

  BodyPartData({
    required this.stdX,
    required this.stdY,
  });

  factory BodyPartData.fromJson(Map<String, dynamic> json) {
    return BodyPartData(
      stdX: List<double>.from(json['std_x']),
      stdY: List<double>.from(json['std_y']),
    );
  }
}
