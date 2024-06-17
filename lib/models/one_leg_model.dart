import 'package:flutter_bloc/flutter_bloc.dart';

enum OneLegState { legLifted, legLowered }

class OneLegStanding extends Cubit<OneLegState> {
  OneLegStanding() : super(OneLegState.legLowered);
  bool standing = false;
  int standingTimer = 0;

  void setOneLegState(OneLegState current) {
    emit(current);
  }

  void lift() {
    standing = true;

    emit(state);
  }

  void low() {
    standing = false;
    emit(state);
  }

  void setTime(int time) {
    standingTimer = time;
    emit(state);
  }
}
