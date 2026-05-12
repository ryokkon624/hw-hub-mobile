enum TaskRecalcStatus {
  pending('0'),
  processing('1'),
  done('2'),
  failed('9');

  const TaskRecalcStatus(this.code);
  final String code;

  static TaskRecalcStatus? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
