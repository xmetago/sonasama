import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';

class CustomPdfViewer extends StatefulWidget {
  final String pdfPath;
  final String title;

  const CustomPdfViewer({
    super.key,
    required this.pdfPath,
    required this.title,
  });

  @override
  State<CustomPdfViewer> createState() => _CustomPdfViewerState();
}

class _CustomPdfViewerState extends State<CustomPdfViewer> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _checkPdfFile();
  }

  void _checkPdfFile() {
    try {
      print('📄 PDF dosyası kontrol ediliyor: ${widget.pdfPath}');
      
      final pdfFile = File(widget.pdfPath);
      if (!pdfFile.existsSync()) {
        print('❌ PDF dosyası bulunamadı: ${widget.pdfPath}');
        setState(() {
          _hasError = true;
          _errorMessage = 'PDF dosyası bulunamadı';
          _isLoading = false;
        });
        return;
      }

      final fileSize = pdfFile.lengthSync();
      print('📄 PDF dosya boyutu: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');

      if (fileSize == 0) {
        print('❌ PDF dosyası boş');
        setState(() {
          _hasError = true;
          _errorMessage = 'PDF dosyası boş';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
      
      print('✅ PDF dosyası hazır');
    } catch (e) {
      print('❌ PDF dosyası kontrol edilirken hata: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'PDF dosyası açılırken hata: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF yükleniyor...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Hata',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _errorMessage = '';
                });
                _checkPdfFile();
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Sayfa bilgisi
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sayfa $_currentPage / $_totalPages',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ],
          ),
        ),
        // PDF viewer
        Expanded(
          child: PDFView(
            filePath: widget.pdfPath,
                         onRender: (pages) {
               print('✅ PDF başarıyla yüklendi');
               print('📄 Sayfa sayısı: $pages');
               setState(() {
                 _totalPages = pages ?? 0;
                 _isLoading = false;
               });
             },
            onError: (error) {
              print('❌ PDF yüklenirken hata: $error');
              setState(() {
                _hasError = true;
                _errorMessage = 'PDF yüklenirken hata: $error';
              });
            },
            onPageError: (page, error) {
              print('❌ Sayfa $page yüklenirken hata: $error');
            },
                         onPageChanged: (page, total) {
               print('📄 Sayfa değişti: $page / $total');
               setState(() {
                 _currentPage = page ?? 1;
               });
             },
            defaultPage: 1,
            swipeHorizontal: false,
            enableSwipe: true,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
          ),
        ),
      ],
    );
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
