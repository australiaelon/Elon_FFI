import 'dart:io';
import 'package:native_assets_cli/code_assets.dart';

LinkMode getLinkMode(LinkModePreference preference) {
  if (preference == LinkModePreference.dynamic ||
      preference == LinkModePreference.preferDynamic) {
    return DynamicLoadingBundled();
  }
  assert(
    preference == LinkModePreference.static ||
    preference == LinkModePreference.preferStatic,
  );
  return StaticLinking();
}

void main(List<String> args) async {
  await build(args, (input, output) async {
    final os = input.config.code.targetOS;
    final arch = input.config.code.targetArchitecture;
    final linkMode = getLinkMode(input.config.code.linkModePreference);

    final libraryFileName = os.libraryFileName(input.packageName, linkMode);
    final libUri = input.outputDirectory.resolve(libraryFileName);

    final prebuiltPath = 'native/$os/$arch/$libraryFileName';
    final prebuiltLibUri = input.packageRoot.resolve(prebuiltPath);

    await Directory.fromUri(input.outputDirectory).create(recursive: true);
    await File.fromUri(prebuiltLibUri).copy(libUri.toFilePath());

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: '${input.packageName}_bindings_generated.dart',
        file: libUri,
        linkMode: linkMode,
        os: input.config.code.targetOS,
        architecture: input.config.code.targetArchitecture,
      )
    );
  });
}