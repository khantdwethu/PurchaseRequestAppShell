import 'package:file_picker/file_picker.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../config/app_config.dart';

class FileSelectionService {
  const FileSelectionService();

  Future<List<String>> pickFiles(FileSelectorParams params) async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: params.mode == FileSelectorMode.openMultiple,
      allowedExtensions: AppConfig.uploadAllowedExtensions,
      type: FileType.custom,
      withData: false,
    );

    if (result == null) {
      return <String>[];
    }

    return result.files
        .map((PlatformFile file) => file.path)
        .whereType<String>()
        .map((String path) => Uri.file(path).toString())
        .toList(growable: false);
  }
}
