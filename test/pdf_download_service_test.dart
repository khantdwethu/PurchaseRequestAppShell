import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_request_app_shell/services/pdf_download_service.dart';

void main() {
  group('PdfDownloadService', () {
    test('rejects invalid url', () async {
      final PdfDownloadService service = PdfDownloadService(
        dio: _FakeDio(),
        cookieReader: _fakeCookieReader,
        temporaryDirectoryProvider: Directory.systemTemp.createTemp,
      );

      await expectLater(
        service.downloadPdf('not a url'),
        throwsA(isA<PdfDownloadException>()),
      );
    });

    test('rejects non pdf bytes', () async {
      final PdfDownloadService service = PdfDownloadService(
        dio: _FakeDio(
          response: Response<List<int>>(
            data: '<html></html>'.codeUnits,
            requestOptions: RequestOptions(path: 'https://example.com/report'),
            statusCode: 200,
          ),
        ),
        cookieReader: _fakeCookieReader,
        temporaryDirectoryProvider: Directory.systemTemp.createTemp,
      );

      await expectLater(
        service.downloadPdf('https://example.com/report'),
        throwsA(isA<PdfDownloadException>()),
      );
    });

    test('returns file for valid pdf bytes', () async {
      final PdfDownloadService service = PdfDownloadService(
        dio: _FakeDio(
          response: Response<List<int>>(
            data: <int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31],
            requestOptions: RequestOptions(path: 'https://example.com/report'),
            statusCode: 200,
          ),
        ),
        cookieReader: _cookieReaderWithValue,
        temporaryDirectoryProvider: Directory.systemTemp.createTemp,
      );

      final File file = await service.downloadPdf('https://example.com/report');

      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(0));

      await file.delete();
    });
  });
}

class _FakeDio extends DioMixin implements Dio {
  _FakeDio({Response<List<int>>? response}) : _response = response;

  final Response<List<int>>? _response;
  BaseOptions _options = BaseOptions();

  @override
  HttpClientAdapter get httpClientAdapter => throw UnimplementedError();

  @override
  set httpClientAdapter(HttpClientAdapter adapter) {}

  @override
  BaseOptions get options => _options;

  @override
  set options(BaseOptions value) {
    _options = value;
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (_response == null) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
      );
    }

    return _response as Response<T>;
  }
}

Future<List<Cookie>> _fakeCookieReader(String url) async {
  return const <Cookie>[];
}

Future<List<Cookie>> _cookieReaderWithValue(String url) async {
  return <Cookie>[Cookie('auth', 'cookie')];
}
