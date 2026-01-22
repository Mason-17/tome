import 'package:flutter/foundation.dart';
import '../models/document_models.dart';
import '../services/file_service.dart';

/// Manages the state of the current document and recent files
class DocumentProvider extends ChangeNotifier {
  final FileService _fileService = FileService();

  MarkdownDocument? _currentDocument;
  List<MarkdownDocument> _recentFiles = [];
  bool _isLoading = false;

  /// Get current document
  MarkdownDocument? get currentDocument => _currentDocument;

  /// Get recent files
  List<MarkdownDocument> get recentFiles => _recentFiles;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Check if there's an active document
  bool get hasDocument => _currentDocument != null;

  /// Check if current document has unsaved changes
  bool get hasUnsavedChanges => _currentDocument?.hasUnsavedChanges ?? false;

  /// Load recent files list
  Future<void> loadRecentFiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _recentFiles = await _fileService.getRecentFiles();
    } catch (e) {
      print('Error loading recent files: $e');
      _recentFiles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new empty document
  void createNewDocument() {
    final now = DateTime.now();
    _currentDocument = MarkdownDocument(
      id: IdGenerator.generate(),
      title: 'Untitled',
      content: '',
      createdAt: now,
      updatedAt: now,
      isSaved: true,
    );
    notifyListeners();
  }

  /// Open a file
  Future<bool> openFile() async {
    try {
      final doc = await _fileService.openFile();
      if (doc != null) {
        _currentDocument = doc;
        await loadRecentFiles();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error opening file: $e');
    }
    return false;
  }

  /// Open a specific recent file
  Future<bool> openRecentFile(MarkdownDocument recentDoc) async {
    try {
      if (recentDoc.filePath != null) {
        final file = await _fileService.openFile();
        if (file != null) {
          _currentDocument = file;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      print('Error opening recent file: $e');
    }
    return false;
  }

  /// Update document content
  void updateContent(String newContent) {
    if (_currentDocument == null) return;

    _currentDocument = _currentDocument!.copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
      isSaved: false, // Mark as unsaved
    );
    notifyListeners();
  }

  /// Update document title
  void updateTitle(String newTitle) {
    if (_currentDocument == null) return;

    _currentDocument = _currentDocument!.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
      isSaved: false,
    );
    notifyListeners();
  }

  /// Save current document
  Future<bool> saveDocument() async {
    if (_currentDocument == null) return false;

    try {
      final success = await _fileService.saveFile(_currentDocument!);
      if (success) {
        _currentDocument = _currentDocument!.copyWith(isSaved: true);
        await loadRecentFiles();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error saving document: $e');
    }
    return false;
  }

  /// Save document as (with file picker)
  Future<bool> saveDocumentAs() async {
    if (_currentDocument == null) return false;

    try {
      final filePath = await _fileService.saveFileAs(_currentDocument!);
      if (filePath != null) {
        _currentDocument = _currentDocument!.copyWith(
          filePath: filePath,
          isSaved: true,
        );
        await loadRecentFiles();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error saving document as: $e');
    }
    return false;
  }

  /// Export as HTML
  Future<bool> exportAsHtml(String htmlContent) async {
    if (_currentDocument == null) return false;

    try {
      return await _fileService.exportAsHtml(_currentDocument!, htmlContent);
    } catch (e) {
      print('Error exporting as HTML: $e');
      return false;
    }
  }

  /// Close current document
  void closeDocument() {
    _currentDocument = null;
    notifyListeners();
  }

  /// Clear recent files
  Future<void> clearRecentFiles() async {
    await _fileService.clearRecentFiles();
    _recentFiles = [];
    notifyListeners();
  }
}