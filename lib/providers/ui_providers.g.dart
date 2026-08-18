// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$requestCategoryFilterHash() =>
    r'aee828714d45a6da1d561b41aaa0539e5af6d23a';

/// See also [RequestCategoryFilter].
@ProviderFor(RequestCategoryFilter)
final requestCategoryFilterProvider =
    NotifierProvider<RequestCategoryFilter, RequestCategory?>.internal(
  RequestCategoryFilter.new,
  name: r'requestCategoryFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$requestCategoryFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RequestCategoryFilter = Notifier<RequestCategory?>;
String _$requestStatusFilterHash() =>
    r'6ab778aa9f641e48e52b2bd9828310e837eb8bde';

/// See also [RequestStatusFilter].
@ProviderFor(RequestStatusFilter)
final requestStatusFilterProvider =
    NotifierProvider<RequestStatusFilter, RequestStatus?>.internal(
  RequestStatusFilter.new,
  name: r'requestStatusFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$requestStatusFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RequestStatusFilter = Notifier<RequestStatus?>;
String _$adminStatusFilterHash() => r'dce84832f3bbe4bc8410e5aa06b00be47ea6d6b3';

/// See also [AdminStatusFilter].
@ProviderFor(AdminStatusFilter)
final adminStatusFilterProvider =
    NotifierProvider<AdminStatusFilter, RequestStatus?>.internal(
  AdminStatusFilter.new,
  name: r'adminStatusFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminStatusFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdminStatusFilter = Notifier<RequestStatus?>;
String _$selectedTabIndexHash() => r'832f9fcf868a3a7a04f756ffbb07c7686181d641';

/// See also [SelectedTabIndex].
@ProviderFor(SelectedTabIndex)
final selectedTabIndexProvider =
    NotifierProvider<SelectedTabIndex, int>.internal(
  SelectedTabIndex.new,
  name: r'selectedTabIndexProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedTabIndexHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedTabIndex = Notifier<int>;
String _$chatSearchQueryHash() => r'2889e1aac5108b79f7a68a1eef73d7621539e44f';

/// See also [ChatSearchQuery].
@ProviderFor(ChatSearchQuery)
final chatSearchQueryProvider =
    NotifierProvider<ChatSearchQuery, String>.internal(
  ChatSearchQuery.new,
  name: r'chatSearchQueryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatSearchQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatSearchQuery = Notifier<String>;
String _$loadingStateHash() => r'3cc3a85d75bd7c95cf168b4c61d8d68350ededed';

/// See also [LoadingState].
@ProviderFor(LoadingState)
final loadingStateProvider = NotifierProvider<LoadingState, bool>.internal(
  LoadingState.new,
  name: r'loadingStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$loadingStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LoadingState = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
