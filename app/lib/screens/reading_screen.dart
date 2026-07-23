import 'package:flutter/material.dart';

import '../widgets/week_tracker.dart';
import '../widgets/progress_bar.dart';

class ReadingScreen
    extends
        StatefulWidget {
  const ReadingScreen({
    super.key,
  });

  @override
  State<
    ReadingScreen
  >
  createState() => _ReadingScreenState();
}

class _ReadingScreenState
    extends
        State<
          ReadingScreen
        > {
  List<
    bool
  >
  completedDays = [
    false,

    false,

    false,

    false,

    false,

    false,

    false,
  ];

  int pagesRead = 0;

  int totalPages = 0;

  int streak = 0;

  String book = "Nenhum livro selecionado";

  final TextEditingController bookController = TextEditingController();

  final TextEditingController pagesController = TextEditingController();

  void toggleDay(
    int index,
  ) {
    setState(
      () {
        completedDays[index] = !completedDays[index];

        streak = completedDays
            .where(
              (
                day,
              ) => day,
            )
            .length;
      },
    );
  }

  void addPages() {
    if (totalPages ==
        0) {
      return;
    }

    setState(
      () {
        if (pagesRead <
            totalPages) {
          pagesRead += 5;
        }

        if (pagesRead >
            totalPages) {
          pagesRead = totalPages;
        }
      },
    );
  }

  void saveBook() {
    if (bookController.text.isEmpty ||
        pagesController.text.isEmpty) {
      return;
    }

    setState(
      () {
        book = bookController.text;

        totalPages =
            int.tryParse(
              pagesController.text,
            ) ??
            0;

        pagesRead = 0;

        bookController.clear();

        pagesController.clear();
      },
    );
  }

  @override
  void dispose() {
    bookController.dispose();

    pagesController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Leitura 📖",
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(
            24,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "Sua evolução através dos livros.",

                style: TextStyle(
                  fontSize: 28,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                "Cada página é um passo na sua evolução.",

                style: TextStyle(
                  fontSize: 18,
                ),
              ),

              const SizedBox(
                height: 35,
              ),

              WeekTracker(
                completedDays: completedDays,

                onDayTap: toggleDay,
              ),

              const SizedBox(
                height: 30,
              ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(
                    16,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "📘 Livro atual",

                        style: TextStyle(
                          fontSize: 18,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      TextField(
                        controller: bookController,

                        decoration: const InputDecoration(
                          labelText: "Nome do livro",
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      TextField(
                        controller: pagesController,

                        keyboardType: TextInputType.number,

                        decoration: const InputDecoration(
                          labelText: "Quantidade de páginas",
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton(
                          onPressed: saveBook,

                          child: const Text(
                            "Salvar livro",
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      Text(
                        book,

                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              Card(
                child: ListTile(
                  leading: const Text(
                    "📄",

                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),

                  title: const Text(
                    "Páginas lidas",

                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    "$pagesRead / $totalPages páginas",
                  ),

                  trailing: IconButton(
                    icon: const Icon(
                      Icons.add,
                    ),

                    onPressed: addPages,
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              ProgressBar(
                title: "Progresso do livro",

                current: pagesRead.toDouble(),

                goal:
                    totalPages ==
                        0
                    ? 1
                    : totalPages.toDouble(),
              ),

              const SizedBox(
                height: 25,
              ),

              Card(
                child: ListTile(
                  leading: const Text(
                    "🔥",

                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),

                  title: const Text(
                    "Sequência",

                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    "$streak dias lendo",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
