import 'package:translator/translator.dart';

/// Service for translating text using Google Translate API
class TranslationService {
  static final GoogleTranslator _translator = GoogleTranslator();

  /// Translate text from source language to target language
  static Future<String> translate(
    String text, {
    String from = 'en',
    String to = 'ar',
  }) async {
    try {
      final translation = await _translator.translate(text, from: from, to: to);
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text on error
    }
  }

  /// Translate multiple texts at once
  static Future<List<String>> translateBatch(
    List<String> texts, {
    String from = 'en',
    String to = 'ar',
  }) async {
    final results = <String>[];
    for (final text in texts) {
      final translated = await translate(text, from: from, to: to);
      results.add(translated);
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return results;
  }

  /// Get translation for a key-value map
  static Future<Map<String, String>> translateMap(
    Map<String, String> source, {
    String from = 'en',
    String to = 'ar',
  }) async {
    final result = <String, String>{};
    for (final entry in source.entries) {
      result[entry.key] = await translate(entry.value, from: from, to: to);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return result;
  }
}
