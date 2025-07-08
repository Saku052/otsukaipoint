import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/allowance_repository_impl.dart';
import '../repositories/notification_repository_impl.dart';
import '../repositories/family_repository_impl.dart';
import '../services/supabase_service.dart';
import '../../domain/repositories/allowance_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/family_repository.dart';

/// リポジトリプロバイダー
final allowanceRepositoryProvider = Provider<AllowanceRepository>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return AllowanceRepositoryImpl(supabaseService);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return NotificationRepositoryImpl(supabaseService);
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return FamilyRepositoryImpl(supabaseService);
});