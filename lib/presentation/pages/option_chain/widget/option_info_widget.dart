import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/constants.dart';
import '../../../../data/models/option_chain_model.dart';
import '../../../bloc/option_chain/option_chain_state.dart';

class OptionInfoWidget extends StatelessWidget {
  final OptionChainState? optionChainState;
  const OptionInfoWidget({super.key,this.optionChainState});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween*2,vertical: SizeConfig.spaceBetween*0.9),
            color: Colorz.bottomPillBg,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      "Chng in OL",
                      style: AppTextStyles.medium.copyWith(fontSize: SizeConfig.smallerFont,color: Colorz.hintTextColor),
                    ),
                  ),
                ),
                SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween*0.5),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 5.sp,
                        width: 5.sp,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colorz.redColor
                        ),
                      ),
                      SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween*0.2),
                      Text(
                        "Call OI",
                        style: AppTextStyles.medium.copyWith(fontSize: SizeConfig.smallerFont,color: Colorz.hintTextColor),
                      ),
                    ],
                  ),
                ),
                SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween*0.5),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Strike",
                      style: AppTextStyles.medium.copyWith(fontSize: SizeConfig.smallerFont,color: Colorz.hintTextColor),
                    ),
                  ),
                ),
                SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween*0.5),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 5.sp,
                        width: 5.sp,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colorz.greenColor
                        ),
                      ),
                      SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween*0.2),
                      Text(
                        "Put OI",
                        style: AppTextStyles.medium.copyWith(fontSize: SizeConfig.smallerFont,color: Colorz.hintTextColor),
                      ),
                    ],
                  ),
                ),
                SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween*0.5),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "OI Chg",
                      style: AppTextStyles.medium.copyWith(fontSize: SizeConfig.smallerFont,color: Colorz.hintTextColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: optionChainState!.allItems.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final item = optionChainState!.allItems[index];
              return OptionChainItem(item: item,);
            },
            separatorBuilder: (_, __) => Divider(color: Colorz.dividerColor,thickness: 1,),
          ),
          SizeConfig.verticalSpace(height: SizeConfig.spaceBetween*2),
        ],
      ),
    );
  }
}

class OptionChainItem extends StatelessWidget {
  final OptionChainModel? item;
  const OptionChainItem({super.key,this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Align(
              alignment: AlignmentGeometry.centerLeft,
              child: Text(
                item!.callVolume,
                style: AppTextStyles.medium.copyWith(color: Colorz.textColor),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: AlignmentGeometry.center,
              child: Text(
                item!.callOi,
                style: AppTextStyles.medium.copyWith(color: Colorz.textColor),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item!.strike,
                  style: AppTextStyles.medium.copyWith(color: Colorz.textColor),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 3.sp,
                      width: 7.sp,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.sp),
                          color: Colorz.redColor
                      ),
                    ),
                    SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween*0.2),
                    Container(
                      height: 3.sp,
                      width: 15.sp,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.sp),
                          color: Colorz.greenColor
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: AlignmentGeometry.center,
              child: Text(
                item!.putOi,
                style: AppTextStyles.medium.copyWith(color: Colorz.textColor),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: AlignmentGeometry.centerRight,
              child: Text(
                item!.changeOi,
                style: AppTextStyles.medium.copyWith(color: Colorz.textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}