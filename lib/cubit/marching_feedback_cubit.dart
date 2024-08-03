import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harulab/model/marching_feedback_model.dart';
import 'package:http/http.dart' as http;

class MarchingFeedbackCubit extends Cubit<MarchingFeedbackCubitState> {
  final _baseUrl = 'http://localhost:8080';

  MarchingFeedbackCubit() : super(InitMarchingFeedbackCubitState());

  Future<void> sendMarching(Map<String, dynamic> json) async {
    try {
      if (state is LoadingMarchingFeedbackCubitState) return;
      emit(LoadingMarchingFeedbackCubitState(
          marchingFeedbackModel: state.marchingFeedbackModel));
      final response =
          await http.post(Uri.parse('$_baseUrl/pose_result/marching/'),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'data': json}));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        emit(LoadedMarchingFeedbackCubitState(
            marchingFeedbackModel: MarchingFeedbackModel.fromJson(data)));
      }
    } catch (e) {
      emit(ErrorMarchingFeedbackCubitState(
          marchingFeedbackModel: state.marchingFeedbackModel,
          errorMessage: e.toString()));
    }
  }
}

abstract class MarchingFeedbackCubitState extends Equatable {
  final MarchingFeedbackModel marchingFeedbackModel;
  MarchingFeedbackCubitState({required this.marchingFeedbackModel});

  @override
  List<Object?> get props => [marchingFeedbackModel];
}

class InitMarchingFeedbackCubitState extends MarchingFeedbackCubitState {
  InitMarchingFeedbackCubitState()
      : super(marchingFeedbackModel: MarchingFeedbackModel.init());
}

class LoadingMarchingFeedbackCubitState extends MarchingFeedbackCubitState {
  LoadingMarchingFeedbackCubitState({required super.marchingFeedbackModel});
}

class LoadedMarchingFeedbackCubitState extends MarchingFeedbackCubitState {
  LoadedMarchingFeedbackCubitState({required super.marchingFeedbackModel});
}

class ErrorMarchingFeedbackCubitState extends MarchingFeedbackCubitState {
  final String errorMessage;
  ErrorMarchingFeedbackCubitState(
      {required super.marchingFeedbackModel, required this.errorMessage});

  @override
  List<Object?> get props => [marchingFeedbackModel, errorMessage];
}
