// Aplica o nome "Gireli Notes" nos arquivos nativos do Android e do Windows.
// Rode uma vez, na pasta do projeto:   dart run tools/aplicar_marca.dart
import 'dart:io';

const nome = 'Gireli Notes';
const binario = 'GireliNotes'; // nome do .exe

void editar(String caminho, String Function(String) f) {
  final a = File(caminho);
  if (!a.existsSync()) {
    stdout.writeln('  (não achei $caminho — pulei)');
    return;
  }
  final antes = a.readAsStringSync();
  final depois = f(antes);
  if (antes == depois) {
    stdout.writeln('  sem mudanças em $caminho');
  } else {
    a.writeAsStringSync(depois);
    stdout.writeln('  ok: $caminho');
  }
}

void main() {
  stdout.writeln('Android');
  editar('android/app/src/main/AndroidManifest.xml', (s) {
    s = s.replaceAll(RegExp(r'android:label="[^"]*"'), 'android:label="$nome"');
    if (!s.contains('android.permission.INTERNET')) {
      s = s.replaceFirst(
        RegExp(r'<manifest[^>]*>'),
        '\$&\n    <uses-permission android:name="android.permission.INTERNET"/>',
      );
    }
    return s;
  });

  stdout.writeln('Windows');
  editar('windows/runner/main.cpp', (s) =>
      s.replaceAllMapped(RegExp(r'(window\.Create\(L)"[^"]*"'), (m) => '${m[1]}"$nome"'));
  editar('windows/runner/Runner.rc', (s) {
    s = s.replaceAllMapped(
        RegExp(r'(VALUE "(?:FileDescription|ProductName)", )"[^"]*"'), (m) => '${m[1]}"$nome"');
    s = s.replaceAllMapped(
        RegExp(r'(VALUE "(?:InternalName)", )"[^"]*"'), (m) => '${m[1]}"$binario"');
    s = s.replaceAllMapped(
        RegExp(r'(VALUE "OriginalFilename", )"[^"]*"'), (m) => '${m[1]}"$binario.exe"');
    return s;
  });
  editar('windows/CMakeLists.txt', (s) =>
      s.replaceAllMapped(RegExp(r'(set\(BINARY_NAME )"[^"]*"\)'), (m) => '${m[1]}"$binario")'));

  stdout.writeln('\nPronto. Agora gere os ícones:  dart run flutter_launcher_icons');
}
