import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../usecases/manage_allowance_usecase.dart';
import '../usecases/manage_family_usecase.dart';
import '../../infrastructure/providers/repository_providers.dart';

/// ユースケースプロバイダー
final manageAllowanceUseCaseProvider = Provider<ManageAllowanceUseCase>((ref) {
  final allowanceRepository = ref.read(allowanceRepositoryProvider);
  final notificationRepository = ref.read(notificationRepositoryProvider);
  final familyRepository = ref.read(familyRepositoryProvider);
  
  return ManageAllowanceUseCase(
    allowanceRepository,
    notificationRepository,
    familyRepository,
  );
});

final manageFamilyUseCaseProvider = Provider<ManageFamilyUseCase>((ref) {
  final familyRepository = ref.read(familyRepositoryProvider);
  final notificationRepository = ref.read(notificationRepositoryProvider);
  
  return ManageFamilyUseCase(
    familyRepository,
    notificationRepository,
  );
});