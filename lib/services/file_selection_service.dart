import 'package:flutter/services.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../config/app_config.dart';

class FileSelectionService {
  static const MethodChannel _channel = MethodChannel(
    'purchase_request_app_shell/file_selector',
  );

  const FileSelectionService();

  Future<List<String>> pickFiles(FileSelectorParams params) async {
    final List<Object?>? result = await _channel
        .invokeListMethod<Object?>('pickFiles', <String, Object?>{
          'allowMultiple': params.mode == FileSelectorMode.openMultiple,
          'allowedExtensions': AppConfig.uploadAllowedExtensions,
        });

    return result
            ?.whereType<String>()
            .where((String value) => value.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
  }
}
