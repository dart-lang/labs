// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:jot/api.dart';
import 'package:jot/src/analysis.dart';
import 'package:jot/src/generate.dart';
import 'package:jot/src/html.dart';
import 'package:jot/src/llm_summary.dart';
import 'package:jot/src/utils.dart';
import 'package:jot/workspace.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  var parser = createArgsParser();
  ArgResults results;

  try {
    results = parser.parse(args);
  } catch (e) {
    printUsage(parser, e);
    exit(64);
  }

  var help = results['help'] as bool;
  if (help) {
    printUsage(parser);
    exit(0);
  }

  var rest = results.rest;
  var sdkDir = rest.isEmpty ? detectSdk : Directory(rest.first);
  if (!sdkDir.existsSync()) {
    stderr.writeln("error: '${sdkDir.path}' does not exist.");
    exit(1);
  }

  validateSdk(sdkDir);

  var outDir = Directory(results['output'] as String);

  await generate(sdkDir, outDir);
}

Future<void> generate(Directory sdkDir, Directory outDir) async {
  var log = Logger.standard();

  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  var versionFile = File(p.join(sdkDir.path, 'version'));
  final version = _parserSdkVersion(versionFile);

  log.stdout('SDK ${sdkDir.path}');
  log.stdout('Version $version');
  log.stdout('');

  var progress = log.progress('Resolving SDK libraries');

  // parse the libraries file
  var librariesFile = File(p.join(sdkDir.path, 'lib', 'libraries.json'));
  var libraries =
      jsonDecode(librariesFile.readAsStringSync()) as Map<String, dynamic>;

  var libNames = Directory(p.join(sdkDir.path, 'lib'))
      .listSyncSorted()
      .whereType<Directory>()
      .map((d) => d.name)
      .where((name) => !name.startsWith('_'))
      .where((name) => libraryUriFor(name, libraries) != null)
      .toList();

  const knownVmLibs = {'cli', 'ffi', 'io', 'isolate', 'mirrors'};

  const knownWebLibs = {
    'html',
    'indexed_db',
    'js',
    'js_interop_unsafe',
    'js_interop',
    'js_util',
    'svg',
    'web_audio',
    'web_gl',
  };

  var vmLibs = libNames.toSet().intersection(knownVmLibs).toList()..sort();
  var webLibs = libNames.toSet().intersection(knownWebLibs).toList()..sort();
  var coreLibs =
      (libNames.toSet()
            ..removeAll(webLibs)
            ..removeAll(vmLibs))
          .toList();

  // set up the analysis context
  var analyzer = Analyzer.packages(
    includedPaths: [p.normalize(sdkDir.absolute.path)],
  );

  // create the workspace
  var stats = Stats()..start();
  var htmlTemplate = await HtmlTemplate.createDefault();
  var workspace = Workspace('Dart SDK', htmlTemplate: htmlTemplate);
  workspace.version = version;
  workspace.footer = 'Dart SDK $version';
  final sdkReadmeFile = File(p.join(sdkDir.path, 'lib', 'api_readme.md'));
  workspace.mainFile = WorkspaceFile(
    workspace,
    'Readme',
    'index.html',
    createMarkdownGenerator(sdkReadmeFile),
    FileType.markdown,
  );
  workspace.description = sdkReadmeFile.readAsStringSync();

  final api = workspace.api;

  // workspace.addChild(DocSeparator(workspace, 'Dart SDK'));

  final libDir = Directory(p.join(sdkDir.path, 'lib'));
  for (var entry in {
    'Core libraries': coreLibs,
    'VM libraries': vmLibs,
    'Web libraries': webLibs,
  }.entries) {
    var categoryName = entry.key;
    var libNames = entry.value;

    workspace.addChild(WorkspaceSeparator(workspace, categoryName));

    // var categoryContainer =
    //     workspace.addChild(DocContainer(workspace, categoryName));

    for (var libName in libNames) {
      var libUrl = libraryUriFor(libName, libraries)!;

      var libFile = File(p.join(libDir.path, libUrl));
      var libraryElement = await analyzer.getLibraryByUri(
        libFile.uri.toString(),
      );

      var packageContainer = workspace.addChild(
        WorkspaceDirectory(workspace, 'dart:$libName'),
      );

      var library = api.addLibrary(
        libraryElement.element,
        'Dart SDK',
        'dart:$libName',
      );
      var file = WorkspaceFile(
        packageContainer,
        'dart:$libName',
        '$libName.html',
        libraryGenerator(library),
      );
      file.importScript = file.name;
      packageContainer.mainFile = file;

      api.addResolution(library, packageContainer.mainFile!);

      for (var itemContainer in library.allChildrenSorted.whereType<Items>()) {
        var path = '$libName/${itemContainer.name}.html';
        var docFile = packageContainer.addChild(
          WorkspaceFile(
            packageContainer,
            itemContainer.name,
            path,
            itemsGenerator(itemContainer),
          ),
        );
        api.addResolution(itemContainer, docFile);
      }
    }

    workspace.api.packages.first.version = workspace.version;
    workspace.api.packages.first.description = workspace.description;
  }

  // workspace.addChild(DocSeparator(workspace, 'Core Packages'));

  // Add a few packages - path, args, collection, ...
  // todo: This is temporary for now; decide whether we do want to document the
  //       sdk w/ a core set of packages or not.

  // workspace.addPackage(
  //     analyzer, 'args', getPackageRoot(Directory.current, 'args')!);
  // workspace.addPackage(
  //   analyzer,
  //   'collection',
  //   getPackageRoot(Directory.current, 'collection')!,
  // );
  // workspace.addPackage(
  //     analyzer, 'path', getPackageRoot(Directory.current, 'path')!);

  progress.cancel();

  // build model
  api.finish();

  // generate
  log.stdout('');
  log.stdout('Generating docs...');

  // generate docs
  final generator = Generator(
    workspace: workspace,
    outDir: outDir,
    logger: log,
    stats: stats,
  );
  await generator.generate();

  // generate the markdown summary files
  final summary = LLMSummary(
    workspace: workspace,
    outDir: outDir,
    logger: log,
    stats: stats,
  );
  summary.generate();

  stats.stop();

  log.stdout('');
  // "1,347 symbols, 82% have documentation, 4 libraries, 8MB of html, 0.3s"
  log.stdout(
    'Wrote docs to ${p.relative(outDir.path)} in '
    '${stats.elapsedSeconds}s (${stats.fileCount} files, '
    '${stats.sizeDesc}).',
  );
}

String _parserSdkVersion(File versionFile) {
  var version = versionFile.readAsStringSync().trim();
  if (version.contains(' ')) {
    version = version.substring(0, version.indexOf(' '));
  }
  if (version.contains('-edge.')) {
    // Dart SDK 3.0.0-edge.3ad45940d6e...a585d088639f5
    version = version.substring(0, version.lastIndexOf('.'));
  }
  return version;
}

String? libraryUriFor(String name, Map<String, dynamic> libraries) {
  for (var key in libraries.keys) {
    var value = libraries[key];
    if (value is Map && value.containsKey('libraries')) {
      var info = value['libraries'] as Map<String, dynamic>;
      if (info.containsKey(name)) {
        return (info[name] as Map<String, dynamic>)['uri'] as String?;
      }
    }
  }

  return null;
}

ArgParser createArgsParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this command help.',
    )
    ..addOption(
      'output',
      abbr: 'o',
      defaultsTo: 'doc/sdk',
      help: 'Configure the output directory.',
    );
}

void printUsage(ArgParser parser, [Object? error]) {
  if (error != null) {
    print(error);
  } else {
    print('Generate API documentation for the Dart SDK.');
  }

  print('');

  print('usage: dart tool/create_dart_sdk.dart <options> [<sdk directory>]');
  print('');
  print(parser.usage);
}

Directory get detectSdk {
  final vm = Platform.resolvedExecutable;
  // <dart-sdk>/bin/dart
  return Directory(p.dirname(p.dirname(vm)));
}

void validateSdk(Directory sdk) {
  var versionFile = File(p.join(sdk.path, 'version'));
  if (!versionFile.existsSync()) {
    stderr.writeln('Invalid SDK (${sdk.path}) - missing version file');
    exit(1);
  }

  var librariesFile = File(p.join(sdk.path, 'lib', 'libraries.json'));
  if (!librariesFile.existsSync()) {
    stderr.writeln('Invalid SDK (${sdk.path}) - missing libraries file');
    exit(1);
  }
}

// ignore: unreachable_from_main
extension WorkspaceExtension on Workspace {
  // ignore: unreachable_from_main
  void addPackage(
    Analyzer analyzer,
    String packageName,
    String fullPackagePath,
  ) {
    // todo: find the file location

    // todo: get the element info

    // todo: find the public libraries
  }
}
