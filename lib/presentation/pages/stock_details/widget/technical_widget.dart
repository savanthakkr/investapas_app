import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investapas/presentation/bloc/technical/technical_bloc.dart';
import 'package:investapas/presentation/bloc/technical/technical_event.dart';
import 'package:investapas/presentation/bloc/technical/technical_state.dart';
import 'package:investapas/presentation/pages/stock_details/widget/oscillators_widget.dart';
import 'package:investapas/presentation/pages/stock_details/widget/pivot_widget.dart';
import 'package:investapas/presentation/pages/stock_details/widget/technical_guage.dart';
import 'package:investapas/presentation/pages/stock_details/widget/type_duration_selector.dart';

import '../../../../Widgets/common_dropdown.dart';
import '../../../../core/constants/constants.dart';

class TechnicalWidget extends StatelessWidget {
  const TechnicalWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TechnicalBloc, TechnicalState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween*2),
                child: CustomDropdown(
                  selectedValue: state.selectedDropdown,
                  hintText: "Select Type",
                  borderColor: Colorz.dividerColor,
                  items: state.typeDropdown.map((e) {
                    return DropdownMenuItem<String>(
                      value: e,
                      child: Text(e),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<TechnicalBloc>().add(ChangeTypeDuration(value));
                    }
                  },
                ),
              ),
              SizeConfig.verticalSpace(height: SizeConfig.spaceBetween*3),
              Container(
                margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween*2),
                child: TechnicalGauge(),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween*2),
                child: Text(
                  "Bullish signals: 1, Bearish signals: 4 out of 9 oscillators",
                  style: AppTextStyles.medium.copyWith(color: Colorz.textColor,fontSize: SizeConfig.smallFont),
                ),
              ),
              SizeConfig.verticalSpace(height: SizeConfig.spaceBetween*2),
              Container(
                margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween*2),
                child: TypeDurationSelector(
                  selected: state.duration,
                  onSelect: (d) =>
                      context.read<TechnicalBloc>().add(ChangeDuration(d)),
                ),
              ),
              SizeConfig.verticalSpace(height: SizeConfig.spaceBetween*2),
              OscillatorsWidget(technicalState: state,isOscillator: true,),
              OscillatorsWidget(technicalState: state,isOscillator: false,),
              SizeConfig.verticalSpace(height: SizeConfig.spaceBetween),
              PivotWidget(technicalState: state,),
            ],
          ),
        );
      },
    );
  }
}
