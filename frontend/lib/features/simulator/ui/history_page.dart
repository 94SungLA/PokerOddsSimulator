import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/simulator/data/models/history_record_model.dart';
import 'package:frontend/features/simulator/domain/models/card_model.dart';
import 'package:frontend/features/simulator/domain/providers/history_provider.dart';
import 'package:frontend/features/simulator/domain/providers/table_state.dart';
import 'package:frontend/features/simulator/ui/main_navigation_page.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '歷史紀錄 (History)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: historyState.when(
          data: (records) {
            if (records.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(historyProvider.notifier).refreshHistory(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return _HistoryCardItem(record: record);
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => _buildErrorState(context, ref, err.toString()),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            '尚無歷史計算紀錄',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '執行勝率計算後，結果將會自動記錄在此處',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    final cleanMsg = error.replaceAll('Exception: ', '');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.loseColor, size: 48),
            const SizedBox(height: 16),
            Text(
              cleanMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.loseColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => ref.read(historyProvider.notifier).refreshHistory(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重試載入', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCardItem extends ConsumerWidget {
  final HistoryRecord record;

  const _HistoryCardItem({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Format date time
    final dateStr = '${record.timestamp.year.toString().substring(2)}/'
        '${record.timestamp.month.toString().padLeft(2, '0')}/'
        '${record.timestamp.day.toString().padLeft(2, '0')} '
        '${record.timestamp.hour.toString().padLeft(2, '0')}:'
        '${record.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Timestamp and Opponent counts)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${record.opponentRanges.length + 1} 人對局',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Cards Row (Hero & Board)
          Row(
            children: [
              // Hero cards
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hero 手牌',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: record.heroHand.map((c) => _MiniCardView(cardStr: c)).toList(),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Board cards
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '公共牌',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    record.communityCards.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Pre-flop',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: record.communityCards.map((c) => _MiniCardView(cardStr: c)).toList(),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Equity percentages stacked bar
          _buildEquityBar(),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '贏: ${(record.winRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: AppColors.winColor, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              Text(
                '平: ${(record.tieRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: AppColors.tieColor, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              Text(
                '輸: ${(record.loseRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: AppColors.loseColor, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Footer Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.loseColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () => _confirmDelete(context, ref, record.id),
                icon: const Icon(Icons.delete_outline, size: 15),
                label: const Text('刪除', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _loadRecord(context, ref),
                icon: const Icon(Icons.visibility, size: 15),
                label: const Text('載入牌桌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquityBar() {
    final winFlex = (record.winRate * 1000).round();
    final tieFlex = (record.tieRate * 1000).round();
    final loseFlex = (record.loseRate * 1000).round();
    final totalFlex = winFlex + tieFlex + loseFlex;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 6,
        color: AppColors.border,
        child: totalFlex == 0
            ? Container()
            : Row(
                children: [
                  if (winFlex > 0)
                    Expanded(
                      flex: winFlex,
                      child: Container(color: AppColors.winColor),
                    ),
                  if (tieFlex > 0)
                    Expanded(
                      flex: tieFlex,
                      child: Container(color: AppColors.tieColor),
                    ),
                  if (loseFlex > 0)
                    Expanded(
                      flex: loseFlex,
                      child: Container(color: AppColors.loseColor),
                    ),
                ],
              ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        title: const Text('確認刪除', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text('您確定要永久刪除此筆勝率計算紀錄嗎？', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.loseColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(historyProvider.notifier).deleteRecord(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已成功刪除紀錄'), backgroundColor: AppColors.surface),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('刪除失敗: $e'), backgroundColor: AppColors.loseColor),
                  );
                }
              }
            },
            child: const Text('確認刪除', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _loadRecord(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(tableStateProvider.notifier);
    
    // Parse Hero hand
    final heroCard1 = record.heroHand.isNotEmpty ? CardModel.fromString(record.heroHand[0]) : null;
    final heroCard2 = record.heroHand.length > 1 ? CardModel.fromString(record.heroHand[1]) : null;

    // Parse Community cards
    final communityCards = List<CardModel?>.generate(5, (idx) {
      return idx < record.communityCards.length
          ? CardModel.fromString(record.communityCards[idx])
          : null;
    });

    final totalPlayers = record.opponentRanges.length + 1;
    final opponentHands = List<List<CardModel?>>.generate(totalPlayers - 1, (_) => List.filled(2, null));
    final opponentRanges = List<String>.generate(totalPlayers - 1, (_) => '');

    // Parse Opponents
    for (var i = 0; i < record.opponentRanges.length; i++) {
      final item = record.opponentRanges[i];
      if (item is List) {
        if (item.length == 2) {
          opponentHands[i] = [
            CardModel.fromString(item[0] as String),
            CardModel.fromString(item[1] as String)
          ];
        }
      } else if (item is String) {
        opponentRanges[i] = item;
      }
    }

    notifier.loadState(
      playerCard1: heroCard1,
      playerCard2: heroCard2,
      communityCards: communityCards,
      opponentHands: opponentHands,
      opponentRanges: opponentRanges,
      totalPlayers: totalPlayers,
    );

    // Switch to simulator tab (index 0)
    ref.read(navigationTabProvider.notifier).state = 0;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已成功載入模擬數據至牌桌！'),
        backgroundColor: AppColors.surface,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _MiniCardView extends StatelessWidget {
  final String cardStr;

  const _MiniCardView({required this.cardStr});

  @override
  Widget build(BuildContext context) {
    final card = CardModel.fromString(cardStr);
    final isRed = card.isRed;
    final color = isRed ? AppColors.suitRed : AppColors.suitBlack;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 22,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Center(
        child: Text(
          '${card.rank}${card.suitSymbol}',
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
