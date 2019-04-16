import 'package:test/test.dart';

import 'package:third_party.dart.inject.example.train.bike/bike.dart';
import 'package:third_party.dart.inject.example.train.common/common.dart';
import 'package:third_party.dart.inject.example.train.food/food.dart';
import 'package:third_party.dart.inject.example.train.locomotive/locomotive.dart';

void main() {
  group('locomotive', () {
    test('can instantiate TrainServices', () async {
      final services = await TrainServices.create(
        new BikeServices(),
        new FoodServices(),
        new CommonServices(),
      );
      services.bikeRack;
      services.kitchen;
    });
  });
}
