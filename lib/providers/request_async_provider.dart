import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_request.dart';
import '../models/user.dart';
import 'repository_providers.dart';

/// AsyncNotifier for request data scoped to the current user.
/// Provides loading / error / data states via AsyncValue.
///
/// Usage in screens:
/// ```dart
/// final asyncReq = ref.watch(scopedRequestsAsyncProvider(user));
/// asyncReq.when(
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => ErrorWidget(retry: ...),
///   data: (requests) => ListView(...),
/// );
/// ```
class ScopedRequestsAsyncNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ServiceRequest>, UserModel> {
  @override
  Future<List<ServiceRequest>> build(UserModel user) async {
    // Reactivity: every repo mutation (load/add/assign/status/rate)
    // emits a revision → this provider rebuilds. Without it the provider
    // built once and then stayed stale/empty.
    ref.watch(requestRevisionsProvider);
    final repo = ref.read(requestRepositoryProvider);
    if (user.isSuperAdmin) return repo.all;
    if (user.isSubAdmin) return repo.assignedTo(user.email);
    return repo.forUser(user.email);
  }

  /// Refresh from Firestore (pull-to-refresh, retry on error).
  Future<void> refresh(UserModel user) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(user));
  }

  /// Apply local filters — does NOT re-fetch, just filters cached data.
  List<ServiceRequest> filtered({
    RequestCategory? category,
    RequestStatus? status,
  }) {
    final requests = state.valueOrNull ?? [];
    return requests.where((r) {
      if (category != null && r.category != category) return false;
      if (status != null && r.status != status) return false;
      return true;
    }).toList();
  }
}

/// User-scoped requests with loading/error states.
final scopedRequestsAsyncProvider =
    AutoDisposeAsyncNotifierProvider.family<ScopedRequestsAsyncNotifier,
        List<ServiceRequest>, UserModel>(
  ScopedRequestsAsyncNotifier.new,
);

/// Convenience: scoped request counts with loading/error states.
final scopedCountAsyncProvider = Provider.family<AsyncValue<int>,
    ({UserModel user, RequestStatus status})>((ref, params) {
  final asyncReq = ref.watch(scopedRequestsAsyncProvider(params.user));
  return asyncReq.whenData(
    (requests) =>
        requests.where((r) => r.status == params.status).length,
  );
});

/// Convenience: average rating with loading/error state.
final avgRatingAsyncProvider =
    Provider.family<AsyncValue<double>, UserModel>((ref, user) {
  final asyncReq = ref.watch(scopedRequestsAsyncProvider(user));
  return asyncReq.whenData((requests) {
    final rated =
        requests.where((r) => r.isRated).map((r) => r.rating).toList();
    if (rated.isEmpty) return 0.0;
    return rated.reduce((a, b) => a + b) / rated.length;
  });
});
