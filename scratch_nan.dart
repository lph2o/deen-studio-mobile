import 'package:flutter/material.dart';
// ignore_for_file: avoid_print
void main() {
  double w = double.nan;
  try {
    double x = w.clamp(16.0, double.infinity);
    print('clamp result: $x');
    var b = BoxConstraints.tightFor(width: x);
    print('b: $b');
  } catch (e) {
    print('error: $e');
  }
}
