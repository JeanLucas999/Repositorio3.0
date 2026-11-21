import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'export_service.dart';
import 'models.dart';

bool get _isMobile => Platform.isAndroid || Platform.isIOS;

String _safeName(String name) {
  final s = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return s.isEmpty ? 'caderno' : s;
}

void _toast(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

/// Pergunta o formato e exporta. [spacing] é o espaçamento do pautado (PDF).
Future<void> showExportDialog(
  BuildContext context,
  Notebook nb, {
  required double spacing,
}) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Exportar'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 'notas'),
          child: const ListTile(
            leading: Icon(Icons.edit_note),
            title: Text('Caderno editável (.notas)'),
            subtitle: Text('Leve; reabre aqui para continuar editando'),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 'pdf'),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('PDF'),
            subtitle: Text(nb.infinite
                ? 'Uma página com todo o conteúdo do quadro'
                : 'Uma página de PDF por página do caderno'),
          ),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  try {
    final bool pdf = choice == 'pdf';
    final Uint8List bytes =
        pdf ? await buildPdf(nb, lineSpacing: spacing) : encodeNotas(nb);
    final ext = pdf ? 'pdf' : kNotasExtension;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Exportar',
      fileName: '${_safeName(nb.name)}.$ext',
      type: FileType.custom,
      allowedExtensions: [ext],
      bytes: _isMobile ? bytes : null, // no celular o seletor grava os bytes
    );
    if (path == null) return; // cancelou
    if (!_isMobile) {
      final target = path.toLowerCase().endsWith('.$ext') ? path : '$path.$ext';
      await File(target).writeAsBytes(bytes, flush: true);
    }
    _toast(context, 'Exportado.');
  } catch (e) {
    _toast(context, 'Não foi possível exportar: $e');
  }
}

/// Escolhe um arquivo .notas e devolve o caderno (com [newId]), ou null.
Future<Notebook?> pickNotasFile(BuildContext context, String newId) async {
  try {
    final res = await FilePicker.platform.pickFiles(
      dialogTitle: 'Importar caderno',
      type: FileType.any,
      withData: true,
    );
    final f = res?.files.single;
    if (f == null) return null;
    final bytes = f.bytes ?? await File(f.path!).readAsBytes();
    return decodeNotas(bytes, newId);
  } on FormatException catch (e) {
    _toast(context, e.message);
  } catch (e) {
    _toast(context, 'Não foi possível importar: $e');
  }
  return null;
}
