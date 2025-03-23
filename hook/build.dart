import 'dart:io';
import 'package:logging/logging.dart';
import 'package:native_assets_cli/code_assets.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    final logger = Logger('')
      ..level = Level.ALL
      ..onRecord.listen((record) => stderr.writeln(record));
    
    logger.info('Native assets hook for $packageName - skipping compilation');
    final binAsset = await addBindingAsset(
      packageName,
      input.config.code,
      logger
    );

    final libAsset = await addLibraryAsset(
      packageName,
      input.config.code,
      logger
    );
    
    output.addCodeAsset(binAsset!);
    output.addCodeAsset(libAsset!);
  });
}


Future<CodeAsset?> addBindingAsset(
  String packageName,
  CodeConfig codeConfig,
  Logger logger
) async {
  final linkMode = _getLinkMode(codeConfig.linkModePreference);
  final bindingFileName = '${packageName}_bindings_generated.dart';
  final bindingFile = await _locateBindingFile(bindingFileName, logger);
  
  if (bindingFile == null) {
    logger.warning('Failed to add binding asset: binding file not found');
    return null;
  }
  
  final codeAsset = CodeAsset(
    package: packageName,
    name: bindingFileName,
    linkMode: linkMode,
    os: codeConfig.targetOS,
    file: bindingFile.uri,
    architecture: codeConfig.targetArchitecture,
  );
  
  logger.info('Added binding asset: ${bindingFile.path}');
  return codeAsset;
}

Future<CodeAsset?> addLibraryAsset(
  String packageName,
  CodeConfig codeConfig,
  Logger logger
) async {
  final os = codeConfig.targetOS;
  final linkMode = _getLinkMode(codeConfig.linkModePreference);
  final libraryFileName = os.libraryFileName(packageName, linkMode);
  final libraryFile = await _locateLibraryFile(libraryFileName, logger);
  
  if (libraryFile == null) {
    logger.warning('No assets will be registered. Make sure the library is built first.');
    return null;
  }
  
  final codeAsset = CodeAsset(
    package: packageName,
    name: libraryFileName,
    linkMode: linkMode,
    os: codeConfig.targetOS,
    file: libraryFile.uri,
    architecture: codeConfig.targetArchitecture,
  );
  
  logger.info('Registered pre-built native library: $libraryFileName');
  return codeAsset;
}


LinkMode _getLinkMode(LinkModePreference preference) {
  if (preference == LinkModePreference.dynamic || preference == LinkModePreference.preferDynamic) {
    return DynamicLoadingBundled();
  }
  assert(preference == LinkModePreference.static || preference == LinkModePreference.preferStatic);
  return StaticLinking();
}

Future<File?> _locateBindingFile(String bindingFileName, Logger logger) async {
  final currentDir = Directory.current.path;
  final bindingPath = '$currentDir/lib/$bindingFileName';
  final bindingFile = File(bindingPath);
  
  if (await bindingFile.exists()) {
    logger.info('Found binding file at ${bindingFile.path}');
    return bindingFile;
  }
  
  logger.warning('Could not find binding file. Expected at: $bindingPath');
  return null;
}

Future<File?> _locateLibraryFile(String libraryFileName, Logger logger) async {
  final currentDir = Directory.current.path;
  final libraryPath = '$currentDir/native/$libraryFileName';
  final libraryFile = File(libraryPath);
  
  if (await libraryFile.exists()) {
    logger.info('Found existing library at ${libraryFile.path}');
    return libraryFile;
  }
  
  logger.warning('Could not find library file. Expected at: $libraryPath');
  return null;
}

extension BuildOutputAddCodeAsset on BuildOutputBuilder {
  bool addCodeAsset(CodeAsset codeAsset) {
    assets.code.add(codeAsset);
    return true;
  }
}