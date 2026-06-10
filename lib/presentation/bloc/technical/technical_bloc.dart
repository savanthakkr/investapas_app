import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investapas/data/models/pivot_model.dart';
import 'package:investapas/data/models/technical_type_model.dart';
import 'package:investapas/presentation/bloc/technical/technical_event.dart';
import 'package:investapas/presentation/bloc/technical/technical_state.dart';

class TechnicalBloc extends Bloc<TechnicalEvent, TechnicalState> {
  TechnicalBloc() : super(const TechnicalState()) {
    on<ChangeDuration>((event, emit) {

      List<double> data;
      int buy = 0;
      int sell = 0;
      int neutral = 0;

      switch (event.duration) {

        case TechnicalDuration.min1:
          buy = 2;
          sell = 6;
          neutral = 1;
          break;

        case TechnicalDuration.min5:
          buy = 4;
          sell = 3;
          neutral = 2;
          break;

        case TechnicalDuration.min15:
          buy = 6;
          sell = 2;
          neutral = 1;
          break;

        case TechnicalDuration.min30:
          buy = 7;
          sell = 1;
          neutral = 1;
          break;

        case TechnicalDuration.hour1:
          buy = 8;
          sell = 0;
          neutral = 1;
          break;
      }

      final total = buy + sell + neutral;
      final score = total == 0 ? 50 : (buy / total) * 100;

      emit(state.copyWith(
        duration: event.duration,
        buy: buy,
        sell: sell,
        neutral: neutral,
        oscillatorScore: double.parse(score.toString()),
      ));
    });

    on<LoadOscillator>((event, emit) {

      final oscillatorList = [
        const TechnicalTypeModel(
          name: "Relative Strength Index (14)",
          value: "46.07",
          action: "Neutral",
        ),
        const TechnicalTypeModel(
          name: "Stochastic %K (14, 3, 3)",
          value: "38.06",
          action: "Neutral",
        ),
        const TechnicalTypeModel(
          name: "Commodity Channel Index (20)",
          value: "38.06",
          action: "Neutral",
        ),
        const TechnicalTypeModel(
          name: "Average Directional Index (14)",
          value: "15.56",
          action: "Neutral",
        ),
        const TechnicalTypeModel(
          name: "Bollinger Bands (20)",
          value: "-0.5",
          action: "Sell",
        ),
        const TechnicalTypeModel(
          name: "On-Balance Volume (14)",
          value: "120.45",
          action: "Sell",
        ),
      ];

      emit(state.copyWith(oscillatorList: oscillatorList));
    });

    on<LoadMovingAverage>((event, emit) {

      final movingList = [
        const TechnicalTypeModel(
          name: "Exponential Moving Average (10)",
          value: "26,016.79",
          action: "Buy",
        ),
        const TechnicalTypeModel(
          name: "Simple Moving Average (10)",
          value: "38.06",
          action: "Sell",
        ),
        const TechnicalTypeModel(
          name: "Exponential Moving Average (20)",
          value: "38.06",
          action: "Neutral",
        ),
        const TechnicalTypeModel(
          name: "Average Directional Index (14)",
          value: "15.56",
          action: "Neutral",
        ),
        const TechnicalTypeModel(
          name: "Bollinger Bands (20)",
          value: "-0.5",
          action: "Sell",
        ),
        const TechnicalTypeModel(
          name: "On-Balance Volume (14)",
          value: "120.45",
          action: "Sell",
        ),
      ];
      emit(state.copyWith(movingList: movingList));
    });

    on<LoadPivot>((event, emit) {

      final pivotList = [
        const PivotModel(
          pivot: "R3",
          classic: "26,016.79",
          fibonacci: "26,016.79",
          action: "Buy",
        ),
        const PivotModel(
          pivot: "R2",
          classic: "26,016.79",
          fibonacci: "26,016.79",
          action: "Sell",
        ),
        const PivotModel(
          pivot: "R1",
          classic: "26,016.79",
          fibonacci: "26,016.79",
          action: "Neutral",
        ),
        const PivotModel(
          pivot: "P",
          classic: "26,016.79",
          fibonacci: "26,016.79",
          action: "Neutral",
        ),
        const PivotModel(
          pivot: "S1",
          classic: "26,016.79",
          fibonacci: "26,016.79",
          action: "Sell",
        ),
        const PivotModel(
          pivot: "S2",
          classic: "26,016.79",
          fibonacci: "26,016.79",
          action: "Sell",
        ),
      ];
      emit(state.copyWith(pivotList: pivotList));
    });

    on<ChangeTypeDuration>((event, emit) {
      emit(state.copyWith(selectedDropdown: event.duration));
    });

    add(const ChangeDuration(TechnicalDuration.min1));
    add(LoadOscillator());
    add(LoadMovingAverage());
    add(LoadPivot());
  }
}