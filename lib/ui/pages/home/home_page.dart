import 'package:flutter/widgets.dart';

import 'home_viewmodel.dart';

class HomePage extends StatefulWidget {
  final HomeViewmodel viewmodel;

  const HomePage({super.key, required this.viewmodel});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
