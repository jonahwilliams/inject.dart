// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';

import 'codegen_test_bed.dart';

/// A map of test names to [CodegenTestBed]s.
///
/// Each entry represents a test case.
final testCasesByName = {
  'should generate injector': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'basic_injector.dart',
    },
    outputs: {'a|lib/module.inject.dart': 'basic_injector.golden'},
  ),
  'should generate factories for injectables': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'basic_injectable.dart',
    },
    outputs: {'a|lib/module.inject.dart': 'basic_injectable.golden'},
  ),
  'should statically log severe error and null out unresolved '
      'injector provider dependencies': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'unresolved_injector_provider_dependencies.dart',
    },
    outputs: {
      'a|lib/module.inject.dart':
          'unresolved_injector_provider_dependencies.golden'
    },
    testFunctions: [
      (testBed) => testBed.expectLogRecord(
          Level.SEVERE,
          'Could not find a way to provide "Foo" for injector '
          '"TestInjector" which is injected in "TestInjector".')
    ],
  ),
  'should statically log severe error and null out unresolved module provider '
      'dependencies': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'unresolved_module_provider_dependencies.dart',
    },
    outputs: {
      'a|lib/module.inject.dart':
          'unresolved_module_provider_dependencies.golden'
    },
    testFunctions: [
      (testBed) => testBed.expectLogRecord(
          Level.SEVERE,
          'Could not find a way to provide "FooImpl" for injector '
          '"TestInjector" which is injected in "TestModule".')
    ],
  ),
  'should statically log severe error and null out unresolved constructor '
      'dependencies': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'unresolved_constructor_dependencies.dart',
    },
    outputs: {
      'a|lib/module.inject.dart': 'unresolved_constructor_dependencies.golden'
    },
    testFunctions: [
      (testBed) => testBed.expectLogRecord(
          Level.SEVERE,
          'Could not find a way to provide "Bar" for injector '
          '"TestInjector" which is injected in "Foo".')
    ],
  ),
  'should generate injector with multiple files': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/foo.dart': 'multi_file_injector/foo.dart',
      'a|lib/module.dart': 'multi_file_injector/module.dart',
      'a|lib/injector.dart': 'multi_file_injector/injector.dart',
    },
    outputs: {
      'a|lib/injector.inject.dart': 'multi_file_injector/injector.inject.golden'
    },
  ),
  'should generate injector for singleton module providers': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'singleton_module_provider.dart',
    },
    outputs: {'a|lib/module.inject.dart': 'singleton_module_provider.golden'},
  ),
  'should generate factories for singleton injectables': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'singleton_injectable.dart',
    },
    outputs: {'a|lib/module.inject.dart': 'singleton_injectable.golden'},
  ),
  'should log severe message when singleton without provide':
      new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'singleton_without_provide.dart',
    },
    outputs: {'a|lib/module.inject.dart': 'singleton_without_provide.golden'},
    testFunctions: [
      (testBed) => testBed.expectLogRecord(
          Level.SEVERE,
          'A class cannot be annotated with `@singleton` '
          'without also being annotated `@provide`.')
    ],
  ),
  'should give module providers priority over injectables': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/foo.dart': 'prioritize_modules/foo.dart',
      'a|lib/modules_have_higher_precedence.dart':
          'prioritize_modules/modules_have_higher_precedence.dart',
    },
    outputs: {
      'a|lib/modules_have_higher_precedence.inject.dart':
          'prioritize_modules/modules_have_higher_precedence.inject.golden'
    },
  ),
  'supports module inheritance': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/foo.dart': 'module_inheritance/foo.dart',
      'a|lib/inherited_modules.dart':
          'module_inheritance/inherited_modules.dart',
    },
    outputs: {
      'a|lib/inherited_modules.inject.dart':
          'module_inheritance/inherited_modules.inject.golden'
    },
  ),
  'supports injector inheritance': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/foo.dart': 'injector_inheritance/foo.dart',
      'a|lib/inherited_injector_provider_methods.dart':
          'injector_inheritance/inherited_injector_provider_methods.dart',
    },
    outputs: {
      'a|lib/inherited_injector_provider_methods.inject.dart':
          'injector_inheritance/inherited_injector_provider_methods.inject.golden'
    },
  ),
  'supports getters as injector providers': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'getters_in_injector.dart',
    },
    outputs: {'a|lib/module.inject.dart': 'getters_in_injector.golden'},
  ),
  'injector @provide annotations are optional': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'injector_provide_annotation_optional.dart',
    },
    outputs: {
      'a|lib/module.inject.dart': 'injector_provide_annotation_optional.golden'
    },
  ),
  'should initialize asynchronous dependencies': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'asynchronous_dependencies_initialized.dart',
    },
    outputs: {
      'a|lib/module.inject.dart': 'asynchronous_dependencies_initialized.golden'
    },
  ),
  'should initialize asynchronous dependencies transitively':
      new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart':
          'asynchronous_dependencies_initialized_transitively.dart',
    },
    outputs: {
      'a|lib/module.inject.dart':
          'asynchronous_dependencies_initialized_transitively.golden'
    },
  ),
  'should warn about cyclic dependencies': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'cyclic_dependencies.dart',
    },
    outputs: {'a|lib/module.inject.dart': 'cyclic_dependencies.golden'},
    testFunctions: [
      (testBed) => testBed.expectLogRecord(
            Level.SEVERE,
            'Detected dependency cycle:\n'
                '  (Bar from lib/module.dart)\n'
                '  (Foo from lib/module.dart)\n'
                '  (Bar from lib/module.dart)',
          ),
      (testBed) => testBed.expectLogRecord(
            Level.SEVERE,
            'Detected dependency cycle:\n'
                '  (A from lib/module.dart)\n'
                '  (B from lib/module.dart)\n'
                '  (C from lib/module.dart)\n'
                '  (A from lib/module.dart)',
          ),
      (testBed) => testBed.expectLogRecord(
            Level.SEVERE,
            'Detected dependency cycle:\n'
                '  (Self from lib/module.dart)\n'
                '  (Self from lib/module.dart)',
          ),
      (testBed) =>
          // This ensures that we do not warn about the same cycle multiple
          // times.
          // Example, the following two cycles are actually the same cycle:
          //   Bar -> Foo -> Bar
          //   Foo -> Bar -> Foo
          testBed.expectLogRecordCount(
              Level.SEVERE, 'Detected dependency cycle', 3),
    ],
  ),
  'should not generate unused fields, initialization and creator methods':
      new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'unused_references_dropped.dart',
    },
    outputs: {'a|lib/module.inject.dart': 'unused_references_dropped.golden'},
  ),
  'should warn about unused modules': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'unused_module.dart',
    },
    outputs: {'a|lib/module.inject.dart': 'unused_module.golden'},
    testFunctions: [
      (testBed) => testBed.expectLogRecord(
            Level.WARNING,
            'Unused module in TestInjector: Unused',
          )
    ],
  ),
  'should support @provide @singleton @customQualifier': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'provide_singleton_and_qualifier.dart',
    },
    outputs: {
      'a|lib/module.inject.dart': 'provide_singleton_and_qualifier.golden'
    },
  ),
  'should support injecting providers': new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/module.dart': 'provider_injection.dart',
    },
    outputs: {'a|lib/module.inject.dart': 'provider_injection.golden'},
  ),
  'should support using a parent injector inherited class as a module':
      new CodegenTestBed(
    pkg: 'a',
    inputs: {
      'a|lib/injector.dart': 'inherited_injector_as_module.dart',
    },
    outputs: {
      'a|lib/injector.inject.dart': 'inherited_injector_as_module.golden'
    },
  ),
};
