import 'package:flutter_bloc/flutter_bloc.dart';

enum OneLegLiftState { neutral, legLifted }

class OneLegCounter extends Cubit<OneLegLiftState> {
  OneLegCounter() : super(OneLegLiftState.neutral);
  int counter = 0;

  void setMarchingState(OneLegLiftState current) {
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