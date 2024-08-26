// import 'dart:js';

// import 'package:SGMCS/constants/app_constants.dart';
// import 'package:SGMCS/shared-preference-manager/preference-manager.dart';
// import 'package:SGMCS/views/screens/auth/login_user.dart';
// import 'package:flutter/material.dart';
// import 'package:material_dialogs/material_dialogs.dart';
// import 'package:material_dialogs/widgets/buttons/icon_button.dart';
// import 'package:material_dialogs/widgets/buttons/icon_outline_button.dart';

// class Popups extends StatefulWidget {
//   const Popups({super.key});

//   @override
//   State<Popups> createState() => _PopupsState();
// }

// class _PopupsState extends State<Popups> {
//   @override
//   Widget build(BuildContext context) {
//     return ;
//   }

  
// }

// normalEmergingShowDialogWithNoGif() {
//   return Dialogs.materialDialog(
//     msg: "Are you sure you want to logout?",
//     title: "Confirmation",
//     color: Colors.white,
//     context: context,
//     actions: [
//       IconsOutlineButton(
//         onPressed: () {
//           Navigator.pop(context);
//         },
//         text: 'Cancel',
//         iconData: Icons.cancel_outlined,
//         textStyle: TextStyle(color: Colors.grey),
//         iconColor: Colors.grey,
//       ),
//       IconsButton(
//         onPressed: () async {
//           Navigator.pop(context);
//           // Navigator.pop(context);
//           await storage.delete(key: 'deviceToken');

//           SharedPreferencesManager().clearPreferenceByKey(AppConstants.isLogin);
//           SharedPreferencesManager().clearPreferenceByKey(AppConstants.user);
//           // SharedPreferencesManager()
//           //     .clearPreferenceByKey(AppConstants.userAccount);
//           // ZegoUIKitPrebuiltCallInvitationService().uninit();

//           Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => const Login(),
//               ));
//         },
//         text: 'Logout',
//         iconData: Icons.delete,
//         color: Colors.red,
//         textStyle: TextStyle(color: Colors.white),
//         iconColor: Colors.white,
//       ),
//     ],
//   );
// }