import 'package:flutter/foundation.dart';

class CacheModel {
  final DateTime? expirationDateTime;
  final dynamic value;

  bool get isExpired => expirationDateTime?.isBefore(DateTime.now()) ?? true;

  CacheModel({
    required this.expirationDateTime,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'expirationDateTime': expirationDateTime.toJson(),
      'value': value,
    };
  }

  factory CacheModel.fromMap(dynamic data) {
    try {
      if (data is Map<String, dynamic> &&
          (data['expirationDateTime'] != null || data['value'] != null)) {
        return CacheModel(
          expirationDateTime: dateTimeFromJson(data['expirationDateTime']),
          value: data['value'],
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    return CacheModel(
      expirationDateTime: null,
      value: data,
    );
  }

  @override
  String toString() =>
      'CacheModel(expirationDateTime: $expirationDateTime, value: $value)';
}

extension _DateTimeExtensions on DateTime? {
  String? toJson() {
    try {
      if (this == null) {
        return null;
      }

      final years = _section(this?.year);
      final months = _section(this?.month);
      final days = _section(this?.day);
      final hours = _section(this?.hour);
      final minutes = _section(this?.minute);
      final seconds = _section(this?.second);

      return '$years.$months.$days.$hours.$minutes.$seconds';
    } catch (e) {
      debugPrint(e.toString());

      return null;
    }
  }

  String _section(int? value) => (value ?? 0).toString().padLeft(2, '0');
}

DateTime? dateTimeFromJson(String? json) {
  try {
    final parts = (json ?? '').split('.');

    if (parts.length != 6) {
      return null;
    }

    final years = int.parse(parts[0]);
    final months = int.parse(parts[1]);
    final days = int.parse(parts[2]);
    final hours = int.parse(parts[3]);
    final minutes = int.parse(parts[4]);
    final seconds = int.parse(parts[5]);

    return DateTime(
      years,
      months,
      days,
      hours,
      minutes,
      seconds,
    );
  } catch (e) {
    debugPrint(e.toString());

    return null;
  }
}
