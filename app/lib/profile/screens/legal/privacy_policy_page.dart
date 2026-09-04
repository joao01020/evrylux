import 'package:flutter/material.dart';

// ============================================================
// PRIVACY POLICY PAGE
// ============================================================
//
// Política de Privacidade do EVRYLUX.
//
// Este documento foi estruturado para refletir práticas comuns
// de aplicativos modernos, com linguagem clara, seções objetivas
// e transparência sobre armazenamento local, sincronização,
// dispositivos, segurança e Cérebro com E2EE.
//
// Antes de publicação comercial em larga escala, recomenda-se
// revisão jurídica e inclusão do canal oficial de privacidade.
//
// ============================================================

class PrivacyPolicyPage
    extends
        StatelessWidget {
  const PrivacyPolicyPage({
    super.key,
  });

  static const String _lastUpdated = '4 de setembro de 2026';

  @override
  Widget build(
    BuildContext context,
  ) {
    return const _LegalDocumentPage(
      title: 'Política de Privacidade',
      subtitle: 'Como o EVRYLUX coleta, utiliza, armazena, protege e permite que você controle seus dados.',
      icon: Icons.privacy_tip_outlined,
      lastUpdated: _lastUpdated,
      sections: [
        _LegalSection(
          title: '1. Visão geral',
          paragraphs: [
            'Esta Política de Privacidade explica como o EVRYLUX trata informações relacionadas ao uso do aplicativo, incluindo dados de conta, preferências, registros pessoais, informações técnicas e conteúdo inserido pelo próprio usuário.',
            'Nosso objetivo é tratar apenas os dados necessários para fornecer, proteger e melhorar as funcionalidades do EVRYLUX, respeitando a legislação aplicável e oferecendo mecanismos de controle ao usuário.',
          ],
        ),
        _LegalSection(
          title: '2. Dados que podem ser tratados',
          paragraphs: [
            'Dependendo das funcionalidades utilizadas, o EVRYLUX pode tratar dados de cadastro e conta, como nome, e-mail, identificador interno do usuário, preferências e informações relacionadas à autenticação.',
            'Também podem ser tratados dados inseridos voluntariamente pelo usuário em áreas como estudos, rotina, treino, finanças, lembretes, progresso, organização pessoal e demais recursos disponíveis no aplicativo.',
            'O aplicativo também pode tratar informações técnicas necessárias para funcionamento e segurança, como identificadores de dispositivo e sessão, plataforma, versão do aplicativo, horários de atividade e status de sincronização.',
          ],
        ),
        _LegalSection(
          title: '3. Dados armazenados localmente',
          paragraphs: [
            'O EVRYLUX utiliza uma arquitetura local-first em diversas funcionalidades. Isso significa que determinados dados podem ser armazenados primeiro no próprio dispositivo para permitir uso rápido, continuidade offline e sincronização posterior.',
            'Enquanto uma alteração ainda não tiver sido sincronizada, ela poderá existir somente no dispositivo. A remoção do aplicativo, limpeza manual de dados locais, perda do dispositivo ou falhas de armazenamento podem causar perda de informações que ainda não tenham sido enviadas ao serviço remoto.',
          ],
        ),
        _LegalSection(
          title: '4. Cérebro, criptografia e dados protegidos',
          paragraphs: [
            'Recursos do Cérebro podem utilizar criptografia ponta a ponta para proteger conteúdo sensível. Quando esse modo estiver ativo, o conteúdo protegido é criptografado antes do armazenamento remoto e depende das chaves autorizadas do próprio usuário para ser recuperado.',
            'O EVRYLUX pode armazenar metadados técnicos necessários ao funcionamento desses recursos, como identificadores de Vault, versões de chave, dispositivos autorizados, solicitações de recuperação e informações de sincronização.',
            'Backups .evbrain exportados pelo usuário permanecem sob responsabilidade do próprio usuário no local em que forem salvos. A exclusão da conta ou dos dados do aplicativo não remove automaticamente cópias externas que estejam fora do controle do EVRYLUX.',
          ],
        ),
        _LegalSection(
          title: '5. Como utilizamos os dados',
          paragraphs: [
            'Os dados podem ser utilizados para autenticar sua conta, disponibilizar recursos do aplicativo, salvar e sincronizar informações, manter preferências, permitir funcionamento offline, gerenciar dispositivos e sessões, proteger sua conta e viabilizar recuperação de funcionalidades quando disponível.',
            'Informações técnicas também podem ser utilizadas para segurança, prevenção de abuso, diagnóstico de falhas, estabilidade, compatibilidade e manutenção do serviço.',
            'O EVRYLUX não utiliza seus dados pessoais para venda a terceiros.',
          ],
        ),
        _LegalSection(
          title: '6. Bases legais e fundamento do tratamento',
          paragraphs: [
            'Quando a legislação exigir uma base legal específica, o tratamento poderá ocorrer, conforme aplicável, para execução do serviço solicitado pelo usuário, cumprimento de obrigação legal ou regulatória, exercício regular de direitos, proteção da segurança do serviço, interesse legítimo compatível com os direitos do usuário ou mediante consentimento quando necessário.',
            'A base aplicável depende da natureza do dado, da funcionalidade utilizada e da legislação vigente no local do usuário.',
          ],
        ),
        _LegalSection(
          title: '7. Serviços de terceiros e operadores',
          paragraphs: [
            'O EVRYLUX pode utilizar prestadores de infraestrutura para autenticação, banco de dados, armazenamento, sincronização, hospedagem, notificações e serviços técnicos necessários ao funcionamento do aplicativo.',
            'Atualmente, partes da infraestrutura podem utilizar Supabase para autenticação, banco de dados e serviços relacionados. Esses prestadores processam dados de acordo com seus próprios termos, políticas e medidas de segurança.',
            'Quando uma integração externa for ativada voluntariamente pelo usuário, apenas os dados necessários para executar a funcionalidade poderão ser enviados ao respectivo serviço.',
          ],
        ),
        _LegalSection(
          title: '8. Compartilhamento de dados',
          paragraphs: [
            'O EVRYLUX não vende dados pessoais.',
            'Dados podem ser compartilhados com prestadores técnicos quando isso for necessário para operar o serviço, atender solicitações do usuário, cumprir obrigações legais, responder a autoridades competentes, proteger direitos, investigar abuso ou preservar a segurança da plataforma.',
            'Sempre que possível, o compartilhamento é limitado ao mínimo necessário para a finalidade correspondente.',
          ],
        ),
        _LegalSection(
          title: '9. Transferências e localização do processamento',
          paragraphs: [
            'Alguns prestadores de infraestrutura podem processar ou armazenar informações em servidores localizados fora do país do usuário.',
            'Quando aplicável, essas operações devem observar os mecanismos permitidos pela legislação de proteção de dados e as salvaguardas adotadas pelos respectivos prestadores.',
          ],
        ),
        _LegalSection(
          title: '10. Sessões e dispositivos',
          paragraphs: [
            'Para segurança da conta, o EVRYLUX pode registrar informações sobre dispositivos e sessões autenticadas, incluindo identificador de dispositivo, identificador de sessão, plataforma, versão do aplicativo e última atividade.',
            'Essas informações podem ser utilizadas para exibir dispositivos conectados, identificar a sessão atual e permitir o encerramento de sessões quando esse recurso estiver disponível.',
          ],
        ),
        _LegalSection(
          title: '11. Segurança',
          paragraphs: [
            'O EVRYLUX adota medidas técnicas e organizacionais destinadas a reduzir riscos de acesso não autorizado, alteração, destruição, perda ou divulgação indevida de dados.',
            'Entre essas medidas podem estar autenticação, controle de acesso, políticas de segurança no banco de dados, armazenamento local protegido, criptografia e mecanismos de autorização de dispositivos.',
            'Nenhum sistema conectado à internet pode garantir segurança absoluta. Por isso, recomendamos utilizar senha forte, proteger o dispositivo, manter o aplicativo atualizado e não aprovar dispositivos ou recuperações que você não reconheça.',
          ],
        ),
        _LegalSection(
          title: '12. Senha e autenticação',
          paragraphs: [
            'As credenciais de acesso são tratadas pelo sistema de autenticação utilizado pelo EVRYLUX. O aplicativo não deve armazenar sua senha atual em texto legível como parte dos dados de perfil.',
            'Em ações sensíveis, como alteração de senha, exclusão de dados ou exclusão de conta, o EVRYLUX pode solicitar nova confirmação da identidade antes de prosseguir.',
          ],
        ),
        _LegalSection(
          title: '13. Retenção de dados',
          paragraphs: [
            'Os dados podem ser mantidos enquanto a conta permanecer ativa ou enquanto forem necessários para fornecer as funcionalidades utilizadas, cumprir obrigações legais, resolver disputas, prevenir fraude ou manter a segurança do serviço.',
            'Os prazos podem variar conforme a categoria do dado e a finalidade do tratamento. Dados locais podem permanecer no dispositivo até serem removidos pelo usuário, pelo aplicativo ou pelo sistema operacional.',
          ],
        ),
        _LegalSection(
          title: '14. Exclusão de dados e conta',
          paragraphs: [
            'O usuário pode utilizar os controles disponíveis no EVRYLUX para excluir dados associados ao aplicativo ou excluir permanentemente a conta, quando essas funcionalidades estiverem disponíveis.',
            'Ao excluir apenas os dados, a conta de autenticação poderá permanecer ativa. Ao excluir a conta, os dados associados e o acesso à conta serão removidos de acordo com o fluxo de exclusão aplicável.',
            'Algumas informações poderão ser retidas quando houver obrigação legal, necessidade de segurança, prevenção de fraude ou outra hipótese permitida pela legislação. Cópias externas criadas pelo próprio usuário, como arquivos .evbrain, não são apagadas automaticamente.',
          ],
        ),
        _LegalSection(
          title: '15. Direitos do usuário',
          paragraphs: [
            'Conforme a legislação aplicável, incluindo a Lei Geral de Proteção de Dados Pessoais (LGPD) no Brasil, o usuário pode ter direitos relacionados à confirmação de tratamento, acesso, correção, anonimização, portabilidade, informação sobre compartilhamento, oposição, revogação de consentimento e exclusão de dados quando cabível.',
            'Solicitações podem exigir verificação de identidade para proteger a conta e impedir acesso indevido a informações pessoais.',
          ],
        ),
        _LegalSection(
          title: '16. Dados financeiros, treino e bem-estar',
          paragraphs: [
            'Informações registradas em áreas de finanças, treino, hábitos, rotina ou evolução são destinadas à organização pessoal do usuário.',
            'O EVRYLUX não substitui orientação médica, psicológica, nutricional, financeira, contábil, jurídica ou profissional. O usuário permanece responsável pelas decisões tomadas com base nos próprios registros e objetivos.',
          ],
        ),
        _LegalSection(
          title: '17. Alterações desta Política',
          paragraphs: [
            'Esta Política poderá ser atualizada para refletir mudanças no EVRYLUX, na legislação, em práticas de segurança ou nos serviços utilizados.',
            'Quando houver alterações relevantes, a data de atualização será modificada e, quando apropriado, o usuário poderá ser informado dentro do aplicativo ou por outro canal adequado.',
          ],
        ),
        _LegalSection(
          title: '18. Contato e solicitações de privacidade',
          paragraphs: [
            'Para dúvidas, solicitações relacionadas à privacidade ou exercício de direitos, utilize o canal oficial de suporte ou privacidade informado pelo EVRYLUX.',
            'Antes da publicação pública do aplicativo, o responsável pelo serviço deve incluir nesta seção um canal oficial e verificável de contato para assuntos de privacidade.',
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
              maxWidth: 920,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                  height: 1.45,
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
                                height: 1.6,
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
