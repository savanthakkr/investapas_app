import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:investapas/Widgets/Widgets.dart';
import 'package:investapas/core/constants/constants.dart';
import 'package:investapas/presentation/pages/dashBoard/home/widget/challange_progress.dart';
import 'package:investapas/presentation/pages/dashBoard/home/widget/create_challange_widget.dart';
import 'package:investapas/presentation/pages/dashBoard/home/widget/free_challange_widget.dart';
import 'package:investapas/presentation/pages/dashBoard/home/widget/rule_summary_widget.dart';

import '../../../../core/utils/navigationService.dart';
import '../../../../routes/appRoutes.dart';
import '../../../bloc/dashboard/bloc.dart';
import '../../../bloc/dashboard/event.dart';
import '../../../bloc/dashboard/state.dart';
import '../../../bloc/profile/profile_bloc.dart';
import '../../../bloc/profile/profile_state.dart';
import '../../../bloc/wallet/wallet_bloc.dart';
import '../../../bloc/wallet/wallet_event.dart';
import '../../../bloc/wallet/wallet_state.dart';
import '../../challenge_history/challenge_history_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Load wallet balance when home is shown
    context.read<WalletBloc>().add(const LoadWalletBalance());

    return BlocBuilder<DashBoardBloc, DashBoardState>(
      builder: (context,state) {
        return Container(
          margin: EdgeInsets.only(
            left: SizeConfig.spaceBetween * 2,
            right: SizeConfig.spaceBetween * 2,
            top: 50.sp,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, profileState) {
                      return Container(
                        width: 48.sp,
                        height: 48.sp,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colorz.primary.withValues(alpha: 0.15),
                          border: Border.all(color: Colorz.primary, width: 1.5),
                        ),
                        child: ClipOval(
                          child: profileState.profilePicture.isNotEmpty
                              ? Image.network(
                                  profileState.profilePicture,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, color: Colorz.primary, size: 26.sp),
                                )
                              : Icon(Icons.person_rounded, color: Colorz.primary, size: 26.sp),
                        ),
                      );
                    },
                  ),
                  SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween*0.9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back, ${state.clientName} 👋",
                          style: AppTextStyles.semiBold.copyWith(fontSize: SizeConfig.mediumFont,color: Colorz.textColor),
                        ),
                        Text(
                          "Good luck for today's session",
                          style: AppTextStyles.medium.copyWith(fontWeight: FontWeight.w500,color: Colorz.hintTextColor),
                        )
                      ],
                    ),
                  ),
                  // ── Wallet badge ──────────────────────────────────────
                  BlocBuilder<WalletBloc, WalletState>(
                    builder: (context, wState) => GestureDetector(
                      onTap: () => NavigatorService.pushNamed(AppRoutes.walletPage),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colorz.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colorz.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.toll_rounded, color: Colors.amber, size: 16.sp),
                            SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween * 0.4),
                            Text(
                              '${wState.balance}',
                              style: AppTextStyles.semiBold.copyWith(
                                color: Colorz.primary,
                                fontSize: SizeConfig.smallFont,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizeConfig.verticalSpace(height: SizeConfig.spaceBetween*5),
                      if (state.challengeLoading)
                        const Center(child: CircularProgressIndicator(color: Colorz.primary))
                      else if (state.hasChallenge)
                        ChallengeProgress(
                          completedDays: state.completedDays,
                          totalDays: state.totalDays,
                          challengeName: state.challengeName,
                          isActive: state.completedDays < state.totalDays,
                          startDate: state.startDate,
                          endDate: state.endDate,
                        )
                      else
                        const SizedBox.shrink(),
                      SizeConfig.verticalSpace(height: SizeConfig.spaceBetween),
                      // Challenge History button
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChallengeHistoryPage()),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.spaceBetween * 1.5,
                              vertical: SizeConfig.spaceBetween * 0.6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colorz.primary),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_rounded, size: 14, color: Colorz.primary),
                                SizeConfig.horizontalSpace(width: 4),
                                Text('Challenge History',
                                    style: AppTextStyles.medium.copyWith(
                                      color: Colorz.primary,
                                      fontSize: SizeConfig.smallFont,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizeConfig.verticalSpace(height: SizeConfig.spaceBetween*1.5),
                      // Show create widget when no challenge
                      if (!state.hasChallenge && !state.challengeLoading) ...[
                        const CreateChallangeWidget(),
                        SizeConfig.verticalSpace(height: SizeConfig.spaceBetween*1.5),
                        const FreeChallangeWidget(),
                        SizeConfig.verticalSpace(height: SizeConfig.spaceBetween*1.5),
                      ],

                      // Show "Start New Challenge" only when challenge is COMPLETED (days over)
                      if (state.hasChallenge && !state.challengeLoading &&
                          state.completedDays >= state.totalDays) ...[
                        InkWell(
                          onTap: () => NavigatorService.pushNamed(AppRoutes.setupChallengePage),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.spaceBetween * 1.5,
                              horizontal: SizeConfig.spaceBetween * 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colorz.primary, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded,
                                    color: Colorz.primary, size: 20),
                                SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween * 0.5),
                                Text(
                                  'Start New Challenge',
                                  style: AppTextStyles.semiBold.copyWith(
                                    color: Colorz.primary,
                                    fontSize: SizeConfig.mediumFont,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizeConfig.verticalSpace(height: SizeConfig.spaceBetween*1.5),
                      ],
                      Text(
                        "Your Rules Summary",
                        style: AppTextStyles.semiBold.copyWith(fontSize: SizeConfig.headerThreeFont,color: Colorz.textColor),
                      ),
                      Text(
                        "Quick view of today's limits",
                        style: AppTextStyles.medium.copyWith(fontSize: SizeConfig.mediumFont,color: Colorz.hintTextColor),
                      ),
                      SizeConfig.verticalSpace(height: SizeConfig.spaceBetween),
                      const RuleSummaryWidget(),
                      SizeConfig.verticalSpace(height: SizeConfig.spaceBetween*1.5),
                      Button(
                        text: 'Continue to Trading Terminal',
                        isOutlined: false,
                        isBig: true,
                        radius: 100,
                        gradient: Colorz.primaryButtonGradient,
                        onPressed: () {
                          context.read<DashBoardBloc>().add(const ChangeTabDashBoardEvent(1));
                        },
                      ),
                      SizeConfig.verticalSpace(height: SizeConfig.spaceBetween * 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
