import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'document_models.dart';
import 'document_repository.dart';

class MedicalDocumentsPanel extends StatefulWidget {
  const MedicalDocumentsPanel({
    required this.repository,
    this.doctorGrantId,
    super.key,
  });

  final DocumentRepository repository;
  final String? doctorGrantId;

  @override
  State<MedicalDocumentsPanel> createState() => _MedicalDocumentsPanelState();
}

class _MedicalDocumentsPanelState extends State<MedicalDocumentsPanel> {
  List<MedicalDocument>? _documents;
  bool _busy = false;
  String? _error;
  bool get _patientMode => widget.doctorGrantId == null;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final documents = _patientMode
          ? await widget.repository.patientDocuments()
          : await widget.repository.doctorDocuments(widget.doctorGrantId!);
      if (mounted) setState(() => _documents = documents);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = picked?.files.singleOrNull;
    if (file?.bytes == null || !mounted) return;
    final details = await showDialog<_DocumentDetails>(
      context: context,
      builder: (_) => _DocumentDetailsDialog(fileName: file!.name),
    );
    if (details == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final document = await widget.repository.upload(
        bytes: file!.bytes!,
        fileName: file.name,
        contentType: _contentType(file.extension),
        category: details.category,
        description: details.description,
      );
      if (mounted) {
        setState(() => _documents = [document, ...?_documents]);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical document uploaded securely.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download(MedicalDocument document) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final grantId = widget.doctorGrantId;
      final bytes = grantId == null
          ? await widget.repository.downloadForPatient(document.id)
          : await widget.repository.downloadForDoctor(grantId, document.id);
      await FilePicker.saveFile(
        dialogTitle: 'Save medical document',
        fileName: document.fileName,
        bytes: Uint8List.fromList(bytes),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(MedicalDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('Remove ${document.fileName} from the medical record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.delete(document.id);
      if (mounted) {
        setState(
          () => _documents = _documents
              ?.where((item) => item.id != document.id)
              .toList(),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = _documents ?? const <MedicalDocument>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEDICAL DOCUMENTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Reports, prescriptions and medical images',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                if (_patientMode)
                  FilledButton.icon(
                    key: const ValueKey('upload-medical-document'),
                    onPressed: _busy ? null : _upload,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload document'),
                  ),
              ],
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (!_busy && documents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text('No medical documents uploaded yet.'),
                ),
              ),
            for (final document in documents) ...[
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  document.contentType == 'application/pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                ),
                title: Text(
                  document.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${document.category} • ${_size(document.sizeBytes)}'
                  '${document.description == null ? '' : ' • ${document.description}'}',
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Download',
                      onPressed: _busy ? null : () => _download(document),
                      icon: const Icon(Icons.download_outlined),
                    ),
                    if (_patientMode)
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: _busy ? null : () => _delete(document),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentDetails {
  const _DocumentDetails(this.category, this.description);
  final String category;
  final String? description;
}

class _DocumentDetailsDialog extends StatefulWidget {
  const _DocumentDetailsDialog({required this.fileName});
  final String fileName;
  @override
  State<_DocumentDetailsDialog> createState() => _DocumentDetailsDialogState();
}

class _DocumentDetailsDialogState extends State<_DocumentDetailsDialog> {
  String _category = 'Lab result';
  final _description = TextEditingController();
  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Document details'),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.fileName),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items:
                const [
                      'Lab result',
                      'Prescription',
                      'Imaging',
                      'Discharge summary',
                      'Other',
                    ]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _category = value ?? 'Other'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _DocumentDetails(
            _category,
            _description.text.trim().isEmpty ? null : _description.text.trim(),
          ),
        ),
        child: const Text('Upload securely'),
      ),
    ],
  );
}

String _contentType(String? extension) => switch (extension?.toLowerCase()) {
  'pdf' => 'application/pdf',
  'png' => 'image/png',
  _ => 'image/jpeg',
};

String _size(int bytes) => bytes >= 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).toStringAsFixed(1)} KB';

String _message(Object error) => error is ApiException
    ? error.message
    : 'The document request could not be completed.';
