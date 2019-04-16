// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_test/build_test.dart';
import 'package:inject/src/build/codegen_builder.dart';
import 'package:inject/src/summary.dart';
import 'package:logging/logging.dart';
import 'package:quiver/check.dart';
import 'package:third_party.dart.inject.testing/utils.dart';

const _testFilesPath = 'third_party/dart/inject_generator/test_files/';

/// A test to run on on [CodegenTestBed].
typedef void CodegenTestFunction(CodegenTestBed testBed);

/// Makes testing test [InjectCodegenBuilder] convenient.
class CodegenTestBed {
  /// Test package being processed.
  final String pkg;

  /// Map of file names in test_files directory by virtual file names.
  final Map<String, String> inputs;

  /// Map of file names in test_files directory by virtual file names.
  final Map<String, String> outputs;

  /// List of [CodegenTestFunction]s to run against this instance in unit tests.
  final List<CodegenTestFunction> testFunctions;

  final _writer = new TestingAssetWriter();

  SummaryTestBed _summaryTestBed;

  /// Constructor.
  CodegenTestBed(
      {this.pkg, this.inputs, this.outputs, this.testFunctions = const []});

  /// Generated files keyed by file paths.
  Map<String, String> get genfiles => _writer.genfiles;

  /// Log records written by the builder.
  List<LogRecord> get logRecords => _summaryTestBed.logRecords;

  /// Runs [InjectSummaryBuilder] followed by [InjectCodegenBuilder] and records
  /// results.
  Future<Null> run() async {
    final readInputs = <String, String>{};
    for (final virtualFile in inputs.keys) {
      readInputs[virtualFile] = await _readTestFile(inputs[virtualFile]);
    }
    _summaryTestBed = new SummaryTestBed(pkg: pkg, inputs: readInputs);

    await _summaryTestBed.run();
    var inputSummaries = <String, String>{};
    _summaryTestBed.summaries.forEach((String path, LibrarySummary summary) {
      inputSummaries[path] = jsonEncode(summary.toJson());
    });
    var builder = new InjectCodegenBuilder(
      // Makes the testing prettier.
      useScoping: false,
    );
    await testBuilder(builder, inputSummaries,
        rootPackage: _summaryTestBed.pkg,
        isInput: (assetId) => assetId.startsWith(_summaryTestBed.pkg),
        onLog: _summaryTestBed.logRecords.add,
        writer: _writer);

    return null;
  }

  /// Writes each expected virtual file to the test_files directory.
  ///
  /// [run] must be called first.
  ///
  /// See [outputs].
  Future<Null> writeGoldens() async {
    checkState(_summaryTestBed != null, message: 'Call [run] first!');

    for (final virtualFile in outputs.keys) {
      final output = genfiles[virtualFile];
      checkState(output != null,
          message: 'Could not find expected output file $virtualFile!');

      await _writeTestFile(outputs[virtualFile], output);
    }
  }

  /// Returns the expected file contents by virtual file names.
  Future<Map<String, String>> expectedOutputs() async {
    final expectedOutputs = <String, String>{};
    for (final virtualFile in outputs.keys) {
      expectedOutputs[virtualFile] = await _readTestFile(outputs[virtualFile]);
    }
    return expectedOutputs;
  }

  /// Verifies that [logRecords] contains a message with the desired [level] and
  /// [message].
  void expectLogRecord(Level level, String message) {
    _summaryTestBed.expectLogRecord(level, message);
  }

  /// Verifies that [logRecords] contains a message with the desired [level] and
  /// [message].
  void expectLogRecordCount(Level level, String message, int expectedCount) {
    _summaryTestBed.expectLogRecordCount(level, message, expectedCount);
  }

  static Future<String> _readTestFile(String testFileName) {
    String runfiles = Platform.environment['RUNFILES'];
    String testFilePath = 'google3/$_testFilesPath$testFileName';
    return new File('$runfiles/$testFilePath').readAsString();
  }

  static Future<void> _writeTestFile(
      String testFileName, String contents) async {
    await new File('$_testFilesPath$testFileName').writeAsString(contents);
  }
}
