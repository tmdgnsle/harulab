import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harulab/cubit/march_model.dart';
import 'package:harulab/cubit/marching_feedback_cubit.dart';
import 'package:harulab/cubit/one_leg_feedback_cubit.dart';
import 'package:harulab/cubit/one_leg_model.dart';
import 'package:harulab/views/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MultiBlocProvider(providers: [
        BlocProvider(
          create: (context) => MarchingCounter(),
        ),
        BlocProvider(
          create: (context) => OneLegStanding(),
        ),
        BlocProvider(
          create: (context) => MarchingFeedbackCubit(),
        ),
        BlocProvider(
          create: (context) => OneLegFeedbackCubit(),
        ),
      ], child: SplashScreen()),
    );
  }
}
