import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';

enum MarchingState { neutral, legLifted, legLowered }

class MarchingCounter extends Cubit<MarchingState> {
  MarchingCounter() : super(MarchingState.neutral);
  int lastCounter = 0;
  int counter_1 = 0;
  int counter_2 = 0;
  int counter_3 = 0;
  int counter_4 = 0;
  int counter_5 = 0;
  int counter_6 = 0;
  double standard_deviation = 0;

  int get totalCounter =>
      counter_1 + counter_2 + counter_3 + counter_4 + counter_5 + counter_6;

  void setMarchingState(MarchingState current) {
    if (state != current) {
      emit(current);
    }
  }

  void increment1() {
    counter_1++;
    emit(state);
  }

  void increment2() {
    counter_2++;
    emit(state);
  }

  void increment3() {
    counter_3++;
    emit(state);
  }

  void increment4() {
    counter_4++;
    emit(state);
  }

  void increment5() {
    counter_5++;
    emit(state);
  }

  void increment6() {
    counter_6++;
    emit(state);
  }

  void reset() {
    lastCounter = totalCounter;
    counter_1 = 0;
    counter_2 = 0;
    counter_3 = 0;
    counter_4 = 0;
    counter_5 = 0;
    counter_6 = 0;
    standard_deviation = 0;
    emit(state);
  }

  void calculateDeviation() {
    final double mean = totalCounter / 6;
    List<int> counters = [
      counter_1,
      counter_2,
      counter_3,
      counter_4,
      counter_5,
      counter_6
    ];
    double deviationSum =
        counters.fold(0.0, (sum, count) => sum + pow(count - mean, 2));
    standard_deviation = sqrt(deviationSum / 6);
    emit(state);
  }
}
