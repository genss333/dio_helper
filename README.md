# Dio Helper 

## Example
```dart
class WeatherApi {
  Dio dioApi() {
    //get base url from env
    String baseUrl = 'https://api.openweathermap.org';

    //Set up the api
    Api api = Api(
      baseUrl: baseUrl,
      accessToken: '',
      refreshToken: '',
      onTokenRefreshed: (newToken) {
        debugPrint('New token: $newToken');
      },
      serverCertificate: '',
      connectTimeout: 180,
      receiveTimeout: 180,
      header: {},
    );

    api.onInit();

    return api.dio;
  }
}

class WeatherService extends GetxService {
  final WeatherApi api;

  WeatherService({required this.api});

  //create any tour services
}

## Dio Documentation
- ref: https://pub.dev/packages/dio
