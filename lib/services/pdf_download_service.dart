import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class PdfDownloadException implements Exception {
  const PdfDownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef TemporaryDirectoryProvider = Future<Directory> Function();
typedef CookieReader = Future<List<Cookie>> Function(String url);

class PdfDownloadService {
  PdfDownloadService({
    Dio? dio,
    CookieReader? cookieReader,
    TemporaryDirectoryProvider? temporaryDirectoryProvider,
  }) : _dio = dio ?? Dio(),
       _cookieReader = cookieReader ?? _readCookies,
       _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory;

  final Dio _dio;
  final CookieReader _cookieReader;
  final TemporaryDirectoryProvider _temporaryDirectoryProvider;

  Future<File> downloadPdf(String pdfUrl) async {
    final Uri? uri = Uri.tryParse(pdfUrl);
    if (uri == null) {
      throw const PdfDownloadException('Invalid PDF URL.');
    }

    final List<Cookie> cookies = await _cookieReader(pdfUrl);
    final String cookieHeader = cookies
        .map((Cookie cookie) => '${cookie.name}=${cookie.value}')
        .join('; ');

    late final Response<List<int>> response;
    try {
      response = await _dio.get<List<int>>(
        pdfUrl,
        options: Options(
          headers: <String, String>{
            if (cookieHeader.isNotEmpty) HttpHeaders.cookieHeader: cookieHeader,
            HttpHeaders.acceptHeader: 'application/pdf',
          },
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (int? status) {
            return status != null && status >= 200 && status < 400;
          },
        ),
      );
    } on DioException catch (error) {
      throw PdfDownloadException(_mapDioError(error));
    }

    final int statusCode = response.statusCode ?? 0;
    if (statusCode == HttpStatus.unauthorized) {
      throw const PdfDownloadException(
        'The session is not authorized to access this report.',
      );
    }

    if (statusCode == HttpStatus.forbidden) {
      throw const PdfDownloadException(
        'The user does not have permission to access this report.',
      );
    }

    final List<int> bytes = response.data ?? const <int>[];
    if (bytes.isEmpty) {
      throw const PdfDownloadException('The downloaded PDF file is empty.');
    }

    if (!_hasPdfSignature(bytes)) {
      throw const PdfDownloadException(
        'The server did not return a valid PDF file. It may have returned a login page or an error page.',
      );
    }

    final Directory temporaryDirectory = await _temporaryDirectoryProvider();
    final String fileName =
        'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}$fileName',
    );

    await file.writeAsBytes(bytes, flush: true);

    if (!await file.exists()) {
      throw const PdfDownloadException('The PDF file was not downloaded.');
    }

    if (await file.length() == 0) {
      await _deleteFileIfExists(file);
      throw const PdfDownloadException('The downloaded PDF file is empty.');
    }

    return file;
  }

  bool _hasPdfSignature(List<int> bytes) {
    if (bytes.length < 5) {
      return false;
    }

    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2D;
  }

  Future<void> _deleteFileIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The PDF report request timed out. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the report server.';
    }

    return 'Unable to open the PDF report.';
  }

  static final WebviewCookieManager _cookieManager = WebviewCookieManager();

  static Future<List<Cookie>> _readCookies(String url) {
    return _cookieManager.getCookies(url);
  }
}
