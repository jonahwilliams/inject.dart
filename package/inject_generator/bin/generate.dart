// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:inject_generator/test_cases.dart';

/// This script generates and overwrites the golden files with the actual
/// generated sources.
///
/// This script runs for all test cases listed in [testCasesByName].
Future<Null> main() async {
  for (final name in testCasesByName.keys) {
    final testCase = testCasesByName[name];

    print('Generating for "$name"...');
    await testCase.run();

    print('Writing goldens...');
    await testCase.writeGoldens();

    print('Done.\n');
  }
}
