import 'package:flutter/material.dart';
import 'package:card_loading/card_loading.dart';

class DefaultSkeleton extends StatelessWidget {
  const DefaultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const CardLoading(
      height: 20,
      borderRadius: BorderRadius.all(Radius.circular(10)),
      margin: EdgeInsets.only(bottom: 10),
    );
  }
}
