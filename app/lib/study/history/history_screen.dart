import 'package:flutter/material.dart';

import '../../core/storage/storage_service.dart';

class HistoryScreen
    extends
        StatefulWidget {
  const HistoryScreen({
    super.key,
  });

  @override
  State<
    HistoryScreen
  >
  createState() => _HistoryScreenState();
}

class _HistoryScreenState
    extends
        State<
          HistoryScreen
        > {
  final List<
    String
  >
  studies = [];

  @override
  void initState() {
    super.initState();

    loadHistory();
  }

  Future<
    void
  >
  loadHistory() async {
    final data = await StorageService.getStudy();

    final List<
      String
    >
    history = [];

    data.forEach(
      (
        key,
        value,
      ) {
        history.add(
          "$key - $value minutos",
        );
      },
    );

    if (!mounted) return;

    setState(
      () {
        studies.clear();

        studies.addAll(
          history,
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Histórico 📚",
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(
          24,
        ),

        child: studies.isEmpty
            ? const Center(
                child: Text(
                  "Nenhum estudo registrado ainda.",

                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: studies.length,

                itemBuilder:
                    (
                      context,
                      index,
                    ) {
                      return Card(
                        child: ListTile(
                          leading: const Text(
                            "✅",
                            style: TextStyle(
                              fontSize: 28,
                            ),
                          ),

                          title: Text(
                            studies[index],
                          ),

                          subtitle: const Text(
                            "Estudo concluído",
                          ),
                        ),
                      );
                    },
              ),
      ),
    );
  }
}
