import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harulab/cubit/one_leg_feedback_cubit.dart';

class ResultOneLeg extends StatelessWidget {
  final standingTimer;
  const ResultOneLeg({required this.standingTimer, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('한 발 서기 결과'),
      ),
      body: BlocBuilder<OneLegFeedbackCubit, OneLegFeedbackCubitState>(
        builder: (context, state) {
          if (state is LoadingOneLegFeedbackCubitState) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is ErrorOneLegFeedbackCubitState) {
            return Center(
              child: Text(state.errorMessage),
            );
          }
          if (state is LoadedOneLegFeedbackCubitState) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal, // 가로 스크롤 가능
              child: Container(
                padding: EdgeInsets.all(16),
                width: 1200, // 차트의 전체 너비
                // height: 400, // 차트의 전체 높이
                child: BarChart(
                  BarChartData(
                    groupsSpace: 40,
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 200,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String label;
                          switch (groupIndex) {
                            case 0:
                              label = '발 올리고 있는 시간: ${standingTimer}';
                              break;
                            case 1:
                              label =
                                  '평균 다리 높이: ${state.oneLegFeedbackModel.liftHeight}';
                              break;
                            case 2:
                              label =
                                  '다리 높이의 일관성: ${state.oneLegFeedbackModel.liftHeightConsistency}';
                              break;
                            case 3:
                              label =
                                  '왼쪽 손목 X표준편차: ${state.oneLegFeedbackModel.stable.wrist.stdX[0]}';
                              break;
                            case 4:
                              label =
                                  '왼쪽 손목 Y표준편차: ${state.oneLegFeedbackModel.stable.wrist.stdY[0]}';
                              break;
                            case 5:
                              label =
                                  '오른쪽 손목 X표준편차: ${state.oneLegFeedbackModel.stable.wrist.stdX[1]}';
                              break;
                            case 6:
                              label =
                                  '오른쪽 손목 Y표준편차: ${state.oneLegFeedbackModel.stable.wrist.stdY[1]}';
                              break;
                            case 7:
                              label =
                                  '왼쪽 팔꿈치 X표준편차: ${state.oneLegFeedbackModel.stable.elbow.stdX[0]}';
                              break;
                            case 8:
                              label =
                                  '왼쪽 팔꿈치 Y표준편차: ${state.oneLegFeedbackModel.stable.elbow.stdY[0]}';
                              break;
                            case 9:
                              label =
                                  '오른쪽 팔꿈치 X표준편차: ${state.oneLegFeedbackModel.stable.elbow.stdX[1]}';
                              break;
                            case 10:
                              label =
                                  '오른쪽 팔꿈치 Y표준편차: ${state.oneLegFeedbackModel.stable.elbow.stdY[1]}';
                              break;
                            case 11:
                              label =
                                  '왼쪽 어깨 X표준편차: ${state.oneLegFeedbackModel.stable.shoulder.stdX[0]}';
                              break;
                            case 12:
                              label =
                                  '왼쪽 어깨 Y표준편차: ${state.oneLegFeedbackModel.stable.shoulder.stdY[0]}';
                              break;
                            case 13:
                              label =
                                  '오른쪽 어깨 X표준편차: ${state.oneLegFeedbackModel.stable.shoulder.stdX[1]}';
                              break;
                            case 14:
                              label =
                                  '오른쪽 어깨 Y표준편차: ${state.oneLegFeedbackModel.stable.shoulder.stdY[1]}';
                              break;
                            default:
                              label = '';
                          }
                          return BarTooltipItem(
                            label,
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            String text;
                            switch (value.toInt()) {
                              case 0:
                                text = '발 올리고\n있는 시간';
                                break;
                              case 1:
                                text = '평균 다리\n높이';
                                break;
                              case 2:
                                text = '다리 높이\n일관성';
                                break;
                              case 3:
                                text = '왼쪽 손목\nX\n표준편차';
                                break;
                              case 4:
                                text = '왼쪽 손목\nY\n표준편차';
                                break;
                              case 5:
                                text = '오른쪽 손목\nX\n표준편차';
                                break;
                              case 6:
                                text = '오른쪽 손목\nY\n표준편차';
                                break;
                              case 7:
                                text = '왼쪽 팔꿈치\nX\n표준편차';
                                break;
                              case 8:
                                text = '왼쪽 팔꿈치\nY\n표준편차';
                                break;
                              case 9:
                                text = '오른쪽 팔꿈치\nX\n표준편차';
                                break;
                              case 10:
                                text = '오른쪽 팔꿈치\nY\n표준편차';
                                break;
                              case 11:
                                text = '왼쪽 어깨\nX\n표준편차';
                                break;
                              case 12:
                                text = '왼쪽 어깨\nY\n표준편차';
                                break;
                              case 13:
                                text = '오른쪽 어깨\nX\n표준편차';
                                break;
                              case 14:
                                text = '오른쪽 어깨\nY\n표준편차';
                                break;
                              default:
                                text = '';
                            }
                            return Padding(
                              padding:
                                  EdgeInsets.only(top: 8, left: 4, right: 4),
                              child: Text(
                                text,
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                          reservedSize: 60, // 하단 레이블 공간 확보
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40, // 왼쪽 레이블 공간 확보
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // 오른쪽 레이블 숨김
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // 상단 레이블 숨김
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false, // 수직 그리드 라인 숨김
                    ),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                              toY: standingTimer.toDouble(), color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                              toY: state.oneLegFeedbackModel.liftHeight
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.liftHeightConsistency
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 3,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.wrist.stdX[0]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 4,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.wrist.stdY[0]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 5,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.wrist.stdX[1]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 6,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.wrist.stdY[1]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 7,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.elbow.stdX[0]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 8,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.elbow.stdY[0]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 9,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.elbow.stdX[1]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 10,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.elbow.stdY[1]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 11,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.shoulder.stdX[0]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 12,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.shoulder.stdY[0]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 13,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.shoulder.stdX[1]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 14,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .oneLegFeedbackModel.stable.shoulder.stdY[1]
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Container();
        },
      ),
    );
  }
}
