import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harulab/models/one_leg_model.dart';

class ResultOneLeg extends StatelessWidget {
  final standingTimer;
  const ResultOneLeg({required this.standingTimer, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('한 발 서기 결과'),
      ),
      body: Center(
        child: Column(
          children: [
            Text('$standingTimer초 만큼 한 발 서기를 하였습니다.'),
            Text('무릎 높이가 불안정합니다.'),
            Text('상체가 불안정합니다.')
          ],
        ),
      ),
    );
  }
}
