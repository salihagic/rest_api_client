class CacheModel {
  final DateTime? expirationDateTime;
  final dynamic value;

  bool get isExpired {
    final isExpired = expirationDateTime?.isBefore(DateTime.now()) ?? false;

    return isExpired;
  }

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

  factory CacheModel.fromMap(Map<String, dynamic> map) {
    final expirationDateTime = map['expirationDateTime'] != null
        ? DateTime.parse(map['expirationDateTime'])
        : null;
    final value = map['value'];

    return CacheModel(
      expirationDateTime: expirationDateTime,
      value: value,
    );
  }

  @override
  String toString() =>
      'CacheModel(expirationDateTime: $expirationDateTime, value: $value)';
}

extension _DateTimeExtensions on DateTime? {
  String? toJson() => this != null
      ? '${this!.year}-${this!.month}-${this!.day}T${this!.hour.toString().padLeft(2, '0')}:${this!.minute.toString().padLeft(2, '0')}:${this!.second.toString().padLeft(2, '0')}'
      : null;
}
