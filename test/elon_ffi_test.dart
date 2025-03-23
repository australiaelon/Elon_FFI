import 'package:test/test.dart';
import 'package:elon_ffi/elon_ffi_bindings_generated.dart';

void main() {
  test('invoke native function', () {
    expect(sum(24, 18), 42);
  });
}
