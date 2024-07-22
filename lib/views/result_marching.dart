import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class ResultMarching extends StatelessWidget {
  final counter;
  const ResultMarching({required this.counter, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('제자리 걷기 결과')),
      body: Center(
        child: Column(
          children: [
            Text('$counter회의 제자리 걷기를 실행하였습니다.'),
            Text('걸음 리듬이 일정합니다.'),
            Text('무릎 높이가 안정적입니다.')
          ],
        ),
      ),
    );
  }
}
