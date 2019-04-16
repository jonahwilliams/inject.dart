// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:inject/src/build/summary_builder.dart';
import 'package:inject/src/summary.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Checks that the output of the generated .inject.summary file is expected.
void main() {
  group('$InjectSummaryBuilder', () {
    Map goldenFileJson;
    Map generatedFileJson;

    setUpAll(() async {
      var packageUri = await Isolate
          .resolvePackageUri(Uri.parse('package:inject/inject.dart'));
      var pathSegments = path.split(packageUri.path);
      var scriptPath =
          path.joinAll(pathSegments.sublist(0, pathSegments.length - 2));
      var goldenFile = new File(
          path.join(scriptPath, 'test', 'build', 'coffee_summary_test.golden'));
      var generatedFile = new File(path.normalize(path.join(scriptPath,
          'example', 'coffee', 'lib', 'coffee_app.inject.summary')));

      var goldenFileData = await goldenFile.readAsString();
      var generatedFileData = await generatedFile.readAsString();
      goldenFileJson = jsonDecode(goldenFileData);
      generatedFileJson = jsonDecode(generatedFileData);
    });

    test('should output coffee_app.inject.summary as expected', () {
      expect(goldenFileJson, isNotNull);
      expect(generatedFileJson, equals(goldenFileJson));
    });

    test('should serialize and deserialize as expected', () {
      var parsedSummary = LibrarySummary.parseJson(goldenFileJson);
      expect(jsonDecode(jsonEncode(parsedSummary)), goldenFileJson);
    });
  });
}
