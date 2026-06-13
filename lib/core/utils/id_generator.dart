import 'dart:math';

abstract interface class IdGenerator {
  String generate();
}

final class RandomIdGenerator implements IdGenerator {
  static const _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static final _random = Random.secure();

  @override
  String generate({int length = 16}) {
    return List.generate(
      length,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
  }
}

class IdGeneratorProvider {
  static IdGenerator instance = RandomIdGenerator();
}
