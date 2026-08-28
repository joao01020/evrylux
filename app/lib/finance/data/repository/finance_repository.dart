import '../../../../core/storage/storage_service.dart';

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

class FinanceRepository {
  Future<Map<String, dynamic>> load() async {
    return await StorageService.getFinance();
  }

  Future<void> save(Map<String, dynamic> data) async {
    await StorageService.saveFinance(data);
  }
}
