/// Uma tarefa combinada para o serviço.
class JobTask {
  JobTask({required this.title, this.done = false});

  final String title;
  bool done;
}

/// Quanto do serviço já foi entregue.
///
/// O número não é digitado por ninguém: ou sai das tarefas concluídas, ou do
/// calendário combinado. Deixar o profissional escolher a porcentagem à mão
/// transformava a barra numa opinião — e quem contratou não tem como conferir
/// uma opinião.
class JobProgress {
  const JobProgress._();

  /// Tarefas combinadas com o cliente, na ordem de execução.
  static final List<JobTask> tasks = [
    JobTask(title: 'Quebrar parede e localizar vazamento', done: true),
    JobTask(title: 'Substituir encanamento danificado', done: true),
    JobTask(title: 'Aplicar massa e reboco'),
    JobTask(title: 'Pintura e acabamento final'),
  ];

  /// Janela combinada para o serviço.
  static final DateTime startDate = DateTime.now().subtract(
    const Duration(days: 3),
  );
  static final DateTime endDate = DateTime.now().add(const Duration(days: 2));

  static double get value =>
      compute(tasks: tasks, start: startDate, end: endDate);

  /// Quantas tarefas já foram concluídas.
  static int get doneCount => tasks.where((task) => task.done).length;

  /// Calcula o andamento.
  ///
  /// Com tarefas combinadas, o progresso é a fração concluída — é o que o
  /// cliente consegue verificar item a item. Sem tarefas, resta o prazo: o
  /// serviço caminha junto com o calendário, do início até a entrega.
  static double compute({
    required List<JobTask> tasks,
    required DateTime start,
    required DateTime end,
    DateTime? now,
  }) {
    if (tasks.isNotEmpty) {
      final done = tasks.where((task) => task.done).length;
      return done / tasks.length;
    }

    final moment = now ?? DateTime.now();
    final total = end.difference(start).inMinutes;

    // Serviço de um dia só, ou datas invertidas: nada a interpolar.
    if (total <= 0) return moment.isBefore(end) ? 0 : 1;

    final elapsed = moment.difference(start).inMinutes;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
