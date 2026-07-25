import '../../core/storage/storage_service.dart';

/*

|
| Screen
|    ↓
| Controller
|    ↓
| Service
|    ↓
| Repository
|    ↓
| StorageService
|
| Cada camada recebe apenas a dependência da camada abaixo.
| Assim toda a aplicação utiliza uma única instância dos serviços,
| facilitando manutenção, testes e evolução do projeto.

*/

class TrainingRepository {
  // ==========================================
  // CARREGAR TREINOS
  // ==========================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  load() async {
    return await StorageService.getTraining();
  }

  // ==========================================
  // SALVAR TREINO
  // ==========================================

  Future<
    void
  >
  save({
    required String day,

    required String training,

    required int minutes,
  }) async {
    await StorageService.saveTraining(
      day,

      training,

      minutes,
    );
  }

  // ==========================================
  // LIMPAR DADOS ANTIGOS
  // ==========================================

  Future<
    void
  >
  clear() async {
    await StorageService.clearTraining();
  }
}
