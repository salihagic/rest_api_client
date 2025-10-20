import 'package:flutter/foundation.dart';

/// A model representing cached data along with its expiration time.
class CacheModel {
  final DateTime?
  expirationDateTime; // The expiration date and time of the cached data
  final dynamic value; // The cached value

  /// Determines if the cached value has expired.
  bool get isExpired => expirationDateTime?.isBefore(DateTime.now()) ?? true;

  /// Constructor for CacheModel.
  /// [expirationDateTime] is the time when the cached data expires,
  /// and [value] is the actual cached data.
  CacheModel({required this.expirationDateTime, required this.value});

  /// Converts the CacheModel instance to a map for easy serialization.
  /// The map can be used for storage or network transmission.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'expirationDateTime': expirationDateTime
          .toJson(), // Serializes the expirationDateTime to a string format
      'value': value, // Included cached value
    };
  }

  /// Factory constructor to create a CacheModel instance from a map.
  /// This function attempts to parse the map and create a CacheModel object.
  factory CacheModel.fromMap(dynamic data) {
    try {
      // Check if the data is a valid Map and contains the required fields
      if (data is Map<String, dynamic> &&
          (data['expirationDateTime'] != null || data['value'] != null)) {
        return CacheModel(
          expirationDateTime: dateTimeFromJson(
            data['expirationDateTime'],
          ), // Converts the expiration time from string to DateTime
          value: data['value'], // Retrieved cached value
        );
      }
    } catch (e) {
      debugPrint(e.toString()); // Log any errors during object creation
    }

    // Fallback to a default CacheModel if creation fails
    return CacheModel(
      expirationDateTime: null, // Defaulting to null if parsing fails
      value: data, // Store raw data as value if no valid structure was found
    );
  }

  @override
  String toString() =>
      'CacheModel(expirationDateTime: $expirationDateTime, value: $value)';
}

/// Extension on DateTime for converting to JSON format.
extension _DateTimeExtensions on DateTime? {
  /// Converts the DateTime object to a JSON-compatible string format.
  /// The format is a dot-separated string representing year, month, day, hour, minute, and second.
  String? toJson() {
    try {
      if (this == null) {
        return null; // Return null if the DateTime is null
      }

      // Format each component of the DateTime
      final years = _section(this?.year);
      final months = _section(this?.month);
      final days = _section(this?.day);
      final hours = _section(this?.hour);
      final minutes = _section(this?.minute);
      final seconds = _section(this?.second);

      // Combine components into a dot-separated string
      return '$years.$months.$days.$hours.$minutes.$seconds';
    } catch (e) {
      debugPrint(e.toString()); // Log any errors during JSON conversion
      return null; // Return null if an error occurs
    }
  }

  /// Helper function to format a section of the date as a two-digit string.
  /// It pads single-digit values with a leading zero.
  String _section(int? value) => (value ?? 0).toString().padLeft(2, '0');
}

/// Converts a dot-separated string to a DateTime object.
/// The expected format is "YYYY.MM.DD.HH.MM.SS".
DateTime? dateTimeFromJson(String? json) {
  try {
    final parts = (json ?? '').split('.'); // Split the string into components

    // Ensure the correct number of components are provided
    if (parts.length != 6) {
      return null; // Return null if the format is incorrect
    }

    // Parse each component to an integer
    final years = int.parse(parts[0]); // Parse year
    final months = int.parse(parts[1]); // Parse month
    final days = int.parse(parts[2]); // Parse day
    final hours = int.parse(parts[3]); // Parse hour
    final minutes = int.parse(parts[4]); // Parse minute
    final seconds = int.parse(parts[5]); // Parse second

    // Create and return a DateTime object
    return DateTime(years, months, days, hours, minutes, seconds);
  } catch (e) {
    debugPrint(e.toString()); // Log any errors during parsing
    return null; // Return null if an error occurs
  }
}
