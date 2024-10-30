import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harulab/cubit/marching_feedback_cubit.dart';

class ResultMarching extends StatelessWidget {
  final int counter;
  final double standard_deviation;

  const ResultMarching(
      {required this.counter, required this.standard_deviation, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('제자리 걷기 결과')),
      body: BlocBuilder<MarchingFeedbackCubit, MarchingFeedbackCubitState>(
        builder: (context, state) {
          if (state is LoadingMarchingFeedbackCubitState) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is ErrorMarchingFeedbackCubitState) {
            return Center(
              child: Text(state.errorMessage),
            );
          }
          if (state is LoadedMarchingFeedbackCubitState) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal, // 가로 스크롤 가능
              child: Container(
                padding: EdgeInsets.all(16),
                width: 800, // 차트의 전체 너비
                // height: 400, // 차트의 전체 높이
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 700,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String label;
                          switch (groupIndex) {
                            case 0:
                              label = '걸음 수: ${counter}';
                              break;
                            case 1:
                              label =
                                  '왼쪽 무릎 각도: ${state.marchingFeedbackModel.right_angles}';
                              break;
                            case 2:
                              label =
                                  '오른쪽 무릎 각도: ${state.marchingFeedbackModel.left_angles}';
                              break;
                            case 3:
                              label =
                                  '무릎 높이: ${state.marchingFeedbackModel.knee_height}';
                              break;
                            case 4:
                              label = '걸음 간격: ${standard_deviation}';
                              break;
                            case 5:
                              label =
                                  '무릎 높이 편차: ${state.marchingFeedbackModel.knee_height_deviation}';
                              break;
                            case 6:
                              label =
                                  '왼팔 스윙: ${state.marchingFeedbackModel.left_swing_strength}';
                              break;
                            case 7:
                              label =
                                  '오른팔 스윙: ${state.marchingFeedbackModel.right_swing_strength}';
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
                                text = '걸음수';
                                break;
                              case 1:
                                text = '왼쪽\n무릎';
                                break;
                              case 2:
                                text = '오른쪽\n무릎';
                                break;
                              case 3:
                                text = '무릎\n높이';
                                break;
                              case 4:
                                text = '걸음\n간격';
                                break;
                              case 5:
                                text = '높이\n편차';
                                break;
                              case 6:
                                text = '왼팔\n스윙';
                                break;
                              case 7:
                                text = '오른팔\n스윙';
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
                          reservedSize: 40, // 하단 레이블 공간 확보
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
                              toY: counter.toDouble(), color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                              toY: state.marchingFeedbackModel.right_angles
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                              toY: state.marchingFeedbackModel.left_angles
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 3,
                        barRods: [
                          BarChartRodData(
                              toY: state.marchingFeedbackModel.knee_height
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 4,
                        barRods: [
                          BarChartRodData(
                              toY: standard_deviation.toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 5,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .marchingFeedbackModel.knee_height_deviation
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 6,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .marchingFeedbackModel.left_swing_strength
                                  .toDouble(),
                              color: Colors.blue)
                        ],
                      ),
                      BarChartGroupData(
                        x: 7,
                        barRods: [
                          BarChartRodData(
                              toY: state
                                  .marchingFeedbackModel.right_swing_strength
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
