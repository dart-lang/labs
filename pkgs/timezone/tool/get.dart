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

import 'package:timezone/tzdata.dart' as tzfile;
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
    }).whenComplete(() {
      log.info('Cleaning up temporary directories');
      return dir.delete(recursive: true);
    }).then((_) {
      log.info('Converting tzfile Locations to native Locations');
      return new Future.sync(() {
        final db = new LocationDatabase();

        for (final loc in tzfileLocations) {
          db.add(tzfileLocationToNativeLocation(loc));
        }

        logReport(r) {
          log.info('  + locations: ${r.originalLocationsCount} => ${r.newLocationsCount}');
          log.info('  + transitions: ${r.originalTransitionsCount} => ${r.newTransitionsCount}');
        }

        log.info('Building location databases:');

        log.info('- all locations');
        final allDb = filterTimeZoneData(db, locations: allLocations);
        logReport(allDb.i2);

        log.info('- common locations from all locations');
        final commonDb = filterTimeZoneData(allDb.i1, locations: commonLocations);
        logReport(commonDb.i2);

        log.info('- [2010 - 2020 years] from common locations');
        final common_2010_2020_Db = filterTimeZoneData(commonDb.i1,
            dateFrom: new DateTime.utc(2010, 1, 1).millisecondsSinceEpoch,
            dateTo: new DateTime.utc(2020, 1, 1).millisecondsSinceEpoch,
            locations: commonLocations);
        logReport(common_2010_2020_Db.i2);

        log.info('Serializing location databases');
        final allOut = new File(ospath.join(outPath, '${source}_all.$tzDataExtension'));
        final commonOut = new File(ospath.join(outPath, '${source}.$tzDataExtension'));
        final common_2010_2020_Out = new File(ospath.join(outPath, '${source}_2010-2020.$tzDataExtension'));
        return allOut.writeAsBytes(allDb.i1.toBytes(), flush: true).then((_) {
          return commonOut.writeAsBytes(commonDb.i1.toBytes(), flush: true);
        }).then((_) {
          return common_2010_2020_Out.writeAsBytes(common_2010_2020_Db.i1.toBytes(), flush: true);
        });
      });
    }).then((_) {
      exit(0);
    });
  });
}