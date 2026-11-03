import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets [tester.view] size/DPR and resets on tear-down (widget / golden tests).
void configureTestView(
  WidgetTester tester,
  Size physicalSize, {
  double devicePixelRatio = 1.0,
}) {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
}
