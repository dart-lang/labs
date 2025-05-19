import 'libc_bindings.g.dart' as libc;

export 'constants.g.dart';
export 'libc_bindings.g.dart' hide errno, seterrno;

int get errno => libc.errno();
set errno(int err) => libc.seterrno(err);
