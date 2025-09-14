import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'ai_service.dart';
import 'language_model.dart';

class ActionButtonData {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  ActionButtonData({required this.label, required this.icon, required this.onPressed});
}

class AnalysisCard extends StatefulWidget {
  final String title;
  final Map<String, String> analysisData;
  final VoidCallback onClose;
  final ActionButtonData? actionButton;

  const AnalysisCard({
    super.key,
    required this.title,
    required this.analysisData,
    required this.onClose,
    this.actionButton,
  });

  @override
  State<AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<AnalysisCard> {
  final AIService _aiService = AIService();
  late String _originalText;
  late String _detectedLanguageName;
  late String _currentTranslatedText;
  
  late Language _sourceLanguage;
  late Language _targetLanguage;
  bool _isTranslating = false;

  final FlutterTts _flutterTts = FlutterTts();

   @override
  void initState() {
    super.initState();
    _originalText = widget.analysisData['Original Text'] ?? widget.analysisData['Description'] ?? widget.analysisData['Product'] ?? '';
    _currentTranslatedText = widget.analysisData['Translation'] ?? '';
    _detectedLanguageName = widget.analysisData['Detected Language'] ?? 'English';

    _sourceLanguage = supportedLanguages.firstWhere((lang) => lang.name.toLowerCase() == _detectedLanguageName.toLowerCase(), orElse: () => supportedLanguages.first);
    _targetLanguage = supportedLanguages.firstWhere((lang) => lang.code == 'en', orElse: () => supportedLanguages.first);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text, String langCode) async {
    await _flutterTts.setLanguage(langCode);
    await _flutterTts.speak(text);
  }

  Future<void> _retranslateText(Language newTargetLanguage) async {
    setState(() {
      _isTranslating = true;
      _targetLanguage = newTargetLanguage;
    });

    final aiResult = await _aiService.translateText(
      _originalText,
      from: _detectedLanguageName,
      to: newTargetLanguage.name,
    );

    setState(() {
      _currentTranslatedText = aiResult.text ?? aiResult.errorMessage ?? 'Translation failed.';
      _isTranslating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF212121),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: widget.onClose),
                ],
              ),
              const Divider(color: Colors.grey),

              if (widget.title == 'Text Translation') ...[
                const SizedBox(height: 10),
                _buildLanguageSelector(),
                const SizedBox(height: 20),
                _buildTextCard(_sourceLanguage, _originalText, context),
                const SizedBox(height: 10),
                _isTranslating
                    ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
                    : _buildTextCard(_targetLanguage, _currentTranslatedText, context, isTranslated: true),
              ] else ...[
                const SizedBox(height: 20),
                ...widget.analysisData.entries.map((entry) {
                  return _buildTextCard(_sourceLanguage, entry.value, context);
                }),
              ],
              
              if (widget.actionButton != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      icon: Icon(widget.actionButton!.icon),
                      label: Text(widget.actionButton!.label),
                      onPressed: widget.actionButton!.onPressed,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Text(
                _detectedLanguageName,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
          ),
          Expanded(
            child: DropdownButton<Language>(
              value: _targetLanguage,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              dropdownColor: Colors.grey.shade800,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              onChanged: (Language? newLang) {
                if (newLang != null && newLang != _targetLanguage) {
                  _retranslateText(newLang);
                }
              },
              items: supportedLanguages.map<DropdownMenuItem<Language>>((Language lang) {
                return DropdownMenuItem<Language>(
                  value: lang,
                  child: Text(lang.name),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard(Language language, String text, BuildContext context, {bool isTranslated = false}) {
    return Card(
      color: Colors.grey.shade800,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(language.name.toUpperCase(),
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(text,
                      style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.grey, size: 22),
                      onPressed: () => _speak(text, language.code),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}