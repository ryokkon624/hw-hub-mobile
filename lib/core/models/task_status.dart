enum TaskStatus {
  notDone('0'),
  done('1'),
  skipped('9');

  const TaskStatus(this.code);
  final String code;

  static TaskStatus? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
