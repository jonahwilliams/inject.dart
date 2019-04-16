// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:inject/src/build/codegen_builder.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Checks that the output of the generated .inject.dart file is expected.
void main() {
  group('$InjectCodegenBuilder', () {
    String golden;
    String generated;

    setUpAll(() async {
      var packageUri = await Isolate
          .resolvePackageUri(Uri.parse('package:inject/inject.dart'));
      var pathSegments = path.split(packageUri.path);
      var scriptPath =
          path.joinAll(pathSegments.sublist(0, pathSegments.length - 2));
      var goldenFile = new File(
          path.join(scriptPath, 'test', 'build', 'coffee_codegen_test.golden'));
      var generatedFile = new File(path.normalize(path.join(
          scriptPath, 'example', 'coffee', 'lib', 'coffee_app.inject.dart')));

      golden = await goldenFile.readAsString();
      generated = await generatedFile.readAsString();
    });

    test('should output coffee_app.inject.dart as expected', () {
      expect(golden, isNotNull);
      expect(generated, golden);
    });
  });
}
