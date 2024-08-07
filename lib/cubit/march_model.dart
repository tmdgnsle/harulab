import 'package:flutter_bloc/flutter_bloc.dart';

enum MarchingState { neutral, legLifted, legLowered }

class MarchingCounter extends Cubit<MarchingState> {
  MarchingCounter() : super(MarchingState.neutral);
  int counter = 0;
  int lastcounter = 0;
  int counter_1 = 0;
  int counter_2 = 0;
  int counter_3 = 0;
  int counter_4 = 0;
  int counter_5 = 0;
  int counter_6 = 0;
  double standard_deviation = 0;

  void setMarchingState(MarchingState current) {
    if (state != current) {
      emit(current);
    }
  }

  void increment1() {
    counter_1++;
    counter++;
    emit(state);
  }

  void increment2() {
    counter_2++;
    counter++;
    emit(state);
  }

  void increment3() {
    counter_3++;
    counter++;
    emit(state);
  }

  void increment4() {
    counter_4++;
    counter++;
    emit(state);
  }

  void increment5() {
    counter_5++;
    counter++;
    emit(state);
  }

  void increment6() {
    counter_6++;
    counter++;
    emit(state);
  }

  void reset() {
    lastcounter = counter;
    counter = 0;
    counter_1 = 0;
    counter_2 = 0;
    counter_3 = 0;
    counter_4 = 0;
    counter_5 = 0;
    counter_6 = 0;
    emit(state);
  }

  void deviation() {
    final double mean = counter / 6;
    List<int> counters = [
      counter_1,
      counter_2,
      counter_3,
      counter_4,
      counter_5,
      counter_6
    ];
    double deviation_sum = 0;
    for (counter in counters) {
      deviation_sum += (mean - counter) * (mean - counter);
    }
    standard_deviation = deviation_sum / 6;
    emit(state);
  }
}
