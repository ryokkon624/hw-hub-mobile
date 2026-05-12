enum TaskAssignReason {
  selfAssigned('0'),
  byRequest('1'),
  forced('2'),
  systemAssigned('9');

  const TaskAssignReason(this.code);
  final String code;

  static TaskAssignReason? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
