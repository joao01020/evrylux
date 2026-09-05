part of '../../profile_settings_page.dart';

extension _ProfileSettingsAboutSection
    on
        _ProfileSettingsPageState {
  // ============================================================
  // ABOUT
  // ============================================================

  Widget _buildAbout() {
    return _SettingsPanel(
      icon: Icons.info_outline_rounded,
      title: 'Sobre',
      subtitle: 'Conheça a ideia por trás do EVRYLUX.',
      children: [
        // ======================================================
        // ABOUT HERO / BRANDING
        // ======================================================
        //
        // A logo oficial do EVRYLUX é renderizada pelo
        // widget _AboutHero, definido em:
        //
        // settings/widgets/profile_settings_widgets.dart
        //
        // Asset utilizado:
        //
        // assets/images/branding/evrylux_logo.png
        //
        // ======================================================
        const _AboutHero(),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // SOBRE O EVRYLUX
        // ======================================================
        _AboutActionRow(
          icon: Icons.auto_awesome_outlined,
          title: 'O que é o EVRYLUX?',
          subtitle: 'Uma forma mais prática de guardar, encontrar e revisar o que você aprende.',
          onTap: () {
            _showAboutInfoDialog(
              title: 'Sobre o EVRYLUX',
              icon: Icons.auto_awesome_outlined,
              content:
                  'Na internet, muitas vezes pesquisamos a mesma coisa várias vezes porque o que aprendemos acaba se perdendo.\n\n'
                  'No caderno, você até pode anotar tudo, mas com o tempo pode ficar difícil encontrar uma informação específica, revisar conteúdos antigos e manter suas anotações organizadas.\n\n'
                  'No EVRYLUX, seus estudos ficam no seu Cérebro: você adiciona o que aprendeu e, quando precisar, pesquisa dentro do seu próprio conhecimento como se tivesse um Google pessoal das suas anotações.\n\n'
                  'Você também pode revisar seus arquivos e acompanhar sua evolução nos estudos.\n\n'
                  'Assim, você não precisa começar do zero sempre que quiser lembrar de algo.',
            );
          },
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // VISÃO
        // ======================================================
        _AboutActionRow(
          icon: Icons.psychology_alt_outlined,
          title: 'A visão',
          subtitle: 'Conhecimento que continua com você.',
          onTap: () {
            _showAboutInfoDialog(
              title: 'A visão do EVRYLUX',
              icon: Icons.psychology_alt_outlined,
              content:
                  'A proposta do EVRYLUX é transformar o estudo em algo acumulativo.\n\n'
                  'Em vez de pesquisar, esquecer e precisar procurar tudo novamente, você constrói uma base própria de conhecimento ao longo do tempo.\n\n'
                  'Quanto mais você aprende e registra, mais útil o seu Cérebro se torna para consultas, revisões e continuidade dos seus estudos.',
            );
          },
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // CÉREBRO EVRYLUX
        // ======================================================
        _AboutActionRow(
          icon: Icons.hub_outlined,
          title: 'Seu Cérebro',
          subtitle: 'Seu próprio sistema de pesquisa para tudo o que você já aprendeu.',
          onTap: () {
            _showAboutInfoDialog(
              title: 'Seu Cérebro no EVRYLUX',
              icon: Icons.hub_outlined,
              content:
                  'O Cérebro reúne o conhecimento que você adiciona durante seus estudos.\n\n'
                  'Em vez de procurar página por página em um caderno ou refazer uma pesquisa na internet, você pode buscar diretamente no seu próprio conteúdo.\n\n'
                  'A ideia é funcionar como um Google pessoal: você pergunta ao seu Cérebro e encontra aquilo que já estudou, junto com seus arquivos, anotações, perguntas e revisões.\n\n'
                  'Quanto mais você registra, mais útil essa base se torna.',
            );
          },
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // PRIVACIDADE
        // ======================================================
        _AboutActionRow(
          icon: Icons.lock_outline_rounded,
          title: 'Seus dados, suas escolhas',
          subtitle: 'Controle sobre como o seu Cérebro é protegido.',
          onTap: () {
            _showAboutInfoDialog(
              title: 'Seus dados, suas escolhas',
              icon: Icons.lock_outline_rounded,
              content:
                  'O EVRYLUX foi pensado para que seus dados continuem sob seu controle.\n\n'
                  'Você pode utilizar o Cérebro apenas localmente, mantendo o conteúdo neste dispositivo, ou utilizar a proteção em nuvem disponível no aplicativo.\n\n'
                  'A forma como o seu conhecimento é armazenado e protegido continua sendo uma escolha sua.',
            );
          },
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // POLÍTICA DE PRIVACIDADE
        // ======================================================
        _AboutActionRow(
          icon: Icons.privacy_tip_outlined,
          title: 'Política de privacidade',
          subtitle: 'Veja como seus dados são tratados.',
          onTap: () {
            Navigator.of(
              context,
            ).push(
              MaterialPageRoute(
                builder:
                    (
                      _,
                    ) {
                      return const PrivacyPolicyPage();
                    },
              ),
            );
          },
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // TERMOS DE USO
        // ======================================================
        _AboutActionRow(
          icon: Icons.description_outlined,
          title: 'Termos de uso',
          subtitle: 'Consulte os termos de utilização do aplicativo.',
          onTap: () {
            Navigator.of(
              context,
            ).push(
              MaterialPageRoute(
                builder:
                    (
                      _,
                    ) {
                      return const TermsOfUsePage();
                    },
              ),
            );
          },
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // LICENÇAS
        // ======================================================
        _AboutActionRow(
          icon: Icons.article_outlined,
          title: 'Licenças',
          subtitle: 'Bibliotecas e licenças utilizadas pelo aplicativo.',
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: AppInfo.name,
              applicationVersion: AppInfo.version,
              applicationLegalese: 'Desenvolvido por João Vitor',
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // ABOUT INFO DIALOG
  // ============================================================

  Future<
    void
  >
  _showAboutInfoDialog({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return showDialog<
      void
    >(
      context: context,
      builder:
          (
            dialogContext,
          ) {
            return AlertDialog(
              backgroundColor: _ProfileSettingsPageState._surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  20,
                ),
                side: const BorderSide(
                  color: _ProfileSettingsPageState._border,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _ProfileSettingsPageState._primary,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: _ProfileSettingsPageState._primaryDark,
                      size: 20,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: _ProfileSettingsPageState._muted,
                      height: 1.6,
                    ),
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Fechar',
                  ),
                ),
              ],
            );
          },
    );
  }
}
