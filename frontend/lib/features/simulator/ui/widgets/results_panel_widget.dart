import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/simulator/data/models/simulation_result_model.dart';
import 'package:frontend/features/simulator/data/models/evaluation_result_model.dart';
import 'package:frontend/features/simulator/domain/providers/evaluation_provider.dart';
import 'package:frontend/features/simulator/domain/providers/ai_coach_provider.dart';
import 'package:frontend/features/simulator/domain/providers/table_state.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ResultsPanelWidget extends ConsumerStatefulWidget {
  final SimulationResult result;

  const ResultsPanelWidget({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<ResultsPanelWidget> createState() => _ResultsPanelWidgetState();
}

class _ResultsPanelWidgetState extends ConsumerState<ResultsPanelWidget> {
  int? _expandedPlayerIndex; // Track which player's distribution is expanded

  @override
  Widget build(BuildContext context) {
    AppColors.setTheme(context);
    // Watch hand evaluation results automatically
    final evaluationState = ref.watch(evaluationProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header & Metadata
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '模擬計算結果 (SIMULATION RESULTS)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '耗時 ${widget.result.elapsedTimeMs.toStringAsFixed(1)} ms',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '基於 ${widget.result.simulationsRun.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} 次 Monte Carlo 模擬對局',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 16),

          // Real-time Hand Analyzer (Outs & Potential Improvements)
          evaluationState.when(
            data: (evaluation) => _buildHandAnalyzerSection(evaluation),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('手牌分析載入失敗: $err', style: const TextStyle(color: AppColors.loseColor, fontSize: 12)),
            ),
          ),

          // Player Results List
          ...widget.result.playerResults.map((player) {
            final isHero = player.playerIndex == 0;
            final isExpanded = _expandedPlayerIndex == player.playerIndex;
            final label = isHero ? '你 (Hero)' : '對手 ${player.playerIndex}';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Player Label & Win Rate Text
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _expandedPlayerIndex = isExpanded ? null : player.playerIndex;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: isHero ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                        Text(
                          '勝率: ${(player.winRate * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isHero ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Stacked Win/Tie/Lose Progress Bar
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedPlayerIndex = isExpanded ? null : player.playerIndex;
                      });
                    },
                    child: _buildStackedProgressBar(player),
                  ),
                  const SizedBox(height: 6),

                  // Segment labels under bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '贏: ${(player.winRate * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppColors.winColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '平手: ${(player.tieRate * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppColors.tieColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '輸: ${(player.loseRate * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppColors.loseColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  // Expanded Distribution
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    _buildHandTypeDistribution(player),
                  ],
                  SizedBox(height: 8),
                  Divider(color: AppColors.border, height: 1),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // AI Coach Action Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _showAiCoachExplanation(context, ref),
            icon: const Icon(Icons.psychology_outlined),
            label: const Text(
              'AI 教練策略分析 (AI Explain)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandAnalyzerSection(EvaluationResult? evaluation) {
    if (evaluation == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '即時牌型分析 (HAND ANALYZER)',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _translateHandType(evaluation.handType),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            evaluation.handStrengthSummary,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (evaluation.potentialImprovements.isNotEmpty) ...[
            SizedBox(height: 10),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            Text(
              '潛在改善聽牌 (Outs & Improvements):',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...evaluation.potentialImprovements.map((imp) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${_translateHandType(imp.improvement)}: ',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${imp.outs} 個 Outs',
                              style: const TextStyle(color: AppColors.winColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          '${(imp.probability * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (imp.outsCards.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '(${imp.outsCards.map((c) => _formatCardSymbol(c)).join(' ')})',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontSize: 10.5,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _formatCardSymbol(String cardStr) {
    if (cardStr.length < 2) return cardStr;
    final rank = cardStr[0];
    final suit = cardStr[1];
    String sym = '';
    switch (suit) {
      case 's': sym = '♠'; break;
      case 'h': sym = '♥'; break;
      case 'd': sym = '♦'; break;
      case 'c': sym = '♣'; break;
    }
    return '$rank$sym';
  }

  void _showAiCoachExplanation(BuildContext context, WidgetRef ref) {
    // Reset provider to clear any previous cached error or state
    ref.read(aiCoachProvider.notifier).reset();
    
    final tableState = ref.read(tableStateProvider);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final aiState = ref.watch(aiCoachProvider);

            // Trigger fetch on popup load
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (aiState.valueOrNull == null && !aiState.isLoading && !aiState.hasError) {
                ref.read(aiCoachProvider.notifier).requestExplanation(
                  tableState: tableState,
                  result: widget.result,
                );
              }
            });

            return AlertDialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.border),
              ),
              title: Row(
                children: [
                  const Icon(Icons.psychology, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'AI 撲克教練策略解說',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5,
                child: aiState.when(
                  data: (text) {
                    if (text == null) return const SizedBox.shrink();
                    return SingleChildScrollView(
                      child: MarkdownBody(
                        data: text,
                        selectable: false,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            height: 1.6,
                          ),
                          h1: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.6,
                          ),
                          h2: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            height: 1.6,
                          ),
                          h3: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            height: 1.6,
                          ),
                          listBullet: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13.5,
                          ),
                          strong: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          blockSpacing: 10,
                        ),
                      ),
                    );
                  },
                  loading: () => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 20),
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 20),
                      Text(
                        'AI 教練正在解析對局形勢與對手範圍...',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  error: (err, stack) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.loseColor, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        err.toString().replaceAll('Exception: ', ''),
                        style: const TextStyle(color: AppColors.loseColor, fontSize: 13, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(aiCoachProvider.notifier).reset();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('關閉', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStackedProgressBar(PlayerResult player) {
    final winFlex = (player.winRate * 1000).round();
    final tieFlex = (player.tieRate * 1000).round();
    final loseFlex = (player.loseRate * 1000).round();
    final totalFlex = winFlex + tieFlex + loseFlex;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 14,
        color: AppColors.border,
        child: totalFlex == 0
            ? Container()
            : Row(
                children: [
                  if (winFlex > 0)
                    Expanded(
                      flex: winFlex,
                      child: Container(
                        color: AppColors.winColor,
                      ),
                    ),
                  if (tieFlex > 0)
                    Expanded(
                      flex: tieFlex,
                      child: Container(
                        color: AppColors.tieColor,
                      ),
                    ),
                  if (loseFlex > 0)
                    Expanded(
                      flex: loseFlex,
                      child: Container(
                        color: AppColors.loseColor,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildHandTypeDistribution(PlayerResult player) {
    final items = player.handTypeDistribution.entries
        .where((e) => e.value > 0.0)
        .toList();

    items.sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '可能牌型機率分佈 (HAND DISTRIBUTION)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((entry) {
            final typeName = entry.key;
            final probability = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _translateHandType(typeName),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(probability * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: probability,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _translateHandType(String englishName) {
    switch (englishName) {
      case 'High Card': return '高牌 (High Card)';
      case 'One Pair': return '一對 (One Pair)';
      case 'Two Pair': return '兩對 (Two Pair)';
      case 'Three of a Kind': return '三條 (Three of a Kind)';
      case 'Straight': return '順子 (Straight)';
      case 'Flush': return '同花 (Flush)';
      case 'Full House': return '葫蘆 (Full House)';
      case 'Four of a Kind': return '鐵支 (Four of a Kind)';
      case 'Straight Flush': return '同花順 (Straight Flush)';
      case 'Royal Flush': return '皇家同花順 (Royal Flush)';
      default: return englishName;
    }
  }
}

