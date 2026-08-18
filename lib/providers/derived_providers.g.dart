// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'derived_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userRequestsHash() => r'138a23ca5e15dec22c205f6f04f56e77303dfe38';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [userRequests].
@ProviderFor(userRequests)
const userRequestsProvider = UserRequestsFamily();

/// See also [userRequests].
class UserRequestsFamily extends Family<List<ServiceRequest>> {
  /// See also [userRequests].
  const UserRequestsFamily();

  /// See also [userRequests].
  UserRequestsProvider call(
    UserModel user,
  ) {
    return UserRequestsProvider(
      user,
    );
  }

  @override
  UserRequestsProvider getProviderOverride(
    covariant UserRequestsProvider provider,
  ) {
    return call(
      provider.user,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userRequestsProvider';
}

/// See also [userRequests].
class UserRequestsProvider extends Provider<List<ServiceRequest>> {
  /// See also [userRequests].
  UserRequestsProvider(
    UserModel user,
  ) : this._internal(
          (ref) => userRequests(
            ref as UserRequestsRef,
            user,
          ),
          from: userRequestsProvider,
          name: r'userRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userRequestsHash,
          dependencies: UserRequestsFamily._dependencies,
          allTransitiveDependencies:
              UserRequestsFamily._allTransitiveDependencies,
          user: user,
        );

  UserRequestsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.user,
  }) : super.internal();

  final UserModel user;

  @override
  Override overrideWith(
    List<ServiceRequest> Function(UserRequestsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserRequestsProvider._internal(
        (ref) => create(ref as UserRequestsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        user: user,
      ),
    );
  }

  @override
  ProviderElement<List<ServiceRequest>> createElement() {
    return _UserRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserRequestsProvider && other.user == user;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, user.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserRequestsRef on ProviderRef<List<ServiceRequest>> {
  /// The parameter `user` of this provider.
  UserModel get user;
}

class _UserRequestsProviderElement extends ProviderElement<List<ServiceRequest>>
    with UserRequestsRef {
  _UserRequestsProviderElement(super.provider);

  @override
  UserModel get user => (origin as UserRequestsProvider).user;
}

String _$adminRequestsHash() => r'502a72813fa46927e634eced46c73b1a40cc6633';

/// See also [adminRequests].
@ProviderFor(adminRequests)
const adminRequestsProvider = AdminRequestsFamily();

/// See also [adminRequests].
class AdminRequestsFamily extends Family<List<ServiceRequest>> {
  /// See also [adminRequests].
  const AdminRequestsFamily();

  /// See also [adminRequests].
  AdminRequestsProvider call(
    UserModel user,
  ) {
    return AdminRequestsProvider(
      user,
    );
  }

  @override
  AdminRequestsProvider getProviderOverride(
    covariant AdminRequestsProvider provider,
  ) {
    return call(
      provider.user,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'adminRequestsProvider';
}

/// See also [adminRequests].
class AdminRequestsProvider extends Provider<List<ServiceRequest>> {
  /// See also [adminRequests].
  AdminRequestsProvider(
    UserModel user,
  ) : this._internal(
          (ref) => adminRequests(
            ref as AdminRequestsRef,
            user,
          ),
          from: adminRequestsProvider,
          name: r'adminRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$adminRequestsHash,
          dependencies: AdminRequestsFamily._dependencies,
          allTransitiveDependencies:
              AdminRequestsFamily._allTransitiveDependencies,
          user: user,
        );

  AdminRequestsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.user,
  }) : super.internal();

  final UserModel user;

  @override
  Override overrideWith(
    List<ServiceRequest> Function(AdminRequestsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdminRequestsProvider._internal(
        (ref) => create(ref as AdminRequestsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        user: user,
      ),
    );
  }

  @override
  ProviderElement<List<ServiceRequest>> createElement() {
    return _AdminRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminRequestsProvider && other.user == user;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, user.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AdminRequestsRef on ProviderRef<List<ServiceRequest>> {
  /// The parameter `user` of this provider.
  UserModel get user;
}

class _AdminRequestsProviderElement
    extends ProviderElement<List<ServiceRequest>> with AdminRequestsRef {
  _AdminRequestsProviderElement(super.provider);

  @override
  UserModel get user => (origin as AdminRequestsProvider).user;
}

String _$allRequestsHash() => r'9a57981b31f7651a255eb5fe8316c65040e6ad97';

/// See also [allRequests].
@ProviderFor(allRequests)
final allRequestsProvider = Provider<List<ServiceRequest>>.internal(
  allRequests,
  name: r'allRequestsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allRequestsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllRequestsRef = ProviderRef<List<ServiceRequest>>;
String _$pendingCountHash() => r'69a4836ea641728650e521528b5a39d1a1cbba80';

/// See also [pendingCount].
@ProviderFor(pendingCount)
const pendingCountProvider = PendingCountFamily();

/// See also [pendingCount].
class PendingCountFamily extends Family<int> {
  /// See also [pendingCount].
  const PendingCountFamily();

  /// See also [pendingCount].
  PendingCountProvider call(
    UserModel user,
  ) {
    return PendingCountProvider(
      user,
    );
  }

  @override
  PendingCountProvider getProviderOverride(
    covariant PendingCountProvider provider,
  ) {
    return call(
      provider.user,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'pendingCountProvider';
}

/// See also [pendingCount].
class PendingCountProvider extends Provider<int> {
  /// See also [pendingCount].
  PendingCountProvider(
    UserModel user,
  ) : this._internal(
          (ref) => pendingCount(
            ref as PendingCountRef,
            user,
          ),
          from: pendingCountProvider,
          name: r'pendingCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pendingCountHash,
          dependencies: PendingCountFamily._dependencies,
          allTransitiveDependencies:
              PendingCountFamily._allTransitiveDependencies,
          user: user,
        );

  PendingCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.user,
  }) : super.internal();

  final UserModel user;

  @override
  Override overrideWith(
    int Function(PendingCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingCountProvider._internal(
        (ref) => create(ref as PendingCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        user: user,
      ),
    );
  }

  @override
  ProviderElement<int> createElement() {
    return _PendingCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingCountProvider && other.user == user;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, user.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PendingCountRef on ProviderRef<int> {
  /// The parameter `user` of this provider.
  UserModel get user;
}

class _PendingCountProviderElement extends ProviderElement<int>
    with PendingCountRef {
  _PendingCountProviderElement(super.provider);

  @override
  UserModel get user => (origin as PendingCountProvider).user;
}

String _$inProgressCountHash() => r'bd9f491e2b24c76195655dcc3c0364ba49ac8358';

/// See also [inProgressCount].
@ProviderFor(inProgressCount)
const inProgressCountProvider = InProgressCountFamily();

/// See also [inProgressCount].
class InProgressCountFamily extends Family<int> {
  /// See also [inProgressCount].
  const InProgressCountFamily();

  /// See also [inProgressCount].
  InProgressCountProvider call(
    UserModel user,
  ) {
    return InProgressCountProvider(
      user,
    );
  }

  @override
  InProgressCountProvider getProviderOverride(
    covariant InProgressCountProvider provider,
  ) {
    return call(
      provider.user,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'inProgressCountProvider';
}

/// See also [inProgressCount].
class InProgressCountProvider extends Provider<int> {
  /// See also [inProgressCount].
  InProgressCountProvider(
    UserModel user,
  ) : this._internal(
          (ref) => inProgressCount(
            ref as InProgressCountRef,
            user,
          ),
          from: inProgressCountProvider,
          name: r'inProgressCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$inProgressCountHash,
          dependencies: InProgressCountFamily._dependencies,
          allTransitiveDependencies:
              InProgressCountFamily._allTransitiveDependencies,
          user: user,
        );

  InProgressCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.user,
  }) : super.internal();

  final UserModel user;

  @override
  Override overrideWith(
    int Function(InProgressCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InProgressCountProvider._internal(
        (ref) => create(ref as InProgressCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        user: user,
      ),
    );
  }

  @override
  ProviderElement<int> createElement() {
    return _InProgressCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InProgressCountProvider && other.user == user;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, user.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin InProgressCountRef on ProviderRef<int> {
  /// The parameter `user` of this provider.
  UserModel get user;
}

class _InProgressCountProviderElement extends ProviderElement<int>
    with InProgressCountRef {
  _InProgressCountProviderElement(super.provider);

  @override
  UserModel get user => (origin as InProgressCountProvider).user;
}

String _$resolvedCountHash() => r'1c6546e4387adae90750cd1f8f8e20eafb2687b2';

/// See also [resolvedCount].
@ProviderFor(resolvedCount)
const resolvedCountProvider = ResolvedCountFamily();

/// See also [resolvedCount].
class ResolvedCountFamily extends Family<int> {
  /// See also [resolvedCount].
  const ResolvedCountFamily();

  /// See also [resolvedCount].
  ResolvedCountProvider call(
    UserModel user,
  ) {
    return ResolvedCountProvider(
      user,
    );
  }

  @override
  ResolvedCountProvider getProviderOverride(
    covariant ResolvedCountProvider provider,
  ) {
    return call(
      provider.user,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'resolvedCountProvider';
}

/// See also [resolvedCount].
class ResolvedCountProvider extends Provider<int> {
  /// See also [resolvedCount].
  ResolvedCountProvider(
    UserModel user,
  ) : this._internal(
          (ref) => resolvedCount(
            ref as ResolvedCountRef,
            user,
          ),
          from: resolvedCountProvider,
          name: r'resolvedCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$resolvedCountHash,
          dependencies: ResolvedCountFamily._dependencies,
          allTransitiveDependencies:
              ResolvedCountFamily._allTransitiveDependencies,
          user: user,
        );

  ResolvedCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.user,
  }) : super.internal();

  final UserModel user;

  @override
  Override overrideWith(
    int Function(ResolvedCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ResolvedCountProvider._internal(
        (ref) => create(ref as ResolvedCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        user: user,
      ),
    );
  }

  @override
  ProviderElement<int> createElement() {
    return _ResolvedCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ResolvedCountProvider && other.user == user;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, user.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ResolvedCountRef on ProviderRef<int> {
  /// The parameter `user` of this provider.
  UserModel get user;
}

class _ResolvedCountProviderElement extends ProviderElement<int>
    with ResolvedCountRef {
  _ResolvedCountProviderElement(super.provider);

  @override
  UserModel get user => (origin as ResolvedCountProvider).user;
}

String _$avgRatingHash() => r'2aa44468bd87bf3357e621fa9dc797839746a4df';

/// See also [avgRating].
@ProviderFor(avgRating)
const avgRatingProvider = AvgRatingFamily();

/// See also [avgRating].
class AvgRatingFamily extends Family<double> {
  /// See also [avgRating].
  const AvgRatingFamily();

  /// See also [avgRating].
  AvgRatingProvider call(
    UserModel user,
  ) {
    return AvgRatingProvider(
      user,
    );
  }

  @override
  AvgRatingProvider getProviderOverride(
    covariant AvgRatingProvider provider,
  ) {
    return call(
      provider.user,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'avgRatingProvider';
}

/// See also [avgRating].
class AvgRatingProvider extends Provider<double> {
  /// See also [avgRating].
  AvgRatingProvider(
    UserModel user,
  ) : this._internal(
          (ref) => avgRating(
            ref as AvgRatingRef,
            user,
          ),
          from: avgRatingProvider,
          name: r'avgRatingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$avgRatingHash,
          dependencies: AvgRatingFamily._dependencies,
          allTransitiveDependencies: AvgRatingFamily._allTransitiveDependencies,
          user: user,
        );

  AvgRatingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.user,
  }) : super.internal();

  final UserModel user;

  @override
  Override overrideWith(
    double Function(AvgRatingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AvgRatingProvider._internal(
        (ref) => create(ref as AvgRatingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        user: user,
      ),
    );
  }

  @override
  ProviderElement<double> createElement() {
    return _AvgRatingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AvgRatingProvider && other.user == user;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, user.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AvgRatingRef on ProviderRef<double> {
  /// The parameter `user` of this provider.
  UserModel get user;
}

class _AvgRatingProviderElement extends ProviderElement<double>
    with AvgRatingRef {
  _AvgRatingProviderElement(super.provider);

  @override
  UserModel get user => (origin as AvgRatingProvider).user;
}

String _$unreadNotificationsHash() =>
    r'6dbf318bb45c5f7d1caaa8905a5ebf2a16ea5771';

/// See also [unreadNotifications].
@ProviderFor(unreadNotifications)
final unreadNotificationsProvider = Provider<int>.internal(
  unreadNotifications,
  name: r'unreadNotificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadNotificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UnreadNotificationsRef = ProviderRef<int>;
String _$weeklyChartDataHash() => r'bf99ac5125b0b69b155c6137c00af0ea4a85feb6';

/// See also [weeklyChartData].
@ProviderFor(weeklyChartData)
const weeklyChartDataProvider = WeeklyChartDataFamily();

/// See also [weeklyChartData].
class WeeklyChartDataFamily extends Family<List<ServiceRequest>> {
  /// See also [weeklyChartData].
  const WeeklyChartDataFamily();

  /// See also [weeklyChartData].
  WeeklyChartDataProvider call(
    UserModel user,
  ) {
    return WeeklyChartDataProvider(
      user,
    );
  }

  @override
  WeeklyChartDataProvider getProviderOverride(
    covariant WeeklyChartDataProvider provider,
  ) {
    return call(
      provider.user,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'weeklyChartDataProvider';
}

/// See also [weeklyChartData].
class WeeklyChartDataProvider extends Provider<List<ServiceRequest>> {
  /// See also [weeklyChartData].
  WeeklyChartDataProvider(
    UserModel user,
  ) : this._internal(
          (ref) => weeklyChartData(
            ref as WeeklyChartDataRef,
            user,
          ),
          from: weeklyChartDataProvider,
          name: r'weeklyChartDataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$weeklyChartDataHash,
          dependencies: WeeklyChartDataFamily._dependencies,
          allTransitiveDependencies:
              WeeklyChartDataFamily._allTransitiveDependencies,
          user: user,
        );

  WeeklyChartDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.user,
  }) : super.internal();

  final UserModel user;

  @override
  Override overrideWith(
    List<ServiceRequest> Function(WeeklyChartDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeeklyChartDataProvider._internal(
        (ref) => create(ref as WeeklyChartDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        user: user,
      ),
    );
  }

  @override
  ProviderElement<List<ServiceRequest>> createElement() {
    return _WeeklyChartDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyChartDataProvider && other.user == user;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, user.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WeeklyChartDataRef on ProviderRef<List<ServiceRequest>> {
  /// The parameter `user` of this provider.
  UserModel get user;
}

class _WeeklyChartDataProviderElement
    extends ProviderElement<List<ServiceRequest>> with WeeklyChartDataRef {
  _WeeklyChartDataProviderElement(super.provider);

  @override
  UserModel get user => (origin as WeeklyChartDataProvider).user;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
