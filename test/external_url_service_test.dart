import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_request_app_shell/config/app_config.dart';
import 'package:purchase_request_app_shell/services/external_url_service.dart';

void main() {
  const ExternalUrlService service = ExternalUrlService();

  test('allows configured website host inside the WebView', () {
    expect(service.isAllowedWebViewUrl(AppConfig.websiteUri), isTrue);
  });

  test('opens phone links externally', () {
    expect(
      service.shouldOpenExternally(Uri.parse('tel:+959123456789')),
      isTrue,
    );
  });

  test('treats PDF URLs as downloads', () {
    expect(
      service.isDownloadableUrl(Uri.parse('https://yourdomain.com/file.pdf')),
      isTrue,
    );
  });
}
