import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _contentController;
  late TextEditingController _titleController;
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _previewScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _titleController = TextEditingController();

    // Update controllers when document changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DocumentProvider>();
      if (provider.currentDocument != null) {
        _contentController.text = provider.currentDocument!.content;
        _titleController.text = provider.currentDocument!.title;
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _editorScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  void _updateControllersFromDocument(DocumentProvider provider) {
    if (provider.currentDocument != null) {
      if (_contentController.text != provider.currentDocument!.content) {
        _contentController.text = provider.currentDocument!.content;
      }
      if (_titleController.text != provider.currentDocument!.title) {
        _titleController.text = provider.currentDocument!.title;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        // Update controllers when document changes externally
        if (provider.currentDocument != null) {
          _updateControllersFromDocument(provider);
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.menu_book, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: provider.hasDocument
                      ? TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Untitled',
                            suffix: provider.hasUnsavedChanges
                                ? const Text(
                                    '●',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 20,
                                    ),
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            provider.updateTitle(value);
                          },
                        )
                      : const Text('Tome'),
                ),
              ],
            ),
            actions: [
              // New Document
              IconButton(
                icon: const Icon(Icons.note_add_outlined),
                tooltip: 'New Document',
                onPressed: () {
                  if (provider.hasUnsavedChanges) {
                    _showUnsavedChangesDialog(context, () {
                      provider.createNewDocument();
                      _contentController.clear();
                      _titleController.text = 'Untitled';
                    });
                  } else {
                    provider.createNewDocument();
                    _contentController.clear();
                    _titleController.text = 'Untitled';
                  }
                },
              ),
              // Open File
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: 'Open File',
                onPressed: () async {
                  if (provider.hasUnsavedChanges) {
                    _showUnsavedChangesDialog(context, () async {
                      await provider.openFile();
                    });
                  } else {
                    await provider.openFile();
                  }
                },
              ),
              // Save
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save',
                onPressed: provider.hasDocument
                    ? () async {
                        if (provider.currentDocument!.filePath == null) {
                          await provider.saveDocumentAs();
                        } else {
                          await provider.saveDocument();
                        }
                      }
                    : null,
              ),
              // Save As
              IconButton(
                icon: const Icon(Icons.save_as),
                tooltip: 'Save As',
                onPressed: provider.hasDocument
                    ? () => provider.saveDocumentAs()
                    : null,
              ),
              // Export HTML
              IconButton(
                icon: const Icon(Icons.code),
                tooltip: 'Export as HTML',
                onPressed: provider.hasDocument
                    ? () => _exportHtml(provider)
                    : null,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: provider.hasDocument
              ? _buildEditor(provider)
              : _buildWelcomeScreen(provider),
        );
      },
    );
  }

  Widget _buildWelcomeScreen(DocumentProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Tome',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const Text('A simple markdown editor'),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  provider.createNewDocument();
                  _titleController.text = 'Untitled';
                },
                icon: const Icon(Icons.note_add),
                label: const Text('New Document'),
              ),
              ElevatedButton.icon(
                onPressed: () => provider.openFile(),
                icon: const Icon(Icons.folder_open),
                label: const Text('Open File'),
              ),
            ],
          ),
          const SizedBox(height: 48),
          if (provider.recentFiles.isNotEmpty) ...[
            Text(
              'Recent Files',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.recentFiles.length,
                itemBuilder: (context, index) {
                  final recent = provider.recentFiles[index];
                  return ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(recent.displayName),
                    subtitle: Text(recent.filePath ?? ''),
                    onTap: () => provider.openRecentFile(recent),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditor(DocumentProvider provider) {
    return Row(
      children: [
        // Left side - Markdown Editor
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Markdown',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    scrollController: _editorScrollController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Start writing...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    onChanged: (value) {
                      provider.updateContent(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right side - Preview
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ),
              Expanded(
                child: Markdown(
                  controller: _previewScrollController,
                  data: provider.currentDocument!.content,
                  selectable: true,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showUnsavedChangesDialog(
    BuildContext context,
    VoidCallback onDiscard,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (result == true) {
      onDiscard();
    }
  }

  Future<void> _exportHtml(DocumentProvider provider) async {
    // For simplicity, we'll just convert the markdown to HTML
    // In a real app, you might want to use a markdown->HTML converter
    final htmlContent = provider.currentDocument!.content;
    
    final success = await provider.exportAsHtml(htmlContent);
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exported as HTML successfully')),
      );
    }
  }
}