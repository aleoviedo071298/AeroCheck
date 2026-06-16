class WeatherRepositoryException implements Exception {
  const WeatherRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'WeatherRepositoryException: $message';
    }
    return 'WeatherRepositoryException: $message ($cause)';
  }
}
