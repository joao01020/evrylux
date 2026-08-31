import 'package:flutter/material.dart';

// ============================================================
// PRIVACY POLICY PAGE
// ============================================================
//
// Política de Privacidade do EVRYLUX.
//
// Observação:
// Este texto funciona como uma base completa para o aplicativo.
// Antes de publicar comercialmente, é recomendável revisar o
// conteúdo com um profissional jurídico e preencher os canais
// oficiais de contato.
//
// ============================================================

class PrivacyPolicyPage
    extends
        StatelessWidget {
  const PrivacyPolicyPage({
    super.key,
  });

  static const String _lastUpdated = '31 de agosto de 2026';

  @override
  Widget build(
    BuildContext context,
  ) {
    return const _LegalDocumentPage(
      title: 'Política de Privacidade',
      subtitle: 'Como o EVRYLUX coleta, usa, protege e trata seus dados.',
      icon: Icons.privacy_tip_outlined,
      lastUpdated: _lastUpdated,
      sections: [
        _LegalSection(
          title: '1. Sobre esta Política',
          paragraphs: [
            'Esta Política de Privacidade descreve como o EVRYLUX trata informações relacionadas ao uso do aplicativo, incluindo dados de conta, preferências, registros pessoais e informações geradas pelas funcionalidades disponíveis.',
            'Ao utilizar o EVRYLUX, você declara estar ciente das práticas descritas nesta Política.',
          ],
        ),
        _LegalSection(
          title: '2. Dados que podemos tratar',
          paragraphs: [
            'Dependendo das funcionalidades utilizadas, o EVRYLUX pode tratar dados como nome, endereço de e-mail, identificador da conta, preferências do aplicativo e informações de perfil.',
            'Também podem ser armazenados dados inseridos voluntariamente por você nas áreas de estudos, treinos, rotina, evolução, finanças, lembretes e demais recursos do aplicativo.',
            'Algumas informações podem permanecer armazenadas localmente no dispositivo para permitir funcionamento offline e sincronização posterior.',
          ],
        ),
        _LegalSection(
          title: '3. Finalidades do tratamento',
          paragraphs: [
            'Os dados são utilizados para autenticar sua conta, permitir o funcionamento das funcionalidades, manter seus registros, sincronizar informações entre sessões e dispositivos quando aplicável, personalizar preferências e melhorar a experiência de uso.',
            'Também podemos utilizar informações técnicas estritamente necessárias para segurança, prevenção de falhas, diagnóstico e manutenção do aplicativo.',
          ],
        ),
        _LegalSection(
          title: '4. Armazenamento local e sincronização',
          paragraphs: [
            'O EVRYLUX pode armazenar dados localmente no dispositivo para oferecer uma experiência offline-first. Alterações realizadas sem conexão podem ser mantidas localmente e sincronizadas quando a conexão estiver disponível.',
            'Ao remover o aplicativo ou limpar seus dados locais, informações que ainda não tenham sido sincronizadas podem ser perdidas.',
          ],
        ),
        _LegalSection(
          title: '5. Serviços de terceiros',
          paragraphs: [
            'O EVRYLUX pode utilizar serviços de terceiros para autenticação, banco de dados, sincronização, notificações e infraestrutura técnica.',
            'Atualmente, partes da infraestrutura podem utilizar Supabase para autenticação e armazenamento remoto. Quando recursos de notificação externa forem ativados, integrações como Telegram também poderão ser utilizadas de acordo com a configuração do usuário.',
            'Esses serviços possuem suas próprias políticas, termos e práticas de segurança.',
          ],
        ),
        _LegalSection(
          title: '6. Compartilhamento de dados',
          paragraphs: [
            'O EVRYLUX não vende seus dados pessoais.',
            'Informações podem ser compartilhadas apenas quando necessário para operar serviços contratados, cumprir obrigações legais, proteger direitos, prevenir abuso ou executar funcionalidades solicitadas pelo próprio usuário.',
          ],
        ),
        _LegalSection(
          title: '7. Segurança',
          paragraphs: [
            'São adotadas medidas razoáveis de segurança para reduzir riscos de acesso não autorizado, alteração, perda ou divulgação indevida.',
            'Apesar dos esforços de proteção, nenhum sistema conectado à internet pode garantir segurança absoluta. Por isso, recomendamos manter sua senha protegida e utilizar dispositivos confiáveis.',
          ],
        ),
        _LegalSection(
          title: '8. Senha e autenticação',
          paragraphs: [
            'Sua senha é gerenciada pelo sistema de autenticação utilizado pelo EVRYLUX e não deve ser compartilhada com terceiros.',
            'Você é responsável por manter a confidencialidade das credenciais de acesso e por comunicar imediatamente qualquer suspeita de uso indevido da conta.',
          ],
        ),
        _LegalSection(
          title: '9. Retenção e exclusão',
          paragraphs: [
            'Os dados podem ser mantidos enquanto sua conta estiver ativa ou enquanto forem necessários para fornecer as funcionalidades utilizadas.',
            'Quando aplicável, você poderá solicitar correção, atualização ou exclusão de informações. Dados mantidos apenas localmente também podem ser removidos ao apagar registros ou dados do aplicativo.',
          ],
        ),
        _LegalSection(
          title: '10. Direitos do usuário',
          paragraphs: [
            'Você pode solicitar informações sobre os dados tratados, correção de dados incompletos ou incorretos, exclusão quando aplicável e esclarecimentos sobre o uso das suas informações.',
            'Direitos específicos podem variar conforme a legislação aplicável, inclusive a Lei Geral de Proteção de Dados Pessoais (LGPD) no Brasil.',
          ],
        ),
        _LegalSection(
          title: '11. Dados financeiros e de saúde',
          paragraphs: [
            'Informações registradas nas áreas de finanças, treino, hábitos ou evolução são destinadas à organização pessoal do usuário.',
            'O EVRYLUX não substitui aconselhamento médico, psicológico, financeiro, contábil ou profissional. O usuário permanece responsável pelas decisões tomadas com base nos próprios registros.',
          ],
        ),
        _LegalSection(
          title: '12. Alterações nesta Política',
          paragraphs: [
            'Esta Política poderá ser atualizada para refletir mudanças no aplicativo, na legislação ou nos serviços utilizados.',
            'Quando houver alterações relevantes, a data de atualização será modificada e, quando apropriado, o usuário poderá ser informado dentro do aplicativo.',
          ],
        ),
        _LegalSection(
          title: '13. Contato',
          paragraphs: [
            'Para dúvidas, solicitações relacionadas à privacidade ou exercício de direitos, utilize o canal oficial de suporte do EVRYLUX.',
            'Antes da publicação pública do aplicativo, inclua aqui o e-mail ou endereço oficial destinado a assuntos de privacidade.',
          ],
        ),
      ],
    );
  }
}

// ============================================================
// LEGAL DOCUMENT PAGE
// ============================================================

class _LegalDocumentPage
    extends
        StatelessWidget {
  const _LegalDocumentPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String lastUpdated;
  final List<
    _LegalSection
  >
  sections;

  static const Color _background = Color(
    0xFFF7FBF1,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _surfaceSoft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24,
                20,
                24,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      22,
                    ),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(
                        22,
                      ),
                      border: Border.all(
                        color: _border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(
                              16,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: _primaryDark,
                            size: 27,
                          ),
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: _text,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                'Última atualização: $lastUpdated',
                                style: const TextStyle(
                                  color: _primaryDark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      22,
                    ),
                    decoration: BoxDecoration(
                      color: _surfaceSoft,
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                      border: Border.all(
                        color: _border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (
                          var i = 0;
                          i <
                              sections.length;
                          i++
                        ) ...[
                          Text(
                            sections[i].title,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          for (final paragraph in sections[i].paragraphs) ...[
                            Text(
                              paragraph,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(
                              height: 9,
                            ),
                          ],
                          if (i !=
                              sections.length -
                                  1)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              child: Divider(
                                color: _border,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection({
    required this.title,
    required this.paragraphs,
  });

  final String title;
  final List<
    String
  >
  paragraphs;
}
