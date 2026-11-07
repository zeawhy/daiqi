import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android launcher label is 带齐了 via @string/app_name', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:label="@string/app_name"'));
    expect(manifest, isNot(contains('android:label="daiqi"')));
    final strings = File('android/app/src/main/res/values/strings.xml').readAsStringSync();
    expect(strings, contains('<string name="app_name">带齐了</string>'));
  });
}
