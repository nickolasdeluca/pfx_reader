import 'package:flutter_test/flutter_test.dart';
import 'package:pfx_reader/src/pfx_reader_method_channel.dart';
import 'package:pfx_reader/src/pfx_reader_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MethodChannelPfxReader is the default instance', () {
    expect(PfxReaderPlatform.instance, isInstanceOf<MethodChannelPfxReader>());
  });
}
