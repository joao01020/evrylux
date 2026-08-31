import 'package:flutter/material.dart';

// ============================================================
// TERMS OF USE PAGE
// ============================================================
//
// Termos de Uso do EVRYLUX.
//
// Observação:
// Este texto funciona como uma base completa para o aplicativo.
// Antes de publicar comercialmente, é recomendável revisar o
// conteúdo com um profissional jurídico.
//
// ============================================================

class TermsOfUsePage
    extends
        StatelessWidget {
  const TermsOfUsePage({
    super.key,
  });

  static const String _lastUpdated = '31 de agosto de 2026';

  @override
  Widget build(
    BuildContext context,
  ) {
    return const _LegalDocumentPage(
      title: 'Termos de Uso',
      subtitle: 'Regras e condições para utilização do EVRYLUX.',
      icon: Icons.description_outlined,
      lastUpdated: _lastUpdated,
      sections: [
        _LegalSection(
          title: '1. Aceitação dos Termos',
          paragraphs: [
            'Ao acessar ou utilizar o EVRYLUX, você concorda com estes Termos de Uso e com a Política de Privacidade aplicável.',
            'Caso não concorde com alguma condição, você deve interromper o uso do aplicativo.',
          ],
        ),
        _LegalSection(
          title: '2. Finalidade do aplicativo',
          paragraphs: [
            'O EVRYLUX é uma plataforma de organização e evolução pessoal que pode oferecer recursos relacionados a estudos, treino, rotina, finanças, progresso, lembretes e outras áreas de acompanhamento individual.',
            'As funcionalidades podem ser adicionadas, modificadas, limitadas ou removidas ao longo do desenvolvimento do produto.',
          ],
        ),
        _LegalSection(
          title: '3. Cadastro e conta',
          paragraphs: [
            'Algumas funcionalidades exigem criação de conta e autenticação.',
            'Você deve fornecer informações verdadeiras e manter seus dados de acesso protegidos. A conta é pessoal e não deve ser compartilhada de forma que comprometa sua segurança.',
          ],
        ),
        _LegalSection(
          title: '4. Uso permitido',
          paragraphs: [
            'Você concorda em utilizar o EVRYLUX apenas para finalidades lícitas e de acordo com estes Termos.',
            'É proibido tentar obter acesso não autorizado a contas, sistemas, bancos de dados, infraestrutura ou funcionalidades internas do aplicativo.',
            'Também é proibido usar o serviço para fraude, abuso, violação de direitos de terceiros, distribuição de conteúdo ilegal ou qualquer atividade que comprometa a disponibilidade ou segurança da plataforma.',
          ],
        ),
        _LegalSection(
          title: '5. Conteúdo inserido pelo usuário',
          paragraphs: [
            'Você mantém a responsabilidade pelas informações, textos, registros e demais conteúdos que inserir no EVRYLUX.',
            'Ao utilizar recursos de sincronização, você autoriza o processamento técnico desses dados na medida necessária para fornecer o serviço.',
          ],
        ),
        _LegalSection(
          title: '6. Funcionamento offline e sincronização',
          paragraphs: [
            'Determinadas funcionalidades podem operar de forma offline e sincronizar alterações posteriormente.',
            'Conflitos de sincronização, falhas de conexão, remoção do aplicativo ou limpeza de dados locais podem afetar informações que ainda não tenham sido sincronizadas.',
            'Recomendamos manter o aplicativo atualizado e verificar o status de sincronização quando os dados forem importantes.',
          ],
        ),
        _LegalSection(
          title: '7. Recursos de treino, saúde e bem-estar',
          paragraphs: [
            'Informações relacionadas a treino, hábitos, evolução física ou bem-estar possuem finalidade organizacional e informativa.',
            'O EVRYLUX não fornece diagnóstico médico e não substitui orientação de médicos, nutricionistas, fisioterapeutas ou outros profissionais qualificados.',
            'Procure orientação profissional antes de iniciar atividades físicas ou alterar hábitos quando houver necessidade.',
          ],
        ),
        _LegalSection(
          title: '8. Recursos financeiros',
          paragraphs: [
            'Ferramentas de finanças são destinadas à organização pessoal e acompanhamento de informações fornecidas pelo usuário.',
            'O EVRYLUX não presta consultoria financeira, contábil, tributária ou de investimentos e não garante resultados financeiros.',
          ],
        ),
        _LegalSection(
          title: '9. Disponibilidade e alterações',
          paragraphs: [
            'Buscamos manter o aplicativo disponível e funcional, mas não garantimos funcionamento ininterrupto, ausência de falhas ou compatibilidade permanente com todos os dispositivos e sistemas.',
            'Atualizações podem alterar recursos, interface, requisitos técnicos e formas de armazenamento.',
          ],
        ),
        _LegalSection(
          title: '10. Serviços de terceiros',
          paragraphs: [
            'O funcionamento do EVRYLUX pode depender de serviços de terceiros, como autenticação, banco de dados, notificações, hospedagem e infraestrutura.',
            'Falhas, indisponibilidades ou mudanças nesses serviços podem afetar temporariamente determinadas funcionalidades.',
          ],
        ),
        _LegalSection(
          title: '11. Propriedade intelectual',
          paragraphs: [
            'O nome EVRYLUX, identidade visual, interface, código, textos próprios, estrutura e demais elementos do aplicativo são protegidos pelas leis aplicáveis, salvo componentes de terceiros sujeitos às respectivas licenças.',
            'Estes Termos não transferem ao usuário qualquer direito de propriedade sobre o aplicativo.',
          ],
        ),
        _LegalSection(
          title: '12. Limitação de responsabilidade',
          paragraphs: [
            'O EVRYLUX é oferecido como ferramenta de organização pessoal. O usuário permanece responsável por suas decisões, registros, escolhas, metas e ações.',
            'Na medida permitida pela legislação aplicável, o desenvolvedor não será responsável por perdas indiretas decorrentes de decisões tomadas exclusivamente com base em informações inseridas ou apresentadas pelo aplicativo.',
          ],
        ),
        _LegalSection(
          title: '13. Suspensão ou encerramento',
          paragraphs: [
            'O acesso poderá ser limitado ou suspenso em situações de abuso, fraude, risco de segurança, violação destes Termos ou necessidade técnica.',
            'O usuário poderá deixar de utilizar o aplicativo a qualquer momento.',
          ],
        ),
        _LegalSection(
          title: '14. Alterações destes Termos',
          paragraphs: [
            'Estes Termos podem ser atualizados para refletir alterações no produto, na legislação ou nos serviços utilizados.',
            'A versão atualizada passará a valer a partir da data informada no próprio documento.',
          ],
        ),
        _LegalSection(
          title: '15. Legislação aplicável',
          paragraphs: [
            'Estes Termos serão interpretados de acordo com a legislação aplicável ao usuário e ao responsável pelo serviço, respeitando normas obrigatórias de proteção ao consumidor e de proteção de dados.',
          ],
        ),
        _LegalSection(
          title: '16. Contato',
          paragraphs: [
            'Dúvidas sobre estes Termos podem ser encaminhadas ao canal oficial de suporte do EVRYLUX.',
            'Antes da publicação pública do aplicativo, inclua aqui o e-mail ou endereço oficial de contato.',
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
