import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:harulab/model/marching_feedback_model.dart';
import 'package:http/http.dart' as http;

class MarchingFeedbackCubit extends Cubit<MarchingFeedbackCubitState> {
  final _baseUrl = dotenv.get('API_URL');
  final _timeout = Duration(seconds: 30);

  MarchingFeedbackCubit() : super(InitMarchingFeedbackCubitState());

  Future<void> sendMarching(List<Map<String, dynamic>> json) async {
    try {
      if (state is LoadingMarchingFeedbackCubitState) return;
      emit(LoadingMarchingFeedbackCubitState(
          marchingFeedbackModel: state.marchingFeedbackModel));

      print('제자리걷기 데이터 보내기');
      final response = await http
          .post(
            Uri.parse('$_baseUrl/pose_result/marching/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'data': json}),
          )
          .timeout(_timeout);

      print('제자리걷기 응답: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        emit(LoadedMarchingFeedbackCubitState(
            marchingFeedbackModel: MarchingFeedbackModel.fromJson(data)));
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('TimeoutException 발생: $e');
      emit(ErrorMarchingFeedbackCubitState(
          marchingFeedbackModel: state.marchingFeedbackModel,
          errorMessage: '요청 시간이 초과되었습니다. 나중에 다시 시도해주세요.'));
    } on SocketException catch (e) {
      print('SocketException 발생: $e');
      emit(ErrorMarchingFeedbackCubitState(
          marchingFeedbackModel: state.marchingFeedbackModel,
          errorMessage: '네트워크 연결 오류가 발생했습니다. 인터넷 연결을 확인해주세요.'));
    } catch (e) {
      print('예외 발생: $e');
      emit(ErrorMarchingFeedbackCubitState(
          marchingFeedbackModel: state.marchingFeedbackModel,
          errorMessage: '오류가 발생했습니다: ${e.toString()}'));
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
