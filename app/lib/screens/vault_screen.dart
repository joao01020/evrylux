import 'package:flutter/material.dart';

class VaultScreen
    extends
        StatefulWidget {
  const VaultScreen({
    super.key,
  });

  @override
  State<
    VaultScreen
  >
  createState() => _VaultScreenState();
}

class _VaultScreenState
    extends
        State<
          VaultScreen
        > {
  final List<
    Map<
      String,
      String
    >
  >
  passwords = [];

  void addPassword() {
    final nameController = TextEditingController();

    final userController = TextEditingController();

    final passwordController = TextEditingController();

    showDialog(
      context: context,

      builder:
          (
            context,
          ) {
            return AlertDialog(
              title: const Text(
                "Nova senha 🔐",
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  TextField(
                    controller: nameController,

                    decoration: const InputDecoration(
                      labelText: "Serviço",
                      hintText: "Google, Instagram...",
                    ),
                  ),

                  TextField(
                    controller: userController,

                    decoration: const InputDecoration(
                      labelText: "Usuário / Email",
                    ),
                  ),

                  TextField(
                    controller: passwordController,

                    obscureText: true,

                    decoration: const InputDecoration(
                      labelText: "Senha",
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  child: const Text(
                    "Cancelar",
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty ||
                        passwordController.text.isEmpty) {
                      return;
                    }

                    setState(
                      () {
                        passwords.add(
                          {
                            "name": nameController.text,

                            "user": userController.text,

                            "password": passwordController.text,
                          },
                        );
                      },
                    );

                    Navigator.pop(
                      context,
                    );
                  },

                  child: const Text(
                    "Salvar",
                  ),
                ),
              ],
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
          "Vault 🔑",
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: addPassword,

        child: const Icon(
          Icons.add,
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(
          20,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Seu cofre digital.",

              style: TextStyle(
                fontSize: 28,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              "Guarde suas senhas de forma organizada e protegida.",

              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.lock,
                  size: 35,
                ),

                title: const Text(
                  "Vault protegido",
                ),

                subtitle: const Text(
                  "Suas credenciais ficam armazenadas aqui.",
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Expanded(
              child: passwords.isEmpty
                  ? const Center(
                      child: Text(
                        "Nenhuma senha salva.",
                      ),
                    )
                  : ListView.builder(
                      itemCount: passwords.length,

                      itemBuilder:
                          (
                            context,
                            index,
                          ) {
                            final item = passwords[index];

                            bool visible = false;

                            return StatefulBuilder(
                              builder:
                                  (
                                    context,
                                    refresh,
                                  ) {
                                    return Card(
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.key,
                                        ),

                                        title: Text(
                                          item["name"]!,
                                        ),

                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,

                                          children: [
                                            Text(
                                              item["user"]!,
                                            ),

                                            Text(
                                              visible
                                                  ? item["password"]!
                                                  : "••••••••",
                                            ),
                                          ],
                                        ),

                                        trailing: IconButton(
                                          icon: Icon(
                                            visible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),

                                          onPressed: () {
                                            refresh(
                                              () {
                                                visible = !visible;
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                            );
                          },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
