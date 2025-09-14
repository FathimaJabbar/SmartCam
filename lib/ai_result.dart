class AIResult {
  final String? text;
  final bool isQuotaError;
  final String? errorMessage;

  AIResult({this.text, this.isQuotaError = false, this.errorMessage});
}