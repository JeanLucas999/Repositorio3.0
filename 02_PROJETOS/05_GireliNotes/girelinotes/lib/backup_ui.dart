import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'backup_service.dart';
import 'folders.dart';
import 'models.dart';
import 'storage.dart';

bool get _isMobile => Platform.isAndroid || Platform.isIOS;

void _say(BuildContext context, String m) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

String _stamp() {
  final n = DateTime.now();
  String t(int v) => v.toString().padLeft(2, '0');
  return '${n.year}-${t(n.month)}-${t(n.day)}';
}

/// Pergunta o formato e grava o backup completo (um .zip).
Future<void> showBackupDialog(
  BuildContext context, {
  required List<Notebook> books,
  required List<Folder> folders,
  required double spacing,
}) async {
  if (books.isEmpty) {
    _say(context, 'Não há cadernos para guardar.');
    return;
  }
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text('Backup de ${books.length} ${books.length == 1 ? 'caderno' : 'cadernos'}'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 'notas'),
          child: const ListTile(
            leading: Icon(Icons.edit_note),
            title: Text('Cadernos editáveis (.notas)'),
            subtitle: Text('Leve; dá para restaurar aqui depois'),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 'pdf'),
          child: const ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined),
            title: Text('PDFs'),
            subtitle: Text('Para ler em qualquer lugar; não restaura no app'),
          ),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  final pdf = choice == 'pdf';

  final progress = ValueNotifier<String>('Preparando…');
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: 20),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: progress,
                builder: (_, v, __) => Text(v),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Uint8List? bytes;
  Object? error;
  try {
    bytes = await buildBackup(
      books,
      folders,
      pdf: pdf,
      lineSpacing: spacing,
      onProgress: (d, t) => progress.value = 'Caderno $d de $t…',
    );
  } catch (e) {
    error = e;
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // fecha o progresso
  if (error != null || bytes == null) {
    _say(context, 'Não foi possível fazer o backup: $error');
    return;
  }
  try {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Salvar backup',
      fileName: 'notas-backup-${_stamp()}${pdf ? '-pdf' : ''}.zip',
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: _isMobile ? bytes : null,
    );
    if (path == null) return;
    if (!_isMobile) {
      final target = path.toLowerCase().endsWith('.zip') ? path : '$path.zip';
      await File(target).writeAsBytes(bytes, flush: true);
    }
    _say(context, 'Backup salvo.');
  } catch (e) {
    _say(context, 'Não foi possível salvar: $e');
  }
}

/// Escolhe um backup (.zip) e restaura os cadernos. Devolve null se cancelou.
Future<RestoreResult?> pickAndRestore(
  BuildContext context,
  List<Notebook> books,
  List<Folder> folders,
  NotebookStorage storage,
) async {
  try {
    final res = await FilePicker.platform.pickFiles(
      dialogTitle: 'Restaurar backup',
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    final f = res?.files.single;
    if (f == null) return null;
    final bytes = f.bytes ?? await File(f.path!).readAsBytes();
    return await restoreBackup(bytes, books, folders, storage);
  } on FormatException catch (e) {
    _say(context, e.message);
  } catch (e) {
    _say(context, 'Não foi possível restaurar: $e');
  }
  return null;
}
