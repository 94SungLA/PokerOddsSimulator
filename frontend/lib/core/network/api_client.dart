import 'package:dio/dio.dart';
import 'package:frontend/features/simulator/data/models/simulation_result_model.dart';
import 'package:frontend/features/simulator/data/models/evaluation_result_model.dart';
import 'package:frontend/features/simulator/data/models/range_preset_model.dart';
import 'package:frontend/features/simulator/data/models/history_record_model.dart';

class ApiClient {
  Dio _dio;

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'http://127.0.0.1:8000/api/v1',
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            );

  void updateBaseUrl(String newUrl) {
    _dio = Dio(
      BaseOptions(
        baseUrl: newUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<SimulationResult> simulate({
    required List<String> playerHand,
    required List<List<String>> opponentHands,
    List<String>? opponentRanges,
    required List<String> communityCards,
    required int totalPlayers,
    int simulations = 10000,
  }) async {
    try {
      final response = await _dio.post(
        '/simulator/simulate',
        data: {
          'player_hand': playerHand,
          'opponent_hands': opponentHands,
          'opponent_ranges': opponentRanges ?? [],
          'community_cards': communityCards,
          'total_players': totalPlayers,
          'simulations': simulations,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return SimulationResult.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Server returned an error status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '模擬計算失敗');
    } catch (e) {
      throw Exception('發生未知錯誤: $e');
    }
  }

  Future<EvaluationResult> evaluate({
    required List<String> cards,
  }) async {
    try {
      final response = await _dio.post(
        '/evaluate',
        data: {
          'cards': cards,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return EvaluationResult.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Server returned an error status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '手牌評估失敗');
    } catch (e) {
      throw Exception('發生未知錯誤: $e');
    }
  }

  Future<List<RangePreset>> getRanges() async {
    try {
      final response = await _dio.get('/ranges');
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List;
        return list.map((e) => RangePreset.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Server returned an error status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '載入範圍預設失敗');
    } catch (e) {
      throw Exception('發生未知錯誤: $e');
    }
  }

  Future<List<HistoryRecord>> getHistory() async {
    try {
      final response = await _dio.get('/history');
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List;
        return list.map((e) => HistoryRecord.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Server returned an error status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '載入歷史紀錄失敗');
    } catch (e) {
      throw Exception('發生未知錯誤: $e');
    }
  }

  Future<HistoryRecord> saveHistory({
    required List<String> heroHand,
    required List<dynamic> opponentRanges,
    required List<String> communityCards,
    required double winRate,
    required double tieRate,
    required double loseRate,
  }) async {
    try {
      final response = await _dio.post(
        '/history',
        data: {
          'hero_hand': heroHand,
          'opponent_ranges': opponentRanges,
          'community_cards': communityCards,
          'win_rate': winRate,
          'tie_rate': tieRate,
          'lose_rate': loseRate,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return HistoryRecord.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Server returned an error status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '儲存歷史紀錄失敗');
    } catch (e) {
      throw Exception('發生未知錯誤: $e');
    }
  }

  Future<void> deleteHistory(int id) async {
    try {
      final response = await _dio.delete('/history/$id');
      if (response.statusCode != 204) {
        throw Exception('Server returned an error status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '刪除歷史紀錄失敗');
    } catch (e) {
      throw Exception('發生未知錯誤: $e');
    }
  }

  Future<String> explain({
    required List<String> playerHand,
    required List<String> communityCards,
    required List<dynamic> opponentRanges,
    required double winRate,
    required double tieRate,
    required double loseRate,
  }) async {
    try {
      final response = await _dio.post(
        '/explain',
        data: {
          'player_hand': playerHand,
          'community_cards': communityCards,
          'opponent_ranges': opponentRanges,
          'win_rate': winRate,
          'tie_rate': tieRate,
          'lose_rate': loseRate,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['explanation'] as String;
      } else {
        throw Exception('Server returned an error status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'AI 教練解說失敗');
    } catch (e) {
      throw Exception('發生未知錯誤: $e');
    }
  }

  Exception _handleDioError(DioException e, String contextMessage) {
    String errorMessage = '連線失敗，請確認後端服務已啟動。';
    if (e.type == DioExceptionType.connectionTimeout) {
      errorMessage = '連線逾時，後端無回應。';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      errorMessage = '接收逾時，伺服器無回應。';
    } else if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('detail')) {
        errorMessage = '${data['detail']}';
      } else {
        errorMessage = '伺服器錯誤 (代碼 ${e.response?.statusCode})';
      }
    }
    return Exception('$contextMessage: $errorMessage');
  }
}

final apiClient = ApiClient();

