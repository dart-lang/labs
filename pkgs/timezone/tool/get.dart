/// A tool to download and compile TimeZone database
///
/// Usage example:
///
/// ```sh
/// $ pub run tool/get -s 2014h
/// ```

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as ospath;
import 'package:glob/glob.dart';

import 'package:timezone/tzfile.dart' as tzfile;
import 'package:timezone/timezone.dart';
import 'package:timezone/tools.dart';

final outPath = ospath.join('lib', 'data');

const _zicDataFiles = const [
    'africa',
    'antarctica',
    'asia',
    'australasia',
    'etcetera',
    'europe',
    'northamerica',
    'southamerica',
    'pacificnew',
    'backward'];


/// Load [tzfile.Location] from tzfile
Future<tzfile.Location> loadTzfileLocation(String name, String path) {
  return new File(path).readAsBytes().then((rawData) {
    return new tzfile.Location.fromBytes(name, rawData);
  });
}

/// Download IANA Time Zone database to [dest] directory.
Future<String> downloadTzData(String version, String dest) {
  final client = new HttpClient();
  final uri = Uri.parse(
      'https://www.iana.org/time-zones/repository/releases/tzdata$version.tar.gz');
  final outPath = ospath.join(dest, 'tzdata$version.tar.gz');

  return client.getUrl(uri).then((req) {
    return req.close();
  }).then((resp) {
    final out = new File(outPath);
    final sink = out.openWrite();
    return new Future.sync(() {
      return sink.addStream(resp);
    }).then((_) {
      return outPath;
    }).whenComplete(() {
      sink.close();
    });
  }).whenComplete(() {
    client.close();
  });
}

/// Unpack IANA Time Zone database to [dest] directory.
Future unpackTzData(String archivePath, String dest) {
  return Process.run(
      'tar',
      ['--directory=$dest', '-zxf', archivePath]).then((result) {
    if (result.exitCode == 0) {
      return true;
    }
    throw new Exception(result.stderr);
  }).catchError((ProcessException e) {
    throw new Exception(e.toString());
  }, test: (e) => e is ProcessException);
}

/// Compile IANA Time Zone file with zic compiler.
Future zic(String src, String dest) {
  return Process.run('zic', ['-d', dest, src]).then((result) {
    if (result.exitCode == 0) {
      return true;
    }
    throw new Exception(result.stderr);
  }).catchError((ProcessException e) {
    throw new Exception(e.toString());
  }, test: (e) => e is ProcessException);
}


void main(List<String> arguments) {
  // Initialize logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  final Logger log = new Logger('main');

  // Parse CLI arguments
  final parser =
      new ArgParser()..addOption('source', abbr: 's', defaultsTo: 'latest');
  final argResults = parser.parse(arguments);

  final source = argResults['source'];


  final db = new LocationDatabase();
  final tzfileLocations = [];

  log.info('Creating temp directory');
  Directory.systemTemp.createTemp('tzdata-').then((dir) {
    log.info('Temp directory created: ${dir.path}');
    return new Future.sync(() {
      log.info('Downloading timezone data');
      return downloadTzData(source, dir.path);
    }).then((archivePath) {
      log.info('Unpacking timezone data: $archivePath');
      return unpackTzData(archivePath, dir.path);
    }).then((_) {
      final zicDirPath = ospath.join(dir.path, 'zic');
      log.info('Creating zic directory');
      return new Directory(zicDirPath).create();
    }).then((zicDir) {
      log.info('Compiling timezone data with zic compiler');
      return Future.forEach(_zicDataFiles, (i) {
        log.info('- $i');
        return zic(ospath.join(dir.path, i), zicDir.path);
      }).then((_) {
        return new Future.sync(() {
          log.info('Importing tzfile Locations');

          final files = new Glob('**/*');

          return files.list(root: zicDir.path).toList().then((files) {
            return Future.forEach(files, (f) {
              if (f is File) {
                final name = ospath.relative(f.path, from: zicDir.path);
                log.info('- $name');
                return loadTzfileLocation(name, f.path).then((loc) {
                  tzfileLocations.add(loc);
                });
              }
            });
          });
        });
      });
    }).then((_) {
      log.info('Converting tzfile Locations to native Locations');
      return Future.forEach(tzfileLocations, (loc) {
        db.add(tzfileLocationToNativeLocation(loc));
      });
    }).then((_) {
      final out = new File(ospath.join(outPath, '$source.$dataExtension'));
      log.info('Serializing locations database to "$out"');
      return out.writeAsBytes(db.toBytes(), flush: true);
    }).whenComplete(() {
      log.info('Cleaning up');
      return dir.delete(recursive: true);
    });
  });

}
