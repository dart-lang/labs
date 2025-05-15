import 'libc_bindings.dart' as libc;

export 'constants.g.dart';
export 'libc_bindings.dart' hide errno, seterrno;

int get errno => libc.errno();
set errno(int err) => libc.seterrno(err);
