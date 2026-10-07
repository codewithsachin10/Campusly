import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/promo_banner_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final promoBannersProvider = FutureProvider.autoDispose<List<PromoBannerModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final userState = await ref.watch(authControllerProvider.future);
  
  final response = await supabase
      .from('promo_banners')
      .select()
      .eq('is_active', true)
      .order('display_order', ascending: true);
      
  final allBanners = (response as List).map((json) => PromoBannerModel.fromJson(json)).toList();
  
  final now = DateTime.now();
  
  return allBanners.where((banner) {
    // 1. Time Filtering
    if (banner.startDate != null && banner.startDate!.isAfter(now)) return false;
    if (banner.endDate != null && banner.endDate!.isBefore(now)) return false;
    
    // 2. Audience Filtering
    if (userState != null) {
      // Check department (assuming user's department maps to targetDepartments which is a list of department IDs. 
      // This is a bit tricky if user has name instead of ID, but we do our best.
      if (banner.targetDepartments != null && banner.targetDepartments!.isNotEmpty) {
        if (!banner.targetDepartments!.contains(userState.department)) {
          return false;
        }
      }
      
      // Check batch/year
      if (banner.targetBatches != null && banner.targetBatches!.isNotEmpty) {
        if (!banner.targetBatches!.contains(userState.year)) {
          return false;
        }
      }
    }
    
    return true;
  }).toList();
});
