// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:inject/src/source/injected_type.dart';
import 'package:inject/src/source/lookup_key.dart';
import 'package:inject/src/source/symbol_path.dart';
import 'package:quiver/testing/equality.dart';
import 'package:test/test.dart';

final lookupKey1 = new LookupKey(new SymbolPath.global('1'));
final lookupKey2 = new LookupKey(new SymbolPath.global('2'));

void main() {
  group(LookupKey, () {
    test('serialization', () {
      final type = new InjectedType(lookupKey1, isProvider: true);

      final deserialized = deserialize(type);

      expect(deserialized, type);
    });

    test('equality', () {
      expect({
        'only lookupKey': [
          new InjectedType(lookupKey1),
          new InjectedType(lookupKey1)
        ],
        'different lookupKey': [
          new InjectedType(lookupKey2),
          new InjectedType(lookupKey2)
        ],
        'with isProvider': [
          new InjectedType(lookupKey1, isProvider: true),
          new InjectedType(lookupKey1, isProvider: true)
        ],
      }, areEqualityGroups);
    });
  });
}

InjectedType deserialize(InjectedType type) {
  final json = const JsonEncoder().convert(type);
  return new InjectedType.fromJson(const JsonDecoder().convert(json));
}
