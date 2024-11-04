import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import 'pretty_print_json.dart';
import 'status_code.dart';

class Api {
  String baseUrl;
  String accessToken;
  String refreshToken;
  String serverCertificate;
  List<String> ignorePaths = [];
  Function(String newToken) onTokenRefreshed;
  Map<String, dynamic>? header;
  int? connectTimeout;
  int? receiveTimeout;

  Api({
    required this.baseUrl,
    required this.accessToken,
    required this.refreshToken,
    this.serverCertificate = '',
    this.ignorePaths = const [],
    required this.onTokenRefreshed,
    this.connectTimeout,
    this.receiveTimeout,
    this.header,
  });

  Dio dio = Dio();

  void onInit() {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = Duration(seconds: connectTimeout ?? 90);
    dio.options.receiveTimeout = Duration(seconds: receiveTimeout ?? 90);
    dio.options.headers = header;

    dio.interceptors.add(
      CustomInterceptor(
        accessToken: accessToken,
        refreshToken: refreshToken,
        serverCertificate: serverCertificate,
        ignorePaths: ignorePaths,
        dio: dio,
        onTokenRefreshed: onTokenRefreshed,
      ),
    );
  }
}

class CustomInterceptor extends Interceptor {
  String accessToken;
  String refreshToken;
  String serverCertificate;
  List<String> ignorePaths = [];
  Dio dio;
  Function(String newToken) onTokenRefreshed;

  CustomInterceptor({
    required this.accessToken,
    required this.refreshToken,
    required this.serverCertificate,
    required this.dio,
    this.ignorePaths = const [],
    required this.onTokenRefreshed,
  });

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!ignorePaths.any((v) => options.path.contains(v))) {
      if (accessToken.isEmpty) {
        debugPrint('ACCESS_TOKEN == empty');
      }
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      return HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) {
          return serverCertificate == cert.pem;
        };
    };

    PrettyPrint.print(options.headers);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    PrettyPrint.print(response.data);
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    PrettyPrint.print(err.response?.data);
    if (err.response?.statusCode == StatusCode.status401) {
      debugPrint("Access Token was expired ⏳");

      RequestOptions requestOptions = err.requestOptions;
      try {
        Response responseRfToken = await dio.post(
          '/authen/refresh',
          options: Options(
            headers: {
              "Authorization": "Bearer $refreshToken",
            },
          ),
        );

        if (responseRfToken.statusCode == StatusCode.statusOK) {
          debugPrint("Renew Access Token 🎉");

          final newAccessToken = responseRfToken.data['access_token'];

          // update token
          requestOptions.headers["Authorization"] = "Bearer $newAccessToken";

          // storage token
          onTokenRefreshed(newAccessToken);
          debugPrint('newToken: $newAccessToken');

          // repeat
          debugPrint("Repeat 🔃");
          Response? responseResolve = await dio.request(
            requestOptions.baseUrl + requestOptions.path,
            data: requestOptions.data,
            queryParameters: requestOptions.queryParameters,
            options: Options(
              method: requestOptions.method,
              headers: requestOptions.headers,
            ),
          );
          debugPrint(
            'RESOLVE[${responseResolve.statusCode}] => DATA: ${responseResolve.data}',
          );
          return handler.resolve(responseResolve);
        }
      } catch (e) {
        debugPrint(e.toString());
        debugPrint("Refresh Token was expired ❌");
      }
    }
    debugPrint('Error: ${err.message}');
    if (err.response != null) {
      debugPrint('Error Data: ${err.response?.data}');
    }

    return handler.next(err);
  }
}
