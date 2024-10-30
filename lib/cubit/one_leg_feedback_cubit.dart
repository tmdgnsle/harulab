import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:harulab/model/one_leg_feedback_model.dart';
import 'package:http/http.dart' as http;

class OneLegFeedbackCubit extends Cubit<OneLegFeedbackCubitState> {
  final _baseUrl = dotenv.get('API_URL');
  final _timeout = Duration(seconds: 30);

  OneLegFeedbackCubit() : super(InitOneLegFeedbackCubitState());

  Future<void> sendMarching(List<Map<String, dynamic>> json) async {
    try {
      if (state is LoadingOneLegFeedbackCubitState) return;

      emit(LoadingOneLegFeedbackCubitState(
          oneLegFeedbackModel: state.oneLegFeedbackModel));

      final response = await http
          .post(
            Uri.parse('$_baseUrl/pose_result/oneleg_lifting/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'data': json}),
          )
          .timeout(_timeout);

      print('한발서기 응답: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        emit(LoadedOneLegFeedbackCubitState(
            oneLegFeedbackModel: OneLegFeedbackModel.fromJson(data)));
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('TimeoutException 발생: $e');
      emit(ErrorOneLegFeedbackCubitState(
          oneLegFeedbackModel: state.oneLegFeedbackModel,
          errorMessage: '요청 시간이 초과되었습니다. 나중에 다시 시도해주세요.'));
    } on SocketException catch (e) {
      print('SocketException 발생: $e');
      emit(ErrorOneLegFeedbackCubitState(
          oneLegFeedbackModel: state.oneLegFeedbackModel,
          errorMessage: '네트워크 연결 오류가 발생했습니다. 인터넷 연결을 확인해주세요.'));
    } catch (e) {
      print('예외 발생: $e');
      emit(ErrorOneLegFeedbackCubitState(
          oneLegFeedbackModel: state.oneLegFeedbackModel,
          errorMessage: '오류가 발생했습니다: ${e.toString()}'));
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
