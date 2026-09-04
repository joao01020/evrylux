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
      subtitle: 'Informações sobre o EVRYLUX.',
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
          icon: Icons.info_outline_rounded,
          title: 'Sobre',
          subtitle: 'Conheça a proposta e a visão do EVRYLUX.',
          onTap: () {
            _showAboutInfoDialog(
              title: 'Sobre o EVRYLUX',
              icon: Icons.info_outline_rounded,
              content:
                  'EVRYLUX é uma plataforma de evolução pessoal criada para reunir, em um só lugar, áreas como estudos, treino, finanças, rotina e acompanhamento de progresso.\n\n'
                  'A proposta é ajudar você a organizar sua evolução de forma simples, visual e consistente.',
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
                  maxWidth: 440,
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    height: 1.5,
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
