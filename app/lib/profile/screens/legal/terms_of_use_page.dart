import 'package:flutter/material.dart';

// ============================================================
// TERMS OF USE PAGE
// ============================================================
//
// Termos de Uso do EVRYLUX.
//
// Estruturado em padrão semelhante ao utilizado por aplicativos
// modernos: conta, licença, conteúdo, recursos sensíveis,
// disponibilidade, serviços externos, exclusão e responsabilidade.
//
// Antes da publicação comercial em larga escala, recomenda-se
// revisão jurídica e inclusão do canal oficial de contato.
//
// ============================================================

class TermsOfUsePage
    extends
        StatelessWidget {
  const TermsOfUsePage({
    super.key,
  });

  static const String _lastUpdated = '4 de setembro de 2026';

  @override
  Widget build(
    BuildContext context,
  ) {
    return const _LegalDocumentPage(
      title: 'Termos de Uso',
      subtitle: 'Regras, responsabilidades e condições para utilização do EVRYLUX.',
      icon: Icons.description_outlined,
      lastUpdated: _lastUpdated,
      sections: [
        _LegalSection(
          title: '1. Aceitação dos Termos',
          paragraphs: [
            'Ao acessar, criar uma conta ou utilizar o EVRYLUX, você concorda com estes Termos de Uso e com a Política de Privacidade aplicável.',
            'Caso não concorde com alguma condição, você deve interromper o uso do aplicativo e, quando aplicável, excluir sua conta pelos controles disponíveis.',
          ],
        ),
        _LegalSection(
          title: '2. Sobre o EVRYLUX',
          paragraphs: [
            'O EVRYLUX é uma plataforma de organização e evolução pessoal que pode reunir recursos relacionados a estudos, rotina, treino, finanças, progresso, lembretes, conhecimento pessoal e outras áreas de acompanhamento individual.',
            'As funcionalidades podem ser adicionadas, alteradas, aprimoradas, limitadas ou removidas ao longo da evolução do produto.',
          ],
        ),
        _LegalSection(
          title: '3. Cadastro, conta e segurança',
          paragraphs: [
            'Algumas funcionalidades exigem criação de conta e autenticação. Você deve fornecer informações verdadeiras e manter seus dados de acesso protegidos.',
            'A conta é pessoal. Você é responsável por proteger sua senha, dispositivo e sessões autenticadas, bem como por não aprovar dispositivos ou solicitações de recuperação que não reconheça.',
            'O EVRYLUX pode solicitar confirmação adicional de identidade antes de ações sensíveis, incluindo alteração de senha, exclusão de dados ou exclusão da conta.',
          ],
        ),
        _LegalSection(
          title: '4. Licença de uso',
          paragraphs: [
            'Enquanto estes Termos forem respeitados, o EVRYLUX concede ao usuário uma licença pessoal, limitada, revogável, não exclusiva e não transferível para utilizar o aplicativo para suas finalidades previstas.',
            'Essa licença não concede direito de copiar, vender, sublicenciar, distribuir, explorar comercialmente, realizar engenharia reversa indevida ou utilizar elementos proprietários do EVRYLUX fora dos limites permitidos pela legislação.',
          ],
        ),
        _LegalSection(
          title: '5. Uso permitido e condutas proibidas',
          paragraphs: [
            'Você concorda em utilizar o EVRYLUX apenas para finalidades lícitas e compatíveis com estes Termos.',
            'É proibido tentar obter acesso não autorizado a contas, sistemas, bancos de dados, infraestrutura, chaves, sessões, dispositivos ou funcionalidades internas do aplicativo.',
            'Também é proibido utilizar o serviço para fraude, abuso, exploração de vulnerabilidades contra terceiros, violação de direitos, distribuição de conteúdo ilegal, sobrecarga intencional, automação abusiva ou qualquer atividade que comprometa a segurança ou disponibilidade da plataforma.',
          ],
        ),
        _LegalSection(
          title: '6. Conteúdo e dados inseridos pelo usuário',
          paragraphs: [
            'Você mantém a responsabilidade pelo conteúdo que inserir no EVRYLUX, incluindo textos, registros, arquivos, anotações, informações financeiras, dados de rotina, estudos, treino e demais informações pessoais.',
            'Ao utilizar recursos de sincronização, armazenamento remoto ou backup, você autoriza o processamento técnico desses dados na medida necessária para fornecer a funcionalidade solicitada.',
            'Você declara possuir os direitos necessários sobre qualquer conteúdo que inserir ou compartilhar por meio do aplicativo.',
          ],
        ),
        _LegalSection(
          title: '7. Funcionamento local, offline e sincronização',
          paragraphs: [
            'Determinadas funcionalidades podem operar de forma local-first e continuar funcionando temporariamente sem conexão com a internet.',
            'Alterações realizadas offline podem ser sincronizadas posteriormente. Conflitos, falhas de conexão, remoção do aplicativo, limpeza de dados locais ou perda do dispositivo podem afetar informações ainda não sincronizadas.',
            'É responsabilidade do usuário verificar o status de sincronização e manter cópias de segurança quando os dados forem importantes.',
          ],
        ),
        _LegalSection(
          title: '8. Cérebro, criptografia e backups',
          paragraphs: [
            'Recursos do Cérebro podem utilizar criptografia ponta a ponta e mecanismos de autorização de dispositivos para proteger conteúdo sensível.',
            'O usuário é responsável por aprovar apenas dispositivos reconhecidos e por armazenar backups .evbrain em local seguro. A perda de chaves, dispositivos autorizados e backups pode impedir a recuperação de determinados dados protegidos.',
            'Backups exportados e armazenados fora do aplicativo permanecem sob responsabilidade do usuário e não são removidos automaticamente quando a conta ou os dados do EVRYLUX são excluídos.',
          ],
        ),
        _LegalSection(
          title: '9. Sessões e dispositivos',
          paragraphs: [
            'O EVRYLUX pode registrar sessões e dispositivos associados à conta para fins de segurança e gerenciamento de acesso.',
            'Quando disponível, o usuário poderá visualizar dispositivos conectados e encerrar sessões que não reconheça. O funcionamento desse recurso pode depender da conectividade e do ciclo de validade da sessão de autenticação.',
          ],
        ),
        _LegalSection(
          title: '10. Recursos de treino, saúde e bem-estar',
          paragraphs: [
            'Informações relacionadas a treino, hábitos, evolução física, rotina ou bem-estar possuem finalidade organizacional e informativa.',
            'O EVRYLUX não fornece diagnóstico médico e não substitui orientação de médicos, nutricionistas, fisioterapeutas, psicólogos ou outros profissionais qualificados.',
            'Procure orientação profissional antes de iniciar atividades físicas, modificar hábitos ou tomar decisões relacionadas à saúde quando necessário.',
          ],
        ),
        _LegalSection(
          title: '11. Recursos financeiros',
          paragraphs: [
            'Ferramentas financeiras destinam-se à organização pessoal e ao acompanhamento de informações fornecidas pelo próprio usuário.',
            'O EVRYLUX não presta consultoria financeira, contábil, tributária, jurídica ou de investimentos, não executa operações financeiras em nome do usuário e não garante resultados financeiros.',
          ],
        ),
        _LegalSection(
          title: '12. Disponibilidade do serviço',
          paragraphs: [
            'Buscamos manter o EVRYLUX disponível, seguro e funcional, mas não garantimos funcionamento ininterrupto, ausência de falhas, compatibilidade permanente com todos os dispositivos ou disponibilidade contínua de todos os recursos.',
            'Manutenções, falhas de infraestrutura, atualizações de sistema, indisponibilidade de terceiros ou eventos fora do controle razoável do serviço podem afetar temporariamente o funcionamento.',
          ],
        ),
        _LegalSection(
          title: '13. Atualizações e alterações do produto',
          paragraphs: [
            'O EVRYLUX pode receber atualizações destinadas a segurança, correções, compatibilidade, desempenho ou novos recursos.',
            'Algumas atualizações podem alterar a interface, requisitos técnicos, formatos de dados, recursos disponíveis ou regras de sincronização.',
          ],
        ),
        _LegalSection(
          title: '14. Serviços de terceiros',
          paragraphs: [
            'O funcionamento do EVRYLUX pode depender de prestadores externos para autenticação, banco de dados, armazenamento, hospedagem, notificações e infraestrutura técnica.',
            'Esses serviços são regidos por seus próprios termos, políticas e níveis de disponibilidade. Mudanças ou interrupções nesses serviços podem afetar funcionalidades do EVRYLUX.',
          ],
        ),
        _LegalSection(
          title: '15. Propriedade intelectual',
          paragraphs: [
            'O nome EVRYLUX, identidade visual, interface, código, estrutura, textos próprios, elementos gráficos e demais componentes proprietários são protegidos pelas leis aplicáveis, salvo componentes de terceiros sujeitos às respectivas licenças.',
            'Estes Termos não transferem ao usuário qualquer direito de propriedade intelectual sobre o EVRYLUX.',
          ],
        ),
        _LegalSection(
          title: '16. Exclusão de dados e encerramento da conta',
          paragraphs: [
            'O usuário poderá excluir dados associados ao EVRYLUX ou encerrar permanentemente a conta pelos controles disponibilizados no aplicativo, quando aplicável.',
            'A exclusão dos dados pode preservar a conta de autenticação, enquanto a exclusão da conta encerra o acesso e remove os dados associados de acordo com o fluxo aplicável.',
            'Cópias externas criadas pelo próprio usuário, como arquivos .evbrain, não são apagadas automaticamente.',
          ],
        ),
        _LegalSection(
          title: '17. Suspensão ou restrição de acesso',
          paragraphs: [
            'O acesso ao EVRYLUX poderá ser limitado, suspenso ou encerrado em caso de fraude, abuso, risco de segurança, uso ilegal, violação destes Termos, determinação legal ou necessidade técnica relevante.',
            'Quando razoavelmente possível e permitido, poderão ser adotadas medidas proporcionais ao risco identificado.',
          ],
        ),
        _LegalSection(
          title: '18. Responsabilidade do usuário',
          paragraphs: [
            'O usuário permanece responsável por suas decisões, metas, registros, escolhas, conteúdo inserido, cópias de segurança e uso das informações apresentadas pelo aplicativo.',
            'Você também é responsável por manter seus dispositivos protegidos e por revisar sessões, permissões e autorizações sempre que suspeitar de acesso indevido.',
          ],
        ),
        _LegalSection(
          title: '19. Limitação de responsabilidade',
          paragraphs: [
            'Na medida permitida pela legislação aplicável, o EVRYLUX não será responsável por perdas indiretas, lucros cessantes, decisões pessoais, perda de dados ainda não sincronizados ou danos decorrentes de uso inadequado, indisponibilidade externa ou informações inseridas pelo próprio usuário.',
            'Nada nestes Termos exclui ou limita direitos que não possam ser legalmente afastados, incluindo direitos obrigatórios de consumidores e titulares de dados.',
          ],
        ),
        _LegalSection(
          title: '20. Alterações destes Termos',
          paragraphs: [
            'Estes Termos podem ser atualizados para refletir mudanças no produto, na legislação, na segurança ou nos serviços utilizados.',
            'A versão atualizada passará a valer a partir da data indicada no documento. Quando alterações relevantes exigirem nova ciência ou aceite, o usuário poderá ser informado pelo aplicativo ou por outro canal adequado.',
          ],
        ),
        _LegalSection(
          title: '21. Legislação aplicável',
          paragraphs: [
            'Estes Termos serão interpretados de acordo com a legislação aplicável ao usuário e ao responsável pelo serviço, respeitando normas obrigatórias de proteção ao consumidor, proteção de dados e demais direitos que não possam ser afastados contratualmente.',
          ],
        ),
        _LegalSection(
          title: '22. Contato',
          paragraphs: [
            'Dúvidas relacionadas a estes Termos podem ser encaminhadas ao canal oficial de suporte do EVRYLUX.',
            'Antes da publicação pública do aplicativo, o responsável pelo serviço deve incluir nesta seção um canal oficial e verificável de contato.',
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
