import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/family.dart' as entities;
import '../../infrastructure/services/supabase_service.dart';

/// 家族状態
class FamilyState {
  final bool isLoading;
  final entities.Family? currentFamily;
  final List<entities.Family> families;
  final String? error;

  const FamilyState({
    this.isLoading = false,
    this.currentFamily,
    this.families = const [],
    this.error,
  });

  FamilyState copyWith({
    bool? isLoading,
    entities.Family? currentFamily,
    List<entities.Family>? families,
    String? error,
  }) {
    return FamilyState(
      isLoading: isLoading ?? this.isLoading,
      currentFamily: currentFamily ?? this.currentFamily,
      families: families ?? this.families,
      error: error ?? this.error,
    );
  }
}

/// 家族プロバイダー
class FamilyNotifier extends StateNotifier<FamilyState> {
  final SupabaseService _supabaseService;

  FamilyNotifier(this._supabaseService) : super(const FamilyState());

  /// 現在の家族を取得
  Future<entities.Family?> getCurrentFamily() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーが認証されていません');
      }

      // family_membersテーブルから家族IDを取得
      final memberResponse = await _supabaseService.client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (memberResponse == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }

      final familyId = memberResponse['family_id'] as String;

      // 家族情報を取得
      final familyResponse = await _supabaseService.client
          .from('families')
          .select()
          .eq('id', familyId)
          .eq('is_active', true)
          .single();

      final family = entities.Family.fromMap(familyResponse);

      state = state.copyWith(
        isLoading: false,
        currentFamily: family,
      );

      return family;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '家族情報の取得に失敗しました: $e',
      );
      return null;
    }
  }

  /// 家族を作成
  Future<String> createFamily({
    required String name,
    required String createdBy,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 家族を作成
      final familyResponse = await _supabaseService.client
          .from('families')
          .insert({
            'name': name,
            'created_by': createdBy,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final family = entities.Family.fromMap(familyResponse);

      // 作成者を家族メンバーに追加（親として）
      await _supabaseService.client.from('family_members').insert({
        'family_id': family.id,
        'user_id': createdBy,
        'role': 'parent',
        'is_active': true,
        'joined_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      state = state.copyWith(
        isLoading: false,
        currentFamily: family,
      );

      return family.id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '家族の作成に失敗しました: $e',
      );
      rethrow;
    }
  }

  /// QRコード情報を更新
  Future<void> updateQrCode({
    required String familyId,
    required String qrCode,
    required DateTime expiresAt,
  }) async {
    try {
      await _supabaseService.client
          .from('families')
          .update({
            'qr_code': qrCode,
            'qr_code_expires_at': expiresAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', familyId);
    } catch (e) {
      throw Exception('QRコード情報の更新に失敗しました: $e');
    }
  }

  /// 招待コードで家族に参加
  Future<void> joinFamilyByInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 招待コードから家族を検索
      final familyResponse = await _supabaseService.client
          .from('families')
          .select()
          .like('qr_code', '%$inviteCode%')
          .eq('is_active', true)
          .gt('qr_code_expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (familyResponse == null) {
        throw Exception('無効な招待コードです');
      }

      final familyId = familyResponse['id'] as String;

      // 既に家族メンバーかチェック
      final existingMember = await _supabaseService.client
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        if (existingMember['is_active'] == true) {
          throw Exception('既にこの家族のメンバーです');
        } else {
          // 非アクティブなメンバーを再アクティブ化
          await _supabaseService.client
              .from('family_members')
              .update({
                'is_active': true,
                'joined_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existingMember['id']);
        }
      } else {
        // 新しいメンバーとして追加（子として）
        await _supabaseService.client.from('family_members').insert({
          'family_id': familyId,
          'user_id': userId,
          'role': 'child',
          'is_active': true,
          'joined_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // 家族情報を更新
      final family = entities.Family.fromMap(familyResponse);
      state = state.copyWith(
        isLoading: false,
        currentFamily: family,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '家族への参加に失敗しました: $e',
      );
      rethrow;
    }
  }

  /// 初回ログイン時の家族作成
  Future<void> ensureUserHasFamily() async {
    try {
      final user = _supabaseService.client.auth.currentUser;
      if (user == null) return;

      // 既に家族に所属しているかチェック
      final existingFamily = await getCurrentFamily();
      if (existingFamily != null) return;

      // 家族が存在しない場合、新規作成
      await createFamily(
        name: '家族',
        createdBy: user.id,
      );
    } catch (e) {
      print('家族の作成エラー: $e');
      // エラーが発生してもアプリの動作は継続
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 家族プロバイダー
final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return FamilyNotifier(supabaseService);
});

/// 現在の家族プロバイダー
final currentFamilyProvider = Provider<entities.Family?>((ref) {
  final familyState = ref.watch(familyProvider);
  return familyState.currentFamily;
});