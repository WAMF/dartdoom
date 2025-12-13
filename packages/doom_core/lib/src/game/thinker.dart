typedef ThinkerFunction = void Function(Thinker);

class Thinker {
  Thinker? prev;
  Thinker? next;
  ThinkerFunction? function;
}

class ThinkerList {
  late final Thinker _sentinel;

  void init() {
    _sentinel = Thinker();
    _sentinel.prev = _sentinel;
    _sentinel.next = _sentinel;
  }

  void add(Thinker thinker) {
    final last = _sentinel.prev!;
    thinker.next = _sentinel;
    thinker.prev = last;
    last.next = thinker;
    _sentinel.prev = thinker;
  }

  void remove(Thinker thinker) {
    thinker.function = null;
  }

  void runAll() {
    var current = _sentinel.next;
    while (current != _sentinel) {
      final next = current!.next;

      if (current.function == null) {
        current.prev!.next = current.next;
        current.next!.prev = current.prev;
      } else {
        current.function!(current);
      }

      current = next;
    }
  }

  Iterable<Thinker> get all sync* {
    var current = _sentinel.next;
    while (current != _sentinel) {
      yield current!;
      current = current.next;
    }
  }
}
