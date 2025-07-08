import '../../domain/entities/family.dart';
import '../../domain/repositories/family_repository.dart';
import '../services/supabase_service.dart';

/// 家族リポジトリ実装
class FamilyRepositoryImpl implements FamilyRepository {
  final SupabaseService _supabaseService;

  FamilyRepositoryImpl(this._supabaseService);

  @override
  Future<Family?> getCurrentFamily() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return null;

      final memberResponse = await _supabaseService.client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (memberResponse == null) return null;

      final familyId = memberResponse['family_id'] as String;
      final familyResponse = await _supabaseService.client
          .from('families')
          .select()
          .eq('id', familyId)
          .eq('is_active', true)
          .single();

      return Family.fromMap(familyResponse);
    } catch (e) {
      throw Exception('家族情報の取得に失敗しました: $e');
    }
  }

  @override
  Future<String> createFamily({
    required String name,
    required String createdBy,
  }) async {
    try {
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

      final family = Family.fromMap(familyResponse);

      await _supabaseService.client.from('family_members').insert({
        'family_id': family.id,
        'user_id': createdBy,
        'role': 'parent',
        'is_active': true,
        'joined_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return family.id;
    } catch (e) {
      throw Exception('家族の作成に失敗しました: $e');
    }
  }

  @override
  Future<void> updateFamily(Family family) async {
    try {
      await _supabaseService.client
          .from('families')
          .update(family.toMap())
          .eq('id', family.id);
    } catch (e) {
      throw Exception('家族情報の更新に失敗しました: $e');
    }
  }

  @override
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

  @override
  Future<void> joinFamilyByInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
  }) async {
    try {
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
    } catch (e) {
      throw Exception('家族への参加に失敗しました: $e');
    }
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    try {
      final response = await _supabaseService.client
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .eq('is_active', true);

      return (response as List)
          .map((data) => FamilyMember.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('家族メンバーの取得に失敗しました: $e');
    }
  }

  @override
  Future<void> suspendChildAccount(String memberId) async {
    try {
      await _supabaseService.client
          .from('family_members')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', memberId);
    } catch (e) {
      throw Exception('子アカウントの停止に失敗しました: $e');
    }
  }

  @override
  Future<void> reactivateChildAccount(String memberId) async {
    try {
      await _supabaseService.client
          .from('family_members')
          .update({
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', memberId);
    } catch (e) {
      throw Exception('子アカウントの復活に失敗しました: $e');
    }
  }

  @override
  Future<void> deleteFamily(String familyId) async {
    try {
      await _supabaseService.client
          .from('families')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', familyId);
    } catch (e) {
      throw Exception('家族の削除に失敗しました: $e');
    }
  }
}