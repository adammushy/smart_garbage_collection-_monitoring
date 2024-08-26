import 'dart:math';

import 'package:SGMCS/constants/app_constants.dart';
import 'package:SGMCS/providers/data-provider.dart';
import 'package:SGMCS/providers/user-provider.dart';
import 'package:SGMCS/shared-preference-manager/preference-manager.dart';
import 'package:SGMCS/views/screens/admin/allusers.dart';
import 'package:SGMCS/views/screens/admin/dashboardcomponent.dart';
import 'package:SGMCS/views/screens/auth/login_user.dart';
import 'package:SGMCS/views/screens/forms/driversreportlist.dart';
import 'package:fan_side_drawer/fan_side_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final dash = DashboardController();

  @override
  void initState() {
    super.initState();
    Provider.of<UserManagementProvider>(context, listen: false).fetchAllUsers();
    Provider.of<DataManagementProvider>(context, listen: false).getAllReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel"),
      ),
      drawer: Drawer(
        width: 255,
        child: FanSideDrawer(
          menuItems: [
            // DrawerMenuItem(
            //   title: "Breakdown Report",
            //   onMenuTapped: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => BreakDownForm(),
            //       ),
            //     );
            //   },
            // ),

            DrawerMenuItem(
              title: "All users",
              icon: Icons.list,
              onMenuTapped: () {
                Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllUsersScreen(),
              ),
            );
              },
            ),
            DrawerMenuItem(
              title: "Log Out",
              icon: Icons.logout,
              onMenuTapped: () {
                SharedPreferencesManager()
                    .clearPreferenceByKey(AppConstants.isLogin);
                SharedPreferencesManager()
                    .clearPreferenceByKey(AppConstants.user);
                // SharedPreferencesManager()
                //     .clearPreferenceByKey(AppConstants.userAccount);
                // ZegoUIKitPrebuiltCallInvitationService().uninit();
                Navigator.pop(context);

                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Login(),
                    ));
              },
            )
          ],
        ),
      ),
      body: SafeArea(
        child: Consumer2<UserManagementProvider, DataManagementProvider>(
          builder: (context, userProvider, dataProvider, child) {
            // Ensure data is loaded
            if (userProvider.allUsers == null ||
                dataProvider.allReportList == null) {
              return Center(child: CircularProgressIndicator());
            }
            // if (userProvider.isFetching || dataProvider.isFetching) {
            //   return Center(child: CircularProgressIndicator());
            // }

            // if (userProvider.allUsers == null ||
            //     dataProvider.allReportList == null) {
            //   return Center(child: Text('Failed to load data'));
            // }

            return GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 15),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2 / 1.6,
              ),
              itemCount: dash.dashboardList.length,
              shrinkWrap: true,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return StatsCardTile(data: dash, index: index);
              },
            );
          },
        ),
      ),
    );
  }
}
