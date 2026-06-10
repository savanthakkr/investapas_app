import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investapas/presentation/pages/dashBoard/profile/profile_tab.dart';
import 'package:investapas/presentation/pages/dashBoard/trading_journal/trading_journal_tab.dart';
import 'package:investapas/presentation/pages/dashBoard/trading_terminal/trading_terminal_tab.dart';

import '../../../Widgets/app_background.dart';

import '../../bloc/dashboard/bloc.dart';
import '../../bloc/dashboard/state.dart';

import 'bottomNavigationBar.dart';
import 'home/home_tab.dart';
const double dashboardNavBarTotalHeight = 72;

class DashBoardPage extends StatelessWidget {
  const DashBoardPage({super.key});


  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: dashboardNavBarTotalHeight),
            child: BlocBuilder<DashBoardBloc, DashBoardState>(
              builder: (context, state) {
                return _body(state.pageIndex);
              },
            ),
          ),
        ),
        bottomNavigationBar: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: const DashBoardNavigationBar(),
        ),
      ),
    );
  }

  Widget _body(int index) {
    switch (index) {
      case 1:
        return const TradingTerminalTab();
      case 2:
        return const TradingJournalTab();
      case 3:
        return const ProfileTab();
      default:
        return const HomeTab();
    }
  }
}