import 'package:flutter_bloc/flutter_bloc.dart';

enum OneLegState { legLifted, legLowered }

class OneLegStanding extends Cubit<OneLegState> {
  OneLegStanding() : super(OneLegState.legLowered);
  bool standing = false;

  void setMarchingState(OneLegState current) {
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
}
