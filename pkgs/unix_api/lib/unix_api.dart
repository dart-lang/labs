import 'src/libc_bindings.g.dart' as libc;

export 'src/constants.g.dart';
export 'src/libc_bindings.g.dart' hide errno, seterrno;

int get errno => libc.errno();
set errno(int err) => libc.seterrno(err);
