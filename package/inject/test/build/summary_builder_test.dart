// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:inject/src/source/injected_type.dart';
import 'package:inject/src/source/lookup_key.dart';
import 'package:inject/src/source/symbol_path.dart';
import 'package:inject/src/summary.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:third_party.dart.inject.testing/utils.dart';

void main() {
  group('InjectSummaryBuilder', () {
    test('should log info message when library does not declare injectables',
        () async {
      var tb = new SummaryTestBed(pkg: 'a', inputs: {'a|lib/empty.dart': ''});
      await tb.run();

      tb.expectLogRecord(
        Level.INFO,
        'no @module, @injector or @provide annotated classes found in library.',
      );

      // An empty summary should still be generated.
      expect(tb.summaries, contains('a|lib/empty.inject.summary'));
      LibrarySummary summary = tb.summaries['a|lib/empty.inject.summary'];
      expect(summary.injectors, isEmpty);
      expect(summary.modules, isEmpty);
    });

    testShouldLogSevere(
      'when unable to resolve annotation value',
      buggyCode: '''
        // package:inject import intentionally missing to cause @Module()
        // eval fail.
        @module class TestModule {}
      ''',
      expectedSevereMessage: 'a|lib/buggy_code.dart at 3:9: While looking for '
          'annotation package:inject/src/api/annotations.dart#Module on '
          '"class TestModule", failed to resolve annotation value.',
    );

    testShouldWarn(
      'when module does not declare providers',
      buggyCode: '''
        import 'package:inject/inject.dart';

        @module
        class TestModule {}
      ''',
      expectedWarning:
          'at 3:9: module class must declare at least one provider:\n\n'
          '@module class TestModule {}',
    );

    testShouldLogSevere(
      'when injector does not declare providers',
      buggyCode: '''
        import 'package:inject/inject.dart';
        import 'injector_missing_modules.inject.dart' as g;

        class Foo {}

        @module
        class TestModule {
          @provide Foo foo() => null;
        }

        @Injector(const [TestModule])
        class TestInjector {}
      ''',
      expectedSevereMessage:
          'at 11:9: injector class must declare at least one provider:\n\n'
          '@Injector(const [TestModule]) class TestInjector {}',
    );

    test('should generate @provide summaries on injectables', () async {
      var tb = new SummaryTestBed(pkg: 'a', inputs: {
        'a|lib/injectable_class.dart': '''
import 'package:inject/inject.dart';

class Foo {
  @provide
  Foo(String dep) {}
}

class WithNamedConstructor {
  WithNamedConstructor();

  @provide
  WithNamedConstructor.foo();
}

class WithNamedFactory {
  WithNamedFactory();

  @provide
  factory WithNamedFactory.foo() => new WithNamedFactory();
}

@provide
class WithDefaultConstructor {}
''',
      });
      await tb.run();

      expect(tb.summaries, hasLength(1));

      var injectables =
          tb.summaries['a|lib/injectable_class.inject.summary'].injectables;

      InjectableSummary fooSummary = injectables[0];
      expect(fooSummary.clazz,
          new SymbolPath('a', 'lib/injectable_class.dart', 'Foo'));
      expect(fooSummary.constructor.dependencies, [
        new InjectedType(
            new LookupKey(new SymbolPath.dartSdk('core', 'String'))),
      ]);

      InjectableSummary namedConstructorSummary = injectables[1];
      expect(
          namedConstructorSummary.clazz,
          new SymbolPath(
              'a', 'lib/injectable_class.dart', 'WithNamedConstructor'));
      expect(namedConstructorSummary.constructor.name, 'foo');

      InjectableSummary namedFactorySummary = injectables[2];
      expect(namedFactorySummary.clazz,
          new SymbolPath('a', 'lib/injectable_class.dart', 'WithNamedFactory'));
      expect(namedFactorySummary.constructor.name, 'foo');

      InjectableSummary defaultConstructorSummary = injectables[3];
      expect(
          defaultConstructorSummary.clazz,
          new SymbolPath(
              'a', 'lib/injectable_class.dart', 'WithDefaultConstructor'));
      expect(defaultConstructorSummary.constructor.name, '');
    });

    testShouldLogSevere(
      'when both class and constructors are annotated with @provide',
      buggyCode: '''
        import 'package:inject/inject.dart';

        @provide
        class ClassAndConstructor {
          @provide
          ClassAndConstructor();
        }
      ''',
      expectedSevereMessage:
          'has @provide annotation on both the class and on one of the '
          'constructors or factories. Please annotate one or the other, '
          'but not both.',
    );

    testShouldLogSevere(
      'when annotated class contains more than one constructor',
      buggyCode: '''
        import 'package:inject/inject.dart';

        @provide
        class TooManyConstructors {
          TooManyConstructors();
          TooManyConstructors.foo();
        }
      ''',
      expectedSevereMessage:
          'has more than one constructor. Please annotate one '
          'of the constructors instead of the class.',
    );

    testShouldLogSevere(
      'when more than one constructor is annotated with @provide',
      buggyCode: '''
        import 'package:inject/inject.dart';

        class TooManyAnnotatedConstructors {
          @provide
          TooManyAnnotatedConstructors();

          @provide
          TooManyAnnotatedConstructors.foo();
        }
      ''',
      expectedSevereMessage:
          'no more than one constructor may be annotated with '
          '@provide.',
    );

    testShouldLogSevere(
      'when constructor has named parameter',
      buggyCode: '''
        import 'package:inject/inject.dart';

        @provide
        class Foo {}

        class IHaveANamedParameterInMyConstructor {
          @provide
          IHaveANamedParameterInMyConstructor({Foo foo});
        }
      ''',
      expectedSevereMessage: 'named constructor parameters are unsupported',
    );

    void expectTooManyTypes(
        SummaryTestBed tb, String clazz, List<String> types) {
      tb.expectLogRecord(
          Level.SEVERE,
          'A class may be an injectable, a module or an injector, '
          'but not more than one of these types. However class '
          '${clazz} was found to be ${types.join(' and ')}:');
    }

    test(
        'should log severe message when classes are annotated '
        'for multiple types', () async {
      var tb = new SummaryTestBed(pkg: 'a', inputs: {
        'a|lib/too_many_types.dart': '''
import 'package:inject/inject.dart';

@module
class InjectableModule {
  @provide
  InjectableModule();
}

@injector
@module
class ModuleInjector {
  ModuleInjector();
}

@injector
class InjectableInjector {
  @provide
  InjectableInjector();
}

@injector
@module
class InjectableModuleInjector {
  @provide
  InjectableModuleInjector();
}
''',
      });
      await tb.run();

      expectTooManyTypes(tb, 'InjectableModule', ['injectable', 'module']);
      expectTooManyTypes(tb, 'ModuleInjector', ['module', 'injector']);
      expectTooManyTypes(tb, 'InjectableInjector', ['injectable', 'injector']);
      expectTooManyTypes(
          tb, 'InjectableModuleInjector', ['injectable', 'module', 'injector']);
    });

    test('should log severe message when provider return type is dynamic',
        () async {
      var tb = new SummaryTestBed(pkg: 'a', inputs: {
        'a|lib/dynamic_provider.dart': '''
import 'package:inject/inject.dart';

class Foo {}

@module
class TestModule {
  @provide dynamic foo() => null;
}
''',
      });
      await tb.run();

      tb.expectLogRecord(
        Level.SEVERE,
        'provider return type resolved to dynamic',
      );
    });

    // The subtle difference from the previous test is that here the code
    // seemingly intends to have a concrete type on the provider, but due to a
    // botched import or a typo ends up resolving to `dynamic` (that's how
    // Dart's optional type semantics work). This test won't be necessary when
    // Dart is 100% strongly typed.
    testShouldLogSevere(
      'when provider return type resolves to dynamic',
      buggyCode: '''
        import 'package:inject/inject.dart';

        class Foo {}

        @module
        class TestModule {
          // The analyzer resolves missing types to `dynamic`.
          @provide NonExistentType foo() => null;
        }
      ''',
      expectedSevereMessage: 'provider return type resolved to dynamic',
    );

    testShouldLogSevere(
      'when async provider return type resolves to dynamic',
      buggyCode: '''
        import 'dart:async';
        import 'package:inject/inject.dart';

        class Foo {}

        @module
        class TestModule {
          // The analyzer resolves missing types to `dynamic`.
          @asynchronous @provide Future<NonExistentType> foo() => null;
        }
      ''',
      expectedSevereMessage: 'provider return type resolved to dynamic',
    );

    test(
        'should log severe message when qualified provider '
        'return type is dynamic', () async {
      var tb = new SummaryTestBed(pkg: 'a', inputs: {
        'a|lib/dynamic_provider_with_qualifier.dart': '''
import 'package:inject/inject.dart';

const qualifier = const Qualifier(#qualifier);

class Foo {}

@module
class TestModule {
  @provide
  @qualifier
  dynamic foo() => null;
}
''',
      });
      await tb.run();

      tb.expectLogRecord(
        Level.SEVERE,
        'provider return type resolved to dynamic',
      );
    });

    test('should log severe message when provider has named parameter',
        () async {
      var tb = new SummaryTestBed(pkg: 'a', inputs: {
        'a|lib/provider_with_named_parameter.dart': '''
import 'package:inject/inject.dart';

@provide
class Foo {
  final number = 123;
}

@module
class TestModule {
  @provide
  int foo({Foo foo}) => foo.number;
}
''',
      });
      await tb.run();

      tb.expectLogRecord(
        Level.SEVERE,
        'named provider parameters are unsupported',
      );
    });

    test('should recognize asynchronous providers', () async {
      var tb = new SummaryTestBed(pkg: 'a', inputs: {
        'a|lib/async_provider.dart': '''
import 'dart:async';
import 'package:inject/inject.dart';

class Foo {}

@module
class TestModule {
  @provide @asynchronous
  Future<Foo> provideFoo() => null;
}
''',
      });
      await tb.run();

      ProviderSummary summary = tb
          .summaries['a|lib/async_provider.inject.summary']
          .modules
          .single
          .providers
          .single;

      expect(summary.name, 'provideFoo');
      expect(summary.kind, ProviderKind.method);
      expect(
          summary.injectedType,
          new InjectedType(
              new LookupKey(
                  new SymbolPath('a', 'lib/async_provider.dart', 'Foo')),
              isProvider: false));
      expect(summary.isSingleton, isFalse);
      expect(summary.isAsynchronous, isTrue);
      expect(summary.dependencies, isEmpty);
    });

    test('should recognize @Qualifier', () async {
      var tb = new SummaryTestBed(pkg: 'a', inputs: {
        'a|lib/has_qualifier.dart': r'''
          import 'package:inject/inject.dart';

          const baseUri = const Qualifier(#baseUriSymbol);

          @module
          class TestModule {
            @provide
            @baseUri
            String provideBaseUri() => '/api';
          }

          class Fetcher {
            @provide
            Fetcher(@baseUri String uri);
          }
        ''',
      });

      await tb.run();

      final summary = tb.summaries['a|lib/has_qualifier.inject.summary'];
      final modProvider = summary.modules.single.providers.single;
      final expectedKey = new LookupKey(
          new SymbolPath.dartSdk('core', 'String'),
          qualifier: const SymbolPath.global('baseUriSymbol'));
      expect(modProvider.injectedType, new InjectedType(expectedKey));
      final injectable = summary.injectables.single;
      expect(
        injectable.constructor.dependencies.first,
        new InjectedType(expectedKey),
      );
    });

    testShouldLogSevere(
      'when @asynchronous provider does not return Future',
      buggyCode: '''
        import 'package:inject/inject.dart';

        class Foo {}

        @module
        class TestModule {
          @provide @asynchronous
          Foo provideFoo() => null;
        }
      ''',
      expectedSevereMessage: 'asynchronous provider must return a Future',
    );

    testShouldLogSevere(
      'when @asynchronous is used on an injectable',
      buggyCode: '''
        import 'package:inject/inject.dart';

        @provide @asynchronous
        class Foo {}
      ''',
      expectedSevereMessage:
          'Classes and constructors cannot be annotated with '
          '@Asynchronous().',
    );

    testShouldLogSevere(
      'when @asynchronous is used on an injector',
      buggyCode: '''
        import 'dart:async';
        import 'package:inject/inject.dart';

        @provide
        class Foo {}

        @Injector()
        abstract class TestInjector {
          @provide @asynchronous
          Future<Foo> foo();
        }
      ''',
      expectedSevereMessage:
          'injector class must not declare asynchronous providers',
    );

    testShouldLogSevere(
      'when module providers are declared as getters',
      buggyCode: '''
        import 'package:inject/inject.dart';

        class Foo {}

        @module
        class TestModule {
          @provide
          Foo get foo => null;
        }
      ''',
      expectedSevereMessage: 'module class must not declare providers as '
          'getters, but only as methods',
    );

    test('should log about skipped part files', () async {
      var tb = new SummaryTestBed(pkg: 'a', inputs: {
        'a|lib/part_file.dart': 'part of foo;',
      });
      await tb.run();

      tb.expectLogRecord(
        Level.INFO,
        'Skipping a|lib/part_file.dart because it is a part file.',
      );
    });

    test('fails to build when trying to provide a Provider in a module',
        () async {
      final tb = new SummaryTestBed(pkg: 'a', inputs: {
        'a|lib/has_generic_typedef.dart': r'''
        import 'package:inject/inject.dart';

        typedef T Provider<T>();

        @module
        class FooModule {
          @provide
          Provider<int> provideProvider() => () => 123;
        }
        '''
      });

      await tb.run();

      tb.expectLogRecord(
          Level.SEVERE,
          'Modules are not allowed to provide a function type () -> Type. '
          'The inject library prohibits this to avoid confusion '
          'with injecting providers of injectable types. '
          'Your provider method will not be used.');
    });

    testShouldLogSevere(
      'when injector contains concrete methods',
      buggyCode: '''
        import 'package:inject/inject.dart';

        @Injector()
        abstract class TestInjector {
          @provide int foo() => 42;
        }
      ''',
      expectedSevereMessage:
          'at 5:11: providers declared on injector class must be abstract.',
    );

    testShouldLogSevere(
      'when injector method contains parameters',
      buggyCode: '''
        import 'package:inject/inject.dart';

        @provide
        class Foo {}

        @Injector()
        abstract class TestInjector {
          @provide Foo foo(int x);
        }
      ''',
      expectedSevereMessage: 'at 8:28: injector methods cannot have parameters',
    );

    testShouldLogSevere(
      'when we fail to resolve constructor dependency type',
      buggyCode: '''
        import 'package:inject/inject.dart';

        class Foo {
          @provide Foo(dynamic bar);
        }
      ''',
      expectedSevereMessage:
          'at 4:24: a constructor argument type resolved to dynamic.',
    );

    testShouldLogSevere(
      'when provider method dependency type is dynamic',
      buggyCode: '''
        import 'package:inject/inject.dart';

        @module
        class FooModule {
          @provide
          int provideSomething(dynamic bar) => 123;
        }
      ''',
      expectedSevereMessage:
          'at 5:11: Parameter named `bar` resolved to dynamic. '
          'This can happen when the return type is not specified',
    );

    testShouldLogSevere(
      'when we fail to resolve module provider method dependency type',
      buggyCode: '''
        import 'package:inject/inject.dart';

        @module
        class FooModule {
          @provide
          int provideSomething(Bar bar) => 123;
        }
      ''',
      expectedSevereMessage:
          'at 5:11: Parameter named `bar` resolved to dynamic. '
          'This can happen when the return type is not specified',
    );
  });
}
