import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harulab/cubit/marching_feedback_cubit.dart';

class ResultMarching extends StatelessWidget {
  final int counter;
  final double standad_deviation;
  const ResultMarching(
      {required this.counter, required this.standad_deviation, super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<MarchingFeedbackCubit>(context);
    return Scaffold(
      appBar: AppBar(title: Text('제자리 걷기 결과')),
      body: Center(
        child: Column(
          children: [
            Text('걸음 수: $counter'),
            Text('무릎 높이: ${cubit.state.marchingFeedbackModel.knee_height}'),
            Text('걸음 간격: $standad_deviation'),
            Text(
                '양쪽 무릎 높이의 편차: ${cubit.state.marchingFeedbackModel.deviation}'),
            Text('왼팔 스윙: ${cubit.state.marchingFeedbackModel.left_swing}'),
            Text('오른팔 스윙: ${cubit.state.marchingFeedbackModel.right_swing}'),
            Text(
                '양 팔 손목 높이의 편차: ${cubit.state.marchingFeedbackModel.mean_amplitude}'),
          ],
        ),
      ),
    );
  }
}
