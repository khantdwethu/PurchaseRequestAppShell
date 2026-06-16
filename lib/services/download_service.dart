import 'external_url_service.dart';

class DownloadService {
  const DownloadService(this._externalUrlService);

  final ExternalUrlService _externalUrlService;

  Future<bool> openDownload(Uri uri) {
    return _externalUrlService.launchExternal(uri);
  }
}
