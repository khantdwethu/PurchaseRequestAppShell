import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../services/pdf_download_service.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    required this.pdfUrl,
    this.downloadService,
    super.key,
  });

  final String pdfUrl;
  final PdfDownloadService? downloadService;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfDownloadService _downloadService =
      widget.downloadService ?? PdfDownloadService();

  File? _pdfFile;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isDownloading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _deleteTemporaryFile();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    if (mounted) {
      setState(() {
        _isDownloading = true;
        _errorMessage = null;
      });
    }

    try {
      final File file = await _downloadService.downloadPdf(widget.pdfUrl);
      if (!mounted) {
        return;
      }

      setState(() {
        _pdfFile = file;
        _isDownloading = false;
      });
    } on PdfDownloadException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isDownloading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to open the PDF report: $error';
        _isDownloading = false;
      });
    }
  }

  Future<void> _deleteTemporaryFile() async {
    final File? file = _pdfFile;
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _totalPages > 0
              ? 'PDF Report ${_currentPage + 1}/$_totalPages'
              : 'PDF Report',
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isDownloading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading PDF report...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.picture_as_pdf_outlined, size: 64),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadPdf,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final File? file = _pdfFile;
    if (file == null) {
      return const Center(child: Text('PDF file is unavailable.'));
    }

    return PDFView(
      filePath: file.path,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      fitPolicy: FitPolicy.BOTH,
      onRender: (int? pages) {
        if (!mounted) {
          return;
        }

        setState(() {
          _totalPages = pages ?? 0;
        });
      },
      onPageChanged: (int? page, int? total) {
        if (!mounted) {
          return;
        }

        setState(() {
          _currentPage = page ?? 0;
          _totalPages = total ?? _totalPages;
        });
      },
      onError: (dynamic error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _errorMessage = 'PDF rendering error: $error';
        });
      },
      onPageError: (int? page, dynamic error) {},
    );
  }
}
