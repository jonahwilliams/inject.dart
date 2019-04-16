// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:inject/src/build/codegen_builder.dart';
import 'package:inject/src/build/summary_builder.dart';

import 'package:build/build.dart';

/// A [Builder] which produces an injection summary.
Builder summarize([_]) => const InjectSummaryBuilder();

/// A [Builder] which produces injection code.
Builder generate([_]) => const InjectCodegenBuilder();
