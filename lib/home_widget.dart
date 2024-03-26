import 'package:flutter/material.dart';

class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      color: Theme.of(context).colorScheme.inversePrimary,
      height: 500,
      width: 500,
    ));
  }
}
