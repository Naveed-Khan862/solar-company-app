import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_request.dart';
import '../models/user.dart';

final requestCategoryFilterProvider = StateProvider<RequestCategory?>((ref) => null);

final requestStatusFilterProvider = StateProvider<RequestStatus?>((ref) => null);

final adminStatusFilterProvider = StateProvider<RequestStatus?>((ref) => null);

final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

final chatSearchQueryProvider = StateProvider<String>((ref) => '');

final loadingStateProvider = StateProvider<bool>((ref) => true);

final currentUserProvider = StateProvider<UserModel?>((ref) => null);