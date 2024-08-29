import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harulab/model/one_leg_feedback_model.dart';
import 'package:http/http.dart' as http;

class OneLegFeedbackCubit extends Cubit<OneLegFeedbackCubitState> {
  final _baseUrl = 'http://localhost:8080';

  OneLegFeedbackCubit() : super(InitOneLegFeedbackCubitState());

  Future<void> sendMarching(List<Map<String, dynamic>> json) async {
    try {
      if (state is LoadingOneLegFeedbackCubitState) return;
      emit(LoadingOneLegFeedbackCubitState(
          oneLegFeedbackModel: state.oneLegFeedbackModel));
      final response =
          await http.post(Uri.parse('$_baseUrl/pose_result/marching/'),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'data': json}));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        emit(LoadedOneLegFeedbackCubitState(
            oneLegFeedbackModel: OneLegFeedbackModel.fromJson(data)));
      }
    } catch (e) {
      emit(ErrorOneLegFeedbackCubitState(
          oneLegFeedbackModel: state.oneLegFeedbackModel,
          errorMessage: e.toString()));
    }
  }
}

abstract class OneLegFeedbackCubitState extends Equatable {
  final OneLegFeedbackModel oneLegFeedbackModel;
  OneLegFeedbackCubitState({required this.oneLegFeedbackModel});

  @override
  List<Object?> get props => [oneLegFeedbackModel];
}

class InitOneLegFeedbackCubitState extends OneLegFeedbackCubitState {
  InitOneLegFeedbackCubitState()
      : super(oneLegFeedbackModel: OneLegFeedbackModel.init());
}

class LoadingOneLegFeedbackCubitState extends OneLegFeedbackCubitState {
  LoadingOneLegFeedbackCubitState({required super.oneLegFeedbackModel});
}

class LoadedOneLegFeedbackCubitState extends OneLegFeedbackCubitState {
  LoadedOneLegFeedbackCubitState({required super.oneLegFeedbackModel});
}

class ErrorOneLegFeedbackCubitState extends OneLegFeedbackCubitState {
  final String errorMessage;
  ErrorOneLegFeedbackCubitState(
      {required super.oneLegFeedbackModel, required this.errorMessage});

  @override
  List<Object?> get props => [oneLegFeedbackModel, errorMessage];
}
