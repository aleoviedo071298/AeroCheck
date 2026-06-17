class RegulatoryRepositoryException implements Exception {
  const RegulatoryRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'RegulatoryRepositoryException: $message';
    }
    return 'RegulatoryRepositoryException: $message ($cause)';
  }
}
