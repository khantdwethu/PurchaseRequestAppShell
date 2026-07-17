class UrlHelper {
  const UrlHelper._();

  static bool isPdfUrl(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    final String path = uri.path.toLowerCase();
    if (path.endsWith('.pdf')) {
      return true;
    }

    for (final String value in uri.queryParameters.values) {
      if (value.toLowerCase().contains('.pdf')) {
        return true;
      }
    }

    final String lowerUrl = url.toLowerCase();
    return lowerUrl.contains('/pdf/') ||
        lowerUrl.contains('/report/pdf') ||
        lowerUrl.contains('format=pdf') ||
        lowerUrl.contains('output=pdf');
  }
}
