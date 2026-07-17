import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_request_app_shell/screens/pdf_viewer_screen.dart';
import 'package:purchase_request_app_shell/services/pdf_download_service.dart';

void main() {
  testWidgets('shows retry ui when download fails', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PdfViewerScreen(
          pdfUrl: 'https://example.com/report.pdf',
          downloadService: _FailingDownloadService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Try Again'), findsOneWidget);
    expect(find.textContaining('Unable to open'), findsOneWidget);
  });

  testWidgets('shows loading state before download completes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PdfViewerScreen(
          pdfUrl: 'https://example.com/report.pdf',
          downloadService: _PendingDownloadService(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

class _FailingDownloadService extends PdfDownloadService {
  @override
  Future<File> downloadPdf(String pdfUrl) async {
    throw const PdfDownloadException('Unable to open the PDF report.');
  }
}

class _PendingDownloadService extends PdfDownloadService {
  @override
  Future<File> downloadPdf(String pdfUrl) {
    return Completer<File>().future;
  }
}
