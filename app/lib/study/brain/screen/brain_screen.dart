import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart' as dependencies;
import '../../../brain/visualization/brain_visualization.dart';
import '../../../brain/visualization/painters/brain_paths.dart';

// ============================================================
// BRAIN AI
// ============================================================

import '../ai/models/brain_ai_response.dart';
import '../ai/services/brain_ai_context_builder.dart';
import '../ai/services/brain_ai_intent_detector.dart';
import '../ai/services/brain_ai_orchestrator.dart';
import '../ai/services/brain_ai_supabase_client.dart';
import '../ai/widgets/brain_ai_result_card.dart';

// ============================================================
// BRAIN CORE
// ============================================================

import '../controllers/brain_controller.dart';
import '../experience/controllers/brain_experience_controller.dart';
import '../experience/services/brain_initialization_service.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';
import '../models/brain_source.dart';
import '../settings/models/brain_data_mode.dart';

import '../search/models/brain_search_response.dart';
import '../search/services/brain_search_engine.dart';
import '../search/services/brain_search_parser.dart';
import '../search/widgets/brain_search_help_dialog.dart';
import '../source/widgets/brain_source_dialog.dart';

// ============================================================
// SCREENS
// ============================================================

import 'concept/concept_screen.dart';
import 'question/question_screen.dart';
import 'example/example_screen.dart';
import 'warning/warning_screen.dart';
import 'note/brain_note_screen.dart';
import 'widgets/brain_add_knowledge_button.dart';

// ============================================================
// PARTS
// ============================================================

part 'brain_screen_parts/brain_screen_core.dart';
part 'brain_screen_parts/brain_screen_visual_search.dart';
part 'brain_screen_parts/brain_screen_creation.dart';
part 'brain_screen_parts/brain_screen_layout.dart';
part 'brain_screen_parts/brain_screen_models.dart';

// ============================================================
// BRAIN SCREEN
// ============================================================
//
// Responsabilidade desta tela:
//
// - compor a experiência visual;
// - reagir aos controllers;
// - abrir navegação e dialogs pertencentes à UI.
//
// A coordenação da primeira experiência NÃO mora mais aqui.
// Ela foi extraída para:
//
// BrainExperienceController
//        ↓
// BrainInitializationService
//
// O BrainController continua sendo a instância global offline-first
// criada em app_dependencies.dart.
//
// ============================================================
//
// EVRYLUX BRAIN AI
//
// A BrainScreen também mantém o estado visual da experiência de IA.
//
// O fluxo é:
//
// texto digitado
//      ↓
// BrainAiIntentDetector
//      ↓
// pesquisa local / Vault
//      ↓
// BrainAiContextBuilder
//      ↓
// contexto compacto
//      ↓
// BrainAiOrchestrator
//      ↓
// BrainAiSupabaseClient
//      ↓
// Supabase Edge Function
//      ↓
// Groq
//
// IMPORTANTE:
//
// - busca normal continua local;
// - IA não é chamada durante cada tecla;
// - IA só entra quando uma intenção compatível é confirmada;
// - GROQ_API_KEY nunca existe no Flutter;
// - somente contexto selecionado é enviado ao backend.
//
// ============================================================

class BrainScreen
    extends
        StatefulWidget {
  const BrainScreen({
    super.key,
  });

  @override
  State<
    BrainScreen
  >
  createState() {
    return _BrainScreenState();
  }
}

class _BrainScreenState
    extends
        State<
          BrainScreen
        > {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final BrainController _controller;

  late final BrainExperienceController _experienceController;

  // ============================================================
  // BRAIN AI — SERVIÇOS
  // ============================================================
  //
  // O detector é puro e não possui estado.
  //
  // O orchestrator coordena:
  //
  // intenção
  //      ↓
  // contexto compacto
  //      ↓
  // client Supabase
  //
  // ============================================================

  static const BrainAiIntentDetector _brainAiIntentDetector = BrainAiIntentDetector();

  late final BrainAiOrchestrator _brainAiOrchestrator;

  // ============================================================
  // BRAIN AI — ESTADO VISUAL
  // ============================================================
  //
  // _brainAiLoading:
  //   existe uma consulta inteligente em andamento.
  //
  // _brainAiResponse:
  //   resposta estruturada recebida da Edge Function.
  //
  // _brainAiError:
  //   mensagem amigável caso a consulta falhe.
  //
  // ============================================================

  bool _brainAiLoading = false;

  BrainAiResponse? _brainAiResponse;

  String? _brainAiError;

  // ============================================================
  // CÉREBRO VISUAL — EVRYLUX
  // ============================================================

  BrainVisualController? _brainVisualController;

  Timer? _brainSearchPulseStopTimer;

  bool _brainVisualReady = false;

  static const Duration _brainGrowthPreviewDuration = Duration(
    milliseconds: 2050,
  );

  // ============================================================
  // PRIMEIRA EXPERIÊNCIA
  // ============================================================

  bool _dataModeDialogRunning = false;

  bool _dataModeDialogScheduled = false;

  bool _experienceErrorShown = false;

  // ============================================================
  // PESQUISA
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  // ==========================================================
  // TEXTO ATUAL DO CAMPO
  // ==========================================================
  //
  // Este valor acompanha a digitação imediatamente.
  //
  // Exemplo:
  //
  // m
  // me
  // mem
  // memo
  // memória
  //
  // Ele serve para:
  //
  // - atualizar visualmente o campo;
  // - saber se existe texto;
  // - reconhecer frases incompletas;
  //
  // Ele NÃO deve ser usado diretamente para executar a busca.
  //
  // ==========================================================

  String _searchQuery = '';

  // ==========================================================
  // CONSULTA CONFIRMADA
  // ==========================================================
  //
  // Este é o texto que realmente pode ser enviado ao:
  //
  // BrainSearchParser
  //        ↓
  // BrainSearchEngine
  //
  // Ele só será atualizado depois que o usuário parar de
  // digitar pelo tempo definido em _searchDebounceDuration.
  //
  // Exemplo:
  //
  // usuário digita:
  //
  // memória dinâ...
  //
  // _searchQuery muda imediatamente.
  //
  // _committedSearchQuery continua vazio.
  //
  // Depois de 500 ms sem nova tecla:
  //
  // _committedSearchQuery = "memória dinâmica"
  //
  // ==========================================================

  String _committedSearchQuery = '';

  // ==========================================================
  // DEBOUNCE DA PESQUISA
  // ==========================================================

  Timer? _searchDebounceTimer;

  static const Duration _searchDebounceDuration = Duration(
    milliseconds: 500,
  );

  // ==========================================================
  // PARSER / ENGINE
  // ==========================================================

  static const BrainSearchParser _searchParser = BrainSearchParser();

  static const BrainSearchEngine _searchEngine = BrainSearchEngine();

  bool _showAllSearchResults = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ========================================================
    // CONTROLLER GLOBAL OFFLINE-FIRST
    // ========================================================
    //
    // BrainScreen não cria um BrainController local.
    //
    // Mantemos a instância global configurada no container:
    //
    // BrainController
    //      ↓
    // BrainRepository
    //      ↓
    // armazenamento local / Vault
    //      ↓
    // SyncQueue
    //      ↓
    // SyncService
    //      ↓
    // Supabase
    //
    // ========================================================

    _controller = dependencies.brainController;

    // ========================================================
    // BRAIN AI
    // ========================================================
    //
    // Aqui conectamos a arquitetura de IA ao client REAL.
    //
    // Não existe mock.
    //
    // BrainAiSupabaseClient
    //      ↓
    // sessão atual Supabase
    //      ↓
    // access token
    //      ↓
    // /functions/v1/brain-assistant
    //      ↓
    // Groq
    //
    // ========================================================

    _brainAiOrchestrator = BrainAiOrchestrator(
      intentDetector: const BrainAiIntentDetector(),
      contextBuilder: const BrainAiContextBuilder(),
      client: const BrainAiSupabaseClient(),
    );

    // ========================================================
    // PRIMEIRA EXPERIÊNCIA
    // ========================================================
    //
    // O service carrega os dados necessários.
    // O controller coordena o fluxo.
    // A Screen apenas reage ao estado.
    //
    // ========================================================

    final initializationService = BrainInitializationService(
      brainController: _controller,
      visualStateStorage: BrainVisualStateStorage(
        storageScope: dependencies.userStorageScope,
      ),
      dataModeStorage: dependencies.brainDataModeStorage,
    );

    _experienceController = BrainExperienceController(
      initializationService: initializationService,
    );

    _controller.addListener(
      _onControllerChanged,
    );

    _experienceController.addListener(
      _onExperienceChanged,
    );

    unawaited(
      _initialize(),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    _experienceController.removeListener(
      _onExperienceChanged,
    );

    // ========================================================
    // CANCELAR TIMERS DA PESQUISA
    // ========================================================
    //
    // Muito importante:
    //
    // nenhum callback do debounce ou da animação deve continuar
    // executando depois que BrainScreen for destruída.
    //
    // ========================================================

    _searchDebounceTimer?.cancel();

    _brainSearchPulseStopTimer?.cancel();

    // ========================================================
    // LIMPAR ESTADO DA IA
    // ========================================================
    //
    // O orchestrator não possui recurso descartável,
    // portanto não precisa de dispose().
    //
    // Apenas soltamos referências visuais da resposta.
    //
    // ========================================================

    _brainAiResponse = null;
    _brainAiError = null;
    _brainAiLoading = false;

    // ========================================================
    // CÉREBRO VISUAL
    // ========================================================

    _brainVisualController?.dispose();

    // ========================================================
    // EXPERIENCE
    // ========================================================

    _experienceController.dispose();

    // ========================================================
    // TEXT CONTROLLER
    // ========================================================

    _searchController.dispose();

    // ========================================================
    // NÃO FAZER _controller.dispose()
    // ========================================================
    //
    // O BrainController pertence ao container global da aplicação.
    //
    // ========================================================

    super.dispose();
  }

  // ============================================================
  // CONTROLLER GLOBAL
  // ============================================================

  void _onControllerChanged() {
    _mutateState(
      () {},
    );
  }

  // ============================================================
  // EXPERIENCE CONTROLLER
  // ============================================================

  void _onExperienceChanged() {
    if (!mounted) {
      return;
    }

    _prepareBrainVisualFromExperience();

    _mutateState(
      () {},
    );

    _scheduleDataModeChoiceIfNeeded();

    _showExperienceErrorIfNeeded();
  }

  // ============================================================
  // STATE MUTATION GATE
  // ============================================================
  //
  // Extensions da BrainScreen não chamam State.setState()
  // diretamente.
  //
  // Isso mantém o acesso ao membro protegido dentro da própria
  // subclasse de State e oferece um único ponto seguro para
  // atualizações vindas dos módulos da tela.
  //
  // ============================================================

  void _mutateState(
    VoidCallback mutation,
  ) {
    if (!mounted) {
      return;
    }

    setState(
      mutation,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================
      //
      // Mantemos a AppBar para preservar o botão de voltar.
      //
      // ========================================================
      appBar: _buildAppBar(
        context,
      ),

      // ========================================================
      // BODY
      // ========================================================
      body:
          _controller.isLoading ||
              _experienceController.isInitializing
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildBody(
              context,
            ),
    );
  }
}
