import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_models.dart';

/// Service for file operations (save, load, export)
class FileService {
  static const String _recentFilesKey = 'recent_files';
  static const int _maxRecentFiles = 10;

  /// Load a file from a specific path
  Future<MarkdownDocument?> loadFileFromPath(String filePath) async {
    try {
      final file = File(filePath);
      
      // Check if file exists
      if (!await file.exists()) {
        print('File not found: $filePath');
        return null;
      }
      
      final content = await file.readAsString();
      final fileName = filePath.split('/').last.split('\\').last;
      final title = fileName.replaceAll(RegExp(r'\.(md|markdown|txt)$'), '');

      final now = DateTime.now();
      final doc = MarkdownDocument(
        id: IdGenerator.generate(),
        title: title,
        content: content,
        filePath: filePath,
        createdAt: now,
        updatedAt: now,
        isSaved: true,
      );

      await _addToRecentFiles(doc);
      return doc;
    } catch (e) {
      print('Error loading file from path: $e');
      return null;
    }
  }

  /// Open file picker and load a markdown file
  Future<MarkdownDocument?> openFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        return await loadFileFromPath(result.files.single.path!);
      }
    } catch (e) {
      print('Error opening file: $e');
    }
    return null;
  }

  /// Save document to existing file path
  Future<bool> saveFile(MarkdownDocument document) async {
    if (document.filePath == null) {
      return await saveFileAs(document) != null;
    }

    try {
      final file = File(document.filePath!);
      await file.writeAsString(document.content);
      await _addToRecentFiles(document);
      return true;
    } catch (e) {
      print('Error saving file: $e');
      return false;
    }
  }

  /// Save document with file picker (Save As)
  Future<String?> saveFileAs(MarkdownDocument document) async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Markdown File',
        fileName: '${document.title}.md',
        type: FileType.custom,
        allowedExtensions: ['md'],
      );

      if (outputPath != null) {
        // Ensure .md extension
        if (!outputPath.endsWith('.md')) {
          outputPath = '$outputPath.md';
        }

        final file = File(outputPath);
        await file.writeAsString(document.content);
        
        final updatedDoc = document.copyWith(filePath: outputPath);
        await _addToRecentFiles(updatedDoc);
        
        return outputPath;
      }
    } catch (e) {
      print('Error saving file as: $e');
    }
    return null;
  }

  /// Export document as HTML
  Future<bool> exportAsHtml(MarkdownDocument document, String htmlContent) async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export as HTML',
        fileName: '${document.title}.html',
        type: FileType.custom,
        allowedExtensions: ['html'],
      );

      if (outputPath != null) {
        if (!outputPath.endsWith('.html')) {
          outputPath = '$outputPath.html';
        }

        final file = File(outputPath);
        
        // Wrap in basic HTML structure
        final fullHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${document.title}</title>
  <style>
    body {
      max-width: 800px;
      margin: 40px auto;
      padding: 0 20px;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      line-height: 1.6;
      color: #333;
    }
    code {
      background: #f4f4f4;
      padding: 2px 6px;
      border-radius: 3px;
      font-family: 'Courier New', monospace;
    }
    pre {
      background: #f4f4f4;
      padding: 12px;
      border-radius: 5px;
      overflow-x: auto;
    }
    blockquote {
      border-left: 4px solid #ddd;
      padding-left: 16px;
      margin-left: 0;
      color: #666;
    }
  </style>
</head>
<body>
$htmlContent
</body>
</html>
''';
        
        await file.writeAsString(fullHtml);
        return true;
      }
    } catch (e) {
      print('Error exporting as HTML: $e');
    }
    return false;
  }

  /// Get list of recently opened files
  Future<List<MarkdownDocument>> getRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recentFilesKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => MarkdownDocument.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading recent files: $e');
      return [];
    }
  }

  /// Add document to recent files list
  Future<void> _addToRecentFiles(MarkdownDocument document) async {
    if (document.filePath == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final recentFiles = await getRecentFiles();

      // Remove if already exists
      recentFiles.removeWhere((doc) => doc.filePath == document.filePath);

      // Add to beginning
      recentFiles.insert(0, document);

      // Keep only max recent files
      if (recentFiles.length > _maxRecentFiles) {
        recentFiles.removeRange(_maxRecentFiles, recentFiles.length);
      }

      // Save
      final jsonList = recentFiles.map((doc) => doc.toJson()).toList();
      await prefs.setString(_recentFilesKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error adding to recent files: $e');
    }
  }

  /// Clear recent files list
  Future<void> clearRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentFilesKey);
  }
}