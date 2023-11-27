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

  factory CacheModel.fromMap(dynamic data) {
    if (data is Map<String, dynamic> &&
        (data['expirationDateTime'] != null || data['value'] != null)) {
      return CacheModel(
        expirationDateTime: data['expirationDateTime'] != null
            ? DateTime.parse(data['expirationDateTime'])
            : null,
        value: data['value'],
      );
    } else {
      return CacheModel(
        expirationDateTime: null,
        value: data,
      );
    }
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
