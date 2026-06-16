import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

class ExternalUrlService {
  const ExternalUrlService();

  bool isAllowedWebViewUrl(Uri uri) {
    final String scheme = uri.scheme.toLowerCase();

    if (scheme.isEmpty || scheme == 'about' || scheme == 'data') {
      return true;
    }

    if (scheme != 'https') {
      return false;
    }

    final String host = uri.host.toLowerCase();
    if (host.isEmpty) {
      return false;
    }

    return _allowedWebViewHosts.any((String allowedHost) {
      return host == allowedHost || host.endsWith('.$allowedHost');
    });
  }

  bool shouldOpenExternally(Uri uri) {
    final String scheme = uri.scheme.toLowerCase();

    if (AppConfig.externalSchemes.contains(scheme)) {
      return true;
    }

    if (isDownloadableUrl(uri)) {
      return true;
    }

    if (scheme == 'http' || scheme == 'https') {
      return _matchesConfiguredDomain(uri.host, AppConfig.externalDomains);
    }

    return scheme.isNotEmpty && scheme != 'about' && scheme != 'data';
  }

  bool isExternalWebUrl(Uri uri) {
    final String scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && !isAllowedWebViewUrl(uri);
  }

  bool isDownloadableUrl(Uri uri) {
    final String extension = uri.pathSegments.isEmpty
        ? ''
        : uri.pathSegments.last.split('.').last.toLowerCase();

    return AppConfig.downloadableExtensions.contains(extension);
  }

  Future<bool> launchExternal(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      return false;
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Set<String> get _allowedWebViewHosts {
    final String configuredHost = AppConfig.websiteUri.host.toLowerCase();

    return <String>{
      if (configuredHost.isNotEmpty) configuredHost,
      ...AppConfig.additionalWebViewHosts.map((String host) {
        return host.toLowerCase();
      }),
    };
  }

  bool _matchesConfiguredDomain(
    String rawHost,
    List<String> configuredDomains,
  ) {
    final String host = rawHost.toLowerCase();

    return configuredDomains.any((String domain) {
      final String normalizedDomain = domain.toLowerCase();
      return host == normalizedDomain || host.endsWith('.$normalizedDomain');
    });
  }
}
