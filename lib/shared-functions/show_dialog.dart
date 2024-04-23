// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:material_dialogs/dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:material_dialogs/widgets/buttons/icon_outline_button.dart';

class ShowDialog {
  final BuildContext ctx;
  ShowDialog({required this.ctx});

  normalEmergingShowDialogWithNoGif(String message, String title) {
    return Dialogs.materialDialog(
      msg: message,
      title: title,
      color: Colors.white,
      context: ctx,
      actions: [
        IconsOutlineButton(
          onPressed: () {},
          text: 'Cancel',
          iconData: Icons.cancel_outlined,
          textStyle: TextStyle(color: Colors.grey),
          iconColor: Colors.grey,
        ),
        IconsButton(
          onPressed: () {},
          text: 'Delete',
          iconData: Icons.delete,
          color: Colors.red,
          textStyle: TextStyle(color: Colors.white),
          iconColor: Colors.white,
        ),
      ],
    );
  }

  bottomEmergingShowDialogWithNoGif(String message, String title) {
    return Dialogs.bottomMaterialDialog(
      msg: message,
      title: title,
      context: ctx,
      actions: [
        IconsOutlineButton(
          onPressed: () {},
          text: 'Cancel',
          iconData: Icons.cancel_outlined,
          textStyle: TextStyle(color: Colors.grey),
          iconColor: Colors.grey,
        ),
        IconsButton(
          onPressed: () {},
          text: 'Delete',
          iconData: Icons.delete,
          color: Colors.red,
          textStyle: TextStyle(color: Colors.white),
          iconColor: Colors.white,
        ),
      ],
    );
  }

  normalEmergingShowDialogWithGif(String message, String title, String gifUrl) {
    return Dialogs.materialDialog(
      color: Colors.white,
      msg: message,
      title: title,
      lottieBuilder: Lottie.asset(
        gifUrl,
        fit: BoxFit.contain,
      ),
      context: ctx,
      actions: [
        IconsButton(
          onPressed: () {},
          text: 'Claim',
          iconData: Icons.done,
          color: Colors.blue,
          textStyle: TextStyle(color: Colors.white),
          iconColor: Colors.white,
        ),
      ],
    );
  }

  bottomEmergingShowDialogWithGif(String message, String title, String gifUrl) {
    return Dialogs.bottomMaterialDialog(
      msg: message,
      title: title,
      context: ctx,
      lottieBuilder: Lottie.asset(
        gifUrl,
        fit: BoxFit.contain,
      ),
      actions: [
        IconsOutlineButton(
          onPressed: () {},
          text: 'Cancel',
          iconData: Icons.cancel_outlined,
          textStyle: TextStyle(color: Colors.grey),
          iconColor: Colors.grey,
        ),
        IconsButton(
          onPressed: () {},
          text: 'Delete',
          iconData: Icons.delete,
          color: Colors.red,
          textStyle: TextStyle(color: Colors.white),
          iconColor: Colors.white,
        ),
      ],
    );
  }
}
