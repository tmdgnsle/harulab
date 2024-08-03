import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harulab/cubit/one_leg_feedback_cubit.dart';

class ResultOneLeg extends StatelessWidget {
  final standingTimer;
  const ResultOneLeg({required this.standingTimer, super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<OneLegFeedbackCubit>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('한 발 서기 결과'),
      ),
      body: Center(
        child: Column(
          children: [
            Text('발 올리고 있는 시간: $standingTimer'),
            Text('평균 다리 높이: ${cubit.state.oneLegFeedbackModel.liftHeight}'),
            Text(
                '다리 높이의 일관성: ${cubit.state.oneLegFeedbackModel.liftHeightConsistency}'),
            Text(
                '왼쪽 손목 X표준편차 : ${cubit.state.oneLegFeedbackModel.stable.wrist.stdX[0]}'),
            Text(
                '왼쪽 손목 Y표준편차 : ${cubit.state.oneLegFeedbackModel.stable.wrist.stdY[0]}'),
            Text(
                '오른쪽 손목 X표준편차 : ${cubit.state.oneLegFeedbackModel.stable.wrist.stdX[1]}'),
            Text(
                '오른쪽 손목 Y표준편차 : ${cubit.state.oneLegFeedbackModel.stable.wrist.stdY[1]}'),
            Text(
                '왼쪽 팔꿈치 X표준편차 : ${cubit.state.oneLegFeedbackModel.stable.elbow.stdX[0]}'),
            Text(
                '왼쪽 팔꿈치 Y표준편차 : ${cubit.state.oneLegFeedbackModel.stable.elbow.stdY[0]}'),
            Text(
                '오른쪽 팔꿈치 X표준편차 : ${cubit.state.oneLegFeedbackModel.stable.elbow.stdX[1]}'),
            Text(
                '오른쪽 팔꿈치 Y표준편차 : ${cubit.state.oneLegFeedbackModel.stable.elbow.stdY[1]}'),
            Text(
                '왼쪽 어깨 X표준편차 : ${cubit.state.oneLegFeedbackModel.stable.shoulder.stdX[0]}'),
            Text(
                '왼쪽 어깨 Y표준편차 : ${cubit.state.oneLegFeedbackModel.stable.shoulder.stdY[0]}'),
            Text(
                '오른쪽 어깨 X표준편차 : ${cubit.state.oneLegFeedbackModel.stable.shoulder.stdX[1]}'),
            Text(
                '오른쪽 어깨 Y표준편차 : ${cubit.state.oneLegFeedbackModel.stable.shoulder.stdY[1]}'),
          ],
        ),
      ),
    );
  }
}
