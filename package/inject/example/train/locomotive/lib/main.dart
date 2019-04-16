import 'dart:async';

import 'package:third_party.dart.inject.example.train.bike/bike.dart';
import 'package:third_party.dart.inject.example.train.common/common.dart';
import 'package:third_party.dart.inject.example.train.food/food.dart';
import 'locomotive.dart';

Future<Null> main() async {
  final services = await TrainServices.create(
    new BikeServices(),
    new FoodServices(),
    new CommonServices(),
  );
  print(services.bikeRack.pleaseFix());
}
