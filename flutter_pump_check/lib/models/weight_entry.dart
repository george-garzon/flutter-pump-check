import 'package:hive/hive.dart';

part '../../models/weight_entry.g.dart';

@HiveType(typeId: 0)
class WeightEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double weight;

  WeightEntry({required this.date, required this.weight});
}
