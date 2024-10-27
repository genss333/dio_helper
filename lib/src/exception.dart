import 'package:dio/dio.dart';

class AppException {
  static String checkException(DioException e) {
    String errorDescription = '';
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        errorDescription = "Connection Timeout";
        break;
      case DioExceptionType.sendTimeout:
        errorDescription = "Send Timeout";
        break;
      case DioExceptionType.receiveTimeout:
        errorDescription = "Receive Timeout";
        break;
      case DioExceptionType.badResponse:
        errorDescription =
            "Received invalid status code: ${e.response?.statusCode}";
        break;
      case DioExceptionType.cancel:
        errorDescription = "Request to API server was cancelled";
        break;
      case DioExceptionType.unknown:
        errorDescription =
            "Connection to API server failed due to internet connection";
        break;
      case DioExceptionType.badCertificate:
        errorDescription = "Bad Certificate";
        break;
      default:
        errorDescription = e.error.toString();
        break;
    }
    return errorDescription;
  }
}
