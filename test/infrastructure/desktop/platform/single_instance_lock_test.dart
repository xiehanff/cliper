import 'dart:io';

import 'package:cliper/infrastructure/desktop/platform/single_instance_lock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('SingleInstanceLock', () {
    test(
      'prevents acquiring the same lock twice',
      () async {
        final lockFilePath = '${Directory.systemTemp.path}'
            '${Platform.pathSeparator}cliper-lock-${DateTime.now().microsecondsSinceEpoch}.lock';
        final first = SingleInstanceLock(
          logger: FakeAppLogger(),
          lockFilePath: lockFilePath,
        );
        final second = SingleInstanceLock(
          logger: FakeAppLogger(),
          lockFilePath: lockFilePath,
        );

        expect(await first.acquire(), isTrue);
        expect(await second.acquire(), isFalse);

        await first.release();
        expect(await second.acquire(), isTrue);
        await second.release();
      },
      skip: !Platform.isWindows,
    );
  });
}
