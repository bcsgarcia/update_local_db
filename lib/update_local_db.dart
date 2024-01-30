import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:intl/intl.dart';
import 'package:update_local_db/custom_env.dart';

int calculate() {
  return 6 * 7;
}

final timestampFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

Future<void> getLastDBFile() async {
  final ftpHost = await CustomEnv.get<String>(key: 'FTP_HOST');
  final ftpUser = await CustomEnv.get<String>(key: 'FTP_USER');
  final ftpPassword = await CustomEnv.get<String>(key: 'FTP_PASSWORD');
  final dbName = await CustomEnv.get<String>(key: 'DB_NAME');

  final backupPath = await CustomEnv.get<String>(key: 'BACKUP_PATH');

  var ftpClient = FTPConnect(ftpHost, user: ftpUser, pass: ftpPassword);

  try {
    await ftpClient.connect();
    await ftpClient.setTransferType(TransferType.binary);
    await ftpClient.changeDirectory('backup');
    await ftpClient.changeDirectory('db');

    await ftpClient.downloadFile(
      '${dbName}_backup.zip',
      File('$backupPath/${dbName}_backup.zip'),
      onProgress: (progressInPercent, totalReceived, fileSize) {
        print('[${timestampFormatter.format(DateTime.now())}] - Progresso Download MySQL Backup: $progressInPercent%');
      },
    );
    await ftpClient.disconnect();

    await extrairZip('$backupPath/${dbName}_backup.zip', backupPath);
    await executarScriptSQL(backupPath);
  } catch (e) {
    print('Erro ao enviar o arquivo para o FTP: $e');
  }
}

Future<void> extrairZip(String caminhoDoZip, String diretorioDestino) async {
  // Lê o arquivo zip
  var arquivo = File(caminhoDoZip);
  var bytes = await arquivo.readAsBytes();

  // Decodifica o arquivo Zip
  var archive = ZipDecoder().decodeBytes(bytes);

  // Extrai o conteúdo do Zip
  for (var arquivo in archive) {
    var nomeDoArquivo = arquivo.name;
    var dadosDoArquivo = arquivo.content as List<int>;
    var caminhoDoArquivo = '$diretorioDestino/$nomeDoArquivo';
    var arquivoDestino = File(caminhoDoArquivo);

    // Cria o diretório se não existir
    if (arquivo.isFile) {
      var diretorio = arquivoDestino.parent;
      if (!await diretorio.exists()) {
        await diretorio.create(recursive: true);
      }

      // Escreve o arquivo no disco
      await arquivoDestino.writeAsBytes(dadosDoArquivo);
    } else {
      // Se for um diretório, apenas cria o diretório
      if (!await arquivoDestino.exists()) {
        await arquivoDestino.create(recursive: true);
      }
    }
  }
  await arquivo.delete();
}

Future<void> executarScriptSQL(
  String backupPath,
) async {
  final dbName = await CustomEnv.get<String>(key: 'DB_NAME');
  final scriptPath = '$backupPath/${dbName}_backup.sql';
  final dbUser = await CustomEnv.get<String>(key: 'DB_USER');
  final dbPassword = await CustomEnv.get<String>(key: 'DB_PASSWORD');

  // Comando completo para ser executado no bash
  var comando = 'mysql -u $dbUser -p$dbPassword $dbName < $scriptPath';

  // Executando o comando no shell
  var resultado = await Process.run('bash', ['-c', comando]);

  if (resultado.exitCode != 0) {
    print('Erro ao executar o script SQL: ${resultado.stderr}');
  } else {
    print('Script SQL executado com sucesso: ${resultado.stdout}');
  }
}
