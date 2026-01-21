class StatusResult {
  final int status; // 1 = sucesso, 0 = erro
  final String message;

  StatusResult({
    required this.status,
    required this.message,
  });
}