import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'language_model.dart';
import 'ai_result.dart';
import 'api_keys.dart';

class AIService {
  final String _geminiApiKey = ApiKeys.gemini;
  final String _imaggaApiKey = ApiKeys.imaggaApi;
  final String _imaggaApiSecret = ApiKeys.imaggaApiSecret;

  final String _geminiModelName = 'gemini-1.5-flash-latest';

  Future<AIResult> analyzeImageWithGemini(String imagePath, String prompt) async {
    try {
      final model = GenerativeModel(model: _geminiModelName, apiKey: _geminiApiKey);
      final imageBytes = await File(imagePath).readAsBytes();
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
      ];
      final response = await model.generateContent(content);
      return AIResult(text: response.text);
    } on GenerativeAIException catch (e) {
      if (e.message.toLowerCase().contains('quota')) {
        return AIResult(isQuotaError: true, errorMessage: e.message);
      }
      return AIResult(errorMessage: 'Error from Gemini API: ${e.message}');
    } catch (e) {
      return AIResult(errorMessage: 'An unexpected error occurred: $e');
    }
  }

  Future<AIResult> analyzeImageWithBackup(String imagePath) async {
    final uri = Uri.parse('https://api.imagga.com/v2/tags');
    final credentials = base64Encode(utf8.encode('$_imaggaApiKey:$_imaggaApiSecret'));
    final headers = {'Authorization': 'Basic $credentials'};

    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..files.add(await http.MultipartFile.fromPath('image', imagePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['result'] != null && data['result']['tags'] != null) {
          final tags = (data['result']['tags'] as List).take(5).map((tag) => tag['tag']['en']).toList();
          if (tags.isNotEmpty) {
            return AIResult(text: 'Backup analysis: I see ${tags.join(', ')}.');
          }
        }
        return AIResult(errorMessage: 'Backup API could not identify the image.');
      } else {
        return AIResult(errorMessage: 'Error: Backup API failed with status ${response.statusCode}');
      }
    } catch (e) {
      return AIResult(errorMessage: 'Error: Exception with Backup API: $e');
    }
  }

  Future<AIResult> translateTextWithGemini(String text, {required String from, required String to}) async {
    try {
      final model = GenerativeModel(model: _geminiModelName, apiKey: _geminiApiKey);
      final prompt = "Strictly translate the following text from $from to $to. Do not add any extra words, explanations, or context. Text: '$text'";
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return AIResult(text: response.text?.trim());
    } on GenerativeAIException catch (e) {
      if (e.message.toLowerCase().contains('quota')) {
        return AIResult(isQuotaError: true, errorMessage: e.message);
      }
      return AIResult(errorMessage: 'Error from Gemini API: ${e.message}');
    } catch (e) {
      return AIResult(errorMessage: 'An unexpected error occurred: $e');
    }
  }

  Future<AIResult> translateTextWithBackup(String text, {required String from, required String to}) async {
    final sourceLangCode = supportedLanguages.firstWhere((lang) => lang.name.toLowerCase() == from.toLowerCase(), orElse: () => supportedLanguages.first).code;
    final targetLangCode = supportedLanguages.firstWhere((lang) => lang.name.toLowerCase() == to.toLowerCase(), orElse: () => supportedLanguages.first).code;
    
    final uri = Uri.parse('https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$sourceLangCode|$targetLangCode');
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseData'] != null && data['responseData']['translatedText'] != null) {
          return AIResult(text: data['responseData']['translatedText']);
        }
        return AIResult(errorMessage: 'Backup translation failed.');
      }
      return AIResult(errorMessage: 'Error: Backup translator failed with status ${response.statusCode}.');
    } catch (e) {
      return AIResult(errorMessage: 'Error: Exception with backup translator.');
    }
  }

  Future<AIResult> translateText(String text, {required String from, required String to}) async {
    final aiResult = await translateTextWithGemini(text, from: from, to: to);
    if (aiResult.isQuotaError || aiResult.text == null || aiResult.text!.isEmpty) {
            return await translateTextWithBackup(text, from: from, to: to);
    }
    return aiResult;
  }
}