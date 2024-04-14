import 'package:flutter_bloc/flutter_bloc.dart';

enum MarchingState { neutral, legLifted, legLowered }

class MarchingCounter extends Cubit<MarchingState> {
  MarchingCounter() : super(MarchingState.neutral);
  int counter = 0;

  void setMarchingState(MarchingState current) {
    emit(current);
  }

  void increment() {
    counter++;
    emit(state);
  }

  void reset() {
    counter = 0;
    emit(state);
  }
}
