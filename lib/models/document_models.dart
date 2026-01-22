import 'dart:convert';

/// Represents a markdown document
class MarkdownDocument {
  final String id;
  final String title;
  final String content;
  final String? filePath; // Path on disk if saved
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSaved; // Track if there are unsaved changes

  MarkdownDocument({
    required this.id,
    required this.title,
    required this.content,
    this.filePath,
    required this.createdAt,
    required this.updatedAt,
    this.isSaved = true,
  });

  // Check if document has been modified since last save
  bool get hasUnsavedChanges => !isSaved;

  // Get file name from path or use title
  String get displayName {
    if (filePath != null) {
      return filePath!.split('/').last.split('\\').last;
    }
    return '$title.md';
  }

  // Serialization for recent files list
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MarkdownDocument.fromJson(Map<String, dynamic> json) {
    return MarkdownDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      content: '', // Content loaded separately from file
      filePath: json['filePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSaved: true,
    );
  }

  MarkdownDocument copyWith({
    String? id,
    String? title,
    String? content,
    String? filePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSaved,
  }) {
    return MarkdownDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

/// Helper to generate unique IDs
class IdGenerator {
  static String generate() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}