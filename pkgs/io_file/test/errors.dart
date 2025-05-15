import 'dart:io';
import 'package:errno/errno.dart';

int get eexist => LinuxErrors.eexist;
int get eisdir => LinuxErrors.eisdir;
int get enoent => LinuxErrors.enoent;
int get enotdir => LinuxErrors.enotdir;
int get enotempty =>
    Platform.isMacOS ? DarwinErrors.enotempty : LinuxErrors.enotempty;
