import 'dart:convert';

import 'package:dio/dio.dart';

const _defaultFallbackError = 'Something went wrong. Please try again.';

/// Attempts to extract a user-friendly error string from Dio responses,
/// JSON payloads, or standard Dart exceptions.
String friendlyErrorMessage(
  Object error, {
  String fallback = _defaultFallbackError,
}) {
  if (error is DioException) {
    final payloadMessage = _messageFromPayload(error.response?.data);
    if (payloadMessage != null && payloadMessage.isNotEmpty) {
      return payloadMessage;
    }
    final dioMessage = error.message?.trim();
    if (dioMessage != null && dioMessage.isNotEmpty) {
      return dioMessage;
    }
    return fallback;
  }

  final derived = _messageFromPayload(error);
  if (derived != null && derived.isNotEmpty) {
    return derived;
  }
  return fallback;
}

String? _messageFromPayload(dynamic payload) {
  if (payload == null) return null;
  if (payload is String) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) return null;
    if (_looksLikeJson(trimmed)) {
      try {
        final decoded = jsonDecode(trimmed);
        return _messageFromPayload(decoded);
      } catch (_) {
        // Ignore decoding errors and fall back to the raw string.
      }
    }
    if (trimmed.startsWith('Exception:')) {
      return trimmed.substring('Exception:'.length).trim();
    }
    return trimmed;
  }

  if (payload is Map) {
    for (final key in const ['message', 'error', 'detail', 'description']) {
      if (payload.containsKey(key)) {
        final nested = _messageFromPayload(payload[key]);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
    }
    for (final value in payload.values) {
      final nested = _messageFromPayload(value);
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }
    return null;
  }

  if (payload is List) {
    for (final value in payload) {
      final nested = _messageFromPayload(value);
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }
    return null;
  }

  final stringValue = payload.toString().trim();
  if (stringValue.isEmpty) return null;
  if (_looksLikeJson(stringValue)) {
    try {
      final decoded = jsonDecode(stringValue);
      return _messageFromPayload(decoded);
    } catch (_) {
      // Ignore and return the string value instead.
    }
  }
  return stringValue;
}

bool _looksLikeJson(String input) {
  if (input.length < 2) return false;
  final startsWithBrace = input.startsWith('{') && input.endsWith('}');
  final startsWithBracket = input.startsWith('[') && input.endsWith(']');
  return startsWithBrace || startsWithBracket;
}
