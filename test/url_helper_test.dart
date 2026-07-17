import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_request_app_shell/utils/url_helper.dart';

void main() {
  group('UrlHelper.isPdfUrl', () {
    test('detects pdf extension in path', () {
      expect(UrlHelper.isPdfUrl('https://example.com/report.pdf'), isTrue);
    });

    test('detects pdf extension in query values', () {
      expect(
        UrlHelper.isPdfUrl('https://example.com/download?file=report.pdf'),
        isTrue,
      );
    });

    test('detects guide route patterns', () {
      expect(UrlHelper.isPdfUrl('https://example.com/report/pdf/42'), isTrue);
      expect(
        UrlHelper.isPdfUrl('https://example.com/reports/view?id=1&format=pdf'),
        isTrue,
      );
      expect(
        UrlHelper.isPdfUrl('https://example.com/reports/view?id=1&output=pdf'),
        isTrue,
      );
    });

    test('ignores normal website urls', () {
      expect(UrlHelper.isPdfUrl('https://example.com/dashboard'), isFalse);
    });
  });
}
