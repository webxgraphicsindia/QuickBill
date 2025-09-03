class Forgotresponse<T> {
  final bool success;
  final String message;
  final String? token;
  final T? data;

  Forgotresponse({
    required this.success,
    required this.message,
    this.token,
    this.data,
  });
}