import 'dart:math';

import 'package:SGMCS/providers/data-provider.dart';
import 'package:SGMCS/providers/user-provider.dart';
import 'package:SGMCS/views/screens/admin/allreports.dart';
import 'package:SGMCS/views/screens/admin/allusers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:google_fonts/google_fonts.dart';

class StatsCardTile extends StatefulWidget {
  final DashboardController? data;
  final int? index;
  const StatsCardTile({Key? key, this.index, this.data}) : super(key: key);

  @override
  _StatsCardTileState createState() => _StatsCardTileState();
}

class _StatsCardTileState extends State<StatsCardTile> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateAllUsersCount();
    updateAllPermitsCount();
  }

  void updateAllUsersCount() {
    final alluser =
        Provider.of<UserManagementProvider>(context, listen: true).allUsers;
    // final count = alluser.length.toString();
    final count = alluser != null ? alluser.length.toString() : '0';
    print("Userss :: $count");
    setState(() {
      widget.data?.dashboardList[2].value = count;
    });
  }

  void updateAllPermitsCount() {
    final allReports =
        Provider.of<DataManagementProvider>(context, listen: true)
            .allReportList;
    // final count = allreport.length.toString();
    final count = allReports != null ? allReports.length.toString() : '0';
    print("Permits :: $count");
    setState(() {
      widget.data?.dashboardList[0].value = count;
    });
  }

  final List<Color> colorList = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow
  ];

  /// Function to generate a random color from the list
  Color getRandomColor() {
    final random = Random();
    final randomIndex = random.nextInt(colorList.length);
    return colorList[randomIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5.0),
      child: GestureDetector(
        onTap: () {
          if (widget.index == 0) {
            // GoRouter.of(context).go("/home/profile/lawyers");
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AllReportScreen()));
          } else if (widget.index == 1) {
            // GoRouter.of(context).go("/home/profile/users");
          } else if (widget.index == 2) {
            // GoRouter.of(context).go("/home/profile/admins");

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllUsersScreen(),
              ),
            );
          } else if (widget.index == 3) {
            // GoRouter.of(context).go("/home/profile/allusers");
          }
        },
        child: Container(
          decoration: BoxDecoration(
            // color: Commons.dashColor[widget.index!],

            // color: getRandomColor(),
            color: Colors.green,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.data!.dashboardList[widget.index!].icon,
                  color: Colors.white,
                  size: 40,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextBuilder(
                      text: widget.data!.dashboardList[widget.index!].value!,
                      fontSize: 24.0,
                      color: Colors.white,
                    ),
                    TextBuilder(
                      text: widget.data!.dashboardList[widget.index!].title!,
                      textOverflow: TextOverflow.clip,
                      fontSize: 20.0,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardController {
  final dashboardList = [
    // DashboardModel(
    //   icon: Icons.verified,
    //   title: 'Lawyers',
    //   value: '0',
    // ),
    DashboardModel(
      icon: Icons.note,
      title: 'Reports',
      value: '0',
    ),
    DashboardModel(
      icon: Icons.receipt,
      // icon: Icons.groups_outlined,
      title: 'Complains',
      value: '0',
    ),
    DashboardModel(
      icon: Icons.groups_outlined,
      title: 'All users',
      value: '0',
    ),
  ];
}

class DashboardModel {
  final String? title;
  String? value; // Update to non-final

  final IconData? icon;

  DashboardModel({this.title, this.value, this.icon});
}

class TextBuilder extends StatefulWidget {
  final String? text;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final double? latterSpacing;
  final TextOverflow? textOverflow;
  final int? maxLines;
  final TextAlign? textAlign;
  final double? height;
  final double? wordSpacing;
  final TextDecoration? textDecoration;
  final FontStyle? fontStyle;
  const TextBuilder({
    Key? key,
    this.text,
    this.fontSize,
    this.color,
    this.textOverflow,
    this.fontWeight,
    this.latterSpacing,
    this.maxLines,
    this.textAlign,
    this.height,
    this.wordSpacing,
    this.textDecoration,
    this.fontStyle,
  }) : super(key: key);

  @override
  State<TextBuilder> createState() => _TextBuilderState();
}

class _TextBuilderState extends State<TextBuilder> {
  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text!,
      style: GoogleFonts.lato(
        fontSize: widget.fontSize,
        color: widget.color,
        fontWeight: widget.fontWeight,
        letterSpacing: widget.latterSpacing,
        height: widget.height,
        wordSpacing: widget.wordSpacing,
        decoration: widget.textDecoration,
        fontStyle: widget.fontStyle,
      ),
      maxLines: widget.maxLines,
      overflow: widget.textOverflow,
      textAlign: widget.textAlign,
    );
  }
}

class Commons {
  static const tileBackgroundColor = const Color(0xFFF1F1F1);
  static const chuckyJokeBackgroundColor = const Color(0xFFF1F1F1);
  static const chuckyJokeWaveBackgroundColor = const Color(0xFFA8184B);
  static const gradientBackgroundColorEnd = const Color(0xFF601A36);
  static const gradientBackgroundColorWhite = const Color(0xFFFFFFFF);
  static const mainAppFontColor = const Color(0xFF4D0F29);
  static const appBarBackGroundColor = const Color(0xFF4D0F28);
  static const categoriesBackGroundColor = const Color(0xFFA8184B);
  static const hintColor = const Color(0xFF4D0F29);
  static const mainAppColor = const Color(0xFF4D0F29);
  static const gradientBackgroundColorStart = const Color(0xFF4D0F29);
  static const popupItemBackColor = const Color(0xFFDADADB);
  static List<Color> dashColor = [
    Colors.blue,
    Colors.blue,
    Colors.blue,
    Colors.blue,
    Colors.blue,
    Colors.blue,
    Color(0xff1AB0B0),
    Color(0xff1AB0B0),
    Color(0xff1AB0B0),
    Color(0xff1AB0B0)
  ];

  static void showError(BuildContext context, String message) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: TextBuilder(text: message),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(15)),
              actions: <Widget>[
                TextButton(
                  child: TextBuilder(text: "Ok"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }
}
