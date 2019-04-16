// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:build/src/asset/exceptions.dart';
import 'package:build/src/asset/id.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:inject/src/context.dart';
import 'package:inject/src/graph.dart';
import 'package:inject/src/source/injected_type.dart';
import 'package:inject/src/source/lookup_key.dart';
import 'package:inject/src/source/symbol_path.dart';
import 'package:inject/src/summary.dart';
import 'package:logging/logging.dart';
import 'package:quiver/testing/equality.dart';
import 'package:test/test.dart';

final InjectedType foo = new InjectedType(
    new LookupKey(SymbolPath.parseAbsoluteUri('asset:foo/foo.dart', 'Foo')));
final InjectedType bar = new InjectedType(
    new LookupKey(SymbolPath.parseAbsoluteUri('asset:foo/foo.dart', 'Bar')));
final InjectedType baz = new InjectedType(
    new LookupKey(SymbolPath.parseAbsoluteUri('asset:foo/foo.dart', 'Baz')));
final map =
    new InjectedType(new LookupKey(new SymbolPath.dartSdk('core', 'Map')));

void main() {
  group('$InjectorGraphResolver', () {
    FakeSummaryReader reader;

    setUp(() {
      reader = new FakeSummaryReader({
        'foo/foo.inject.summary': new LibrarySummary(
          Uri.parse('asset:foo/foo.dart'),
          modules: [
            new ModuleSummary(
                SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#FooModule'), [
              new ProviderSummary(
                foo,
                'provideFoo',
                ProviderKind.method,
              ),
            ]),
            new ModuleSummary(
                SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#BarModule'), [
              new ProviderSummary(
                bar,
                'provideBar',
                ProviderKind.method,
                dependencies: [
                  new InjectedType(new LookupKey(SymbolPath.parseAbsoluteUri(
                      'asset:foo/foo.dart', 'Foo'))),
                ],
              ),
            ]),
            new ModuleSummary(
                SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#BazModule'), [
              new ProviderSummary(
                baz,
                'provideBaz',
                ProviderKind.method,
                dependencies: [map],
              ),
            ]),
            new ModuleSummary(
                SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#MapModule'), [
              new ProviderSummary(
                map,
                'provideMap',
                ProviderKind.method,
                dependencies: [],
              ),
            ]),
          ],
        )
      });
    });

    test('should correctly resolve an object graph', () async {
      final injectorSummary = new InjectorSummary(
        new SymbolPath('foo', 'foo.dart', 'BarInjector'),
        [
          SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#FooModule'),
          SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#BarModule'),
        ],
        [
          new ProviderSummary(
            bar,
            'getBar',
            ProviderKind.method,
          ),
        ],
      );
      var ctx = new _FakeBuilderContext();
      var resolvedGraph;
      await runZoned(
        () async {
          final resolver = new InjectorGraphResolver(reader, injectorSummary);
          resolvedGraph = await resolver.resolve();
        },
        zoneValues: {#builderContext: ctx},
      );
      expect(ctx.records.any((r) => r.level == Level.SEVERE), isFalse);
      expect(resolvedGraph.includeModules, hasLength(2));
      expect(resolvedGraph.providers, hasLength(1));
      final barProvider = resolvedGraph.providers.first;
      expect(barProvider.injectedType, bar);
      expect(barProvider.methodName, 'getBar');
      final isProvided = predicate((d) => (d is ResolvedDependency));
      expect(resolvedGraph.mergedDependencies, hasLength(2));
      expect(resolvedGraph.mergedDependencies.values, everyElement(isProvided));
    });

    test('should correctly resolve object graph containing dart:core objects',
        () async {
      final injectorSummary = new InjectorSummary(
        new SymbolPath('foo', 'foo.dart', 'BazInjector'),
        [
          SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#BazModule'),
          SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#MapModule')
        ],
        [new ProviderSummary(baz, 'getBaz', ProviderKind.method)],
      );
      var ctx = new _FakeBuilderContext();
      var resolvedGraph;
      await runZoned(
        () async {
          final resolver = new InjectorGraphResolver(reader, injectorSummary);
          resolvedGraph = await resolver.resolve();
        },
        zoneValues: {#builderContext: ctx},
      );
      expect(ctx.records.any((r) => r.level == Level.SEVERE), isFalse);
      expect(resolvedGraph.providers, hasLength(1));
      final fooProvider = resolvedGraph.providers.first;
      expect(fooProvider.methodName, 'getBaz');
      final isProvided = predicate((d) => (d is ResolvedDependency));
      expect(resolvedGraph.mergedDependencies, hasLength(2));
      expect(resolvedGraph.mergedDependencies.values, everyElement(isProvided));
    });

    test('should give useful error when graph fails to resolve', () async {
      final injectorSummary = new InjectorSummary(
        new SymbolPath('foo', 'foo.dart', 'BazInjector'),
        [SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#BazModule')],
        [new ProviderSummary(baz, 'getBaz', ProviderKind.method)],
      );
      var ctx = new _FakeBuilderContext();
      var resolvedGraph;
      await runZoned(
        () async {
          final resolver = new InjectorGraphResolver(reader, injectorSummary);
          resolvedGraph = await resolver.resolve();
        },
        zoneValues: {#builderContext: ctx},
      );
      expect(
          ctx.records.any((r) =>
              r.level == Level.SEVERE &&
              r.message.contains('Could not find a way to provide "Map" for '
                  'injector "BazInjector" which is injected in "BazModule"') &&
              r.message
                  .contains('Injector (BazInjector): asset:foo/foo.dart') &&
              r.message.contains('Injected class (Map): dart:core.') &&
              r.message.contains(
                  'Injected in class (BazModule): asset:foo/foo.dart.')),
          isTrue);

      expect(resolvedGraph.providers, hasLength(1));
      final fooProvider = resolvedGraph.providers.first;
      expect(fooProvider.methodName, 'getBaz');
      final isProvided = predicate((d) => (d is ResolvedDependency));
      expect(resolvedGraph.mergedDependencies, hasLength(1));
      expect(resolvedGraph.mergedDependencies.values, everyElement(isProvided));
    });

    test('should correctly resolve a qualifier in an object graph', () async {
      final qualifiedFoo = new InjectedType(new LookupKey(
          SymbolPath.parseAbsoluteUri('asset:foo/foo.dart', 'Foo'),
          qualifier: const SymbolPath.global('uniqueName')));
      var injectorSummary = new InjectorSummary(
        new SymbolPath('foo', 'foo.dart', 'FooInjector'),
        [
          SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#FooModule'),
        ],
        [
          new ProviderSummary(
            qualifiedFoo,
            'provideName',
            ProviderKind.method,
          ),
        ],
      );
      var resolver = new InjectorGraphResolver(reader, injectorSummary);
      var resolvedGraph = await resolver.resolve();

      expect(resolvedGraph.includeModules, hasLength(1));
      var fooModule = resolvedGraph.includeModules.first;
      expect(
        fooModule.toAbsoluteUri().toString(),
        'asset:foo/foo.dart#FooModule',
      );
      expect(resolvedGraph.providers, hasLength(1));

      var nameProvider = resolvedGraph.providers.first;
      expect(
        nameProvider.injectedType,
        qualifiedFoo,
      );
      expect(nameProvider.methodName, 'provideName');
    });

    test('should log a useful message when a summary is missing', () async {
      var ctx = new _FakeBuilderContext();
      await runZoned(
        () async {
          var injectorSummary = new InjectorSummary(
            new SymbolPath('foo', 'foo.dart', 'FooInjector'),
            [],
            [
              new ProviderSummary(
                new InjectedType(new LookupKey(
                    SymbolPath.parseAbsoluteUri('asset:foo/missing.dart#Foo'))),
                'getFoo',
                ProviderKind.method,
              )
            ],
          );
          var resolver = new InjectorGraphResolver(reader, injectorSummary);
          await resolver.resolve();
        },
        zoneValues: {#builderContext: ctx},
      );
      expect(
          ctx.records.any((r) =>
              r.level == Level.SEVERE &&
              r.message.contains('Could not find a way to provide "Foo" for '
                  'injector "FooInjector" '
                  'which is injected in "FooInjector"') &&
              r.message.contains('asset:foo/missing.dart') &&
              r.message.contains('asset:foo/foo.dart.')),
          isTrue);
    });
  });

  group('$Cycle', () {
    test('has order-independent hashCode and operator==', () {
      var sA = new LookupKey(new SymbolPath('package', 'path.dart', 'A'));
      var sB = new LookupKey(new SymbolPath('package', 'path.dart', 'B'));
      var sC = new LookupKey(new SymbolPath('package', 'path.dart', 'C'));
      var sD = new LookupKey(new SymbolPath('package', 'path.dart', 'D'));

      var cycle1 = new Cycle([sA, sB, sC, sA]);
      var cycle2 = new Cycle([sB, sC, sA, sB]);
      var cycle3 = new Cycle([sC, sA, sB, sC]);

      var diffNodes1 = new Cycle([sA, sB, sA]);
      var diffNodes2 = new Cycle([sA, sB, sC, sD, sA]);

      var diffEdges = new Cycle([sA, sC, sB, sA]);

      expect({
        'base': [cycle1, cycle2, cycle3],
        'different node': [diffNodes1],
        'another different node': [diffNodes2],
        'different edges': [diffEdges],
      }, areEqualityGroups);
    });
  });
}

class _FakeBuilderContext implements BuilderContext {
  final List<LogRecord> records = <LogRecord>[];

  @override
  final Logger rawLogger = new Logger("_FakeBuilderContextLogger");

  _FakeBuilderContext() {
    rawLogger.onRecord.listen(records.add);
    rawLogger.onRecord.listen(print);
  }

  @override
  BuildStep get buildStep => null;

  @override
  BuilderLogger get log => null;
}

/// An in-memory implementation of [SummaryReader].
///
/// When [read] is called, it returns the mock summary.
class FakeSummaryReader implements SummaryReader {
  final Map<String, LibrarySummary> _summaries;

  /// Create a fake summary reader with previously created summaries.
  ///
  /// __Example use:__
  ///     return new FakeSummary({
  ///       'foo/foo.dart': new LibrarySummary(...)
  ///     });
  FakeSummaryReader(this._summaries);

  @override
  Future<LibrarySummary> read(String package, String path) {
    if (package == "dart") {
      throw new InvalidInputException(new AssetId(package, path));
    }
    var fullPath = '$package/$path';
    var summary = _summaries[fullPath];
    if (summary == null) {
      throw new FileSystemException('File not found', fullPath);
    }
    return new Future<LibrarySummary>.value(summary);
  }
}
