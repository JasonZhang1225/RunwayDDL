// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$itemByIdHash() => r'86f51bba6305cf80828ca797d86ac122ae42f03c';

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

/// See also [itemById].
@ProviderFor(itemById)
const itemByIdProvider = ItemByIdFamily();

/// See also [itemById].
class ItemByIdFamily extends Family<Item?> {
  /// See also [itemById].
  const ItemByIdFamily();

  /// See also [itemById].
  ItemByIdProvider call(
    String id,
  ) {
    return ItemByIdProvider(
      id,
    );
  }

  @override
  ItemByIdProvider getProviderOverride(
    covariant ItemByIdProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'itemByIdProvider';
}

/// See also [itemById].
class ItemByIdProvider extends AutoDisposeProvider<Item?> {
  /// See also [itemById].
  ItemByIdProvider(
    String id,
  ) : this._internal(
          (ref) => itemById(
            ref as ItemByIdRef,
            id,
          ),
          from: itemByIdProvider,
          name: r'itemByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$itemByIdHash,
          dependencies: ItemByIdFamily._dependencies,
          allTransitiveDependencies: ItemByIdFamily._allTransitiveDependencies,
          id: id,
        );

  ItemByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    Item? Function(ItemByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ItemByIdProvider._internal(
        (ref) => create(ref as ItemByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Item?> createElement() {
    return _ItemByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ItemByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ItemByIdRef on AutoDisposeProviderRef<Item?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ItemByIdProviderElement extends AutoDisposeProviderElement<Item?>
    with ItemByIdRef {
  _ItemByIdProviderElement(super.provider);

  @override
  String get id => (origin as ItemByIdProvider).id;
}

String _$itemsByCategoryHash() => r'00b641c479bc1525d5947cc7f2cf0abfe2e473f6';

/// See also [itemsByCategory].
@ProviderFor(itemsByCategory)
const itemsByCategoryProvider = ItemsByCategoryFamily();

/// See also [itemsByCategory].
class ItemsByCategoryFamily extends Family<List<Item>> {
  /// See also [itemsByCategory].
  const ItemsByCategoryFamily();

  /// See also [itemsByCategory].
  ItemsByCategoryProvider call(
    String categoryId,
  ) {
    return ItemsByCategoryProvider(
      categoryId,
    );
  }

  @override
  ItemsByCategoryProvider getProviderOverride(
    covariant ItemsByCategoryProvider provider,
  ) {
    return call(
      provider.categoryId,
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
  String? get name => r'itemsByCategoryProvider';
}

/// See also [itemsByCategory].
class ItemsByCategoryProvider extends AutoDisposeProvider<List<Item>> {
  /// See also [itemsByCategory].
  ItemsByCategoryProvider(
    String categoryId,
  ) : this._internal(
          (ref) => itemsByCategory(
            ref as ItemsByCategoryRef,
            categoryId,
          ),
          from: itemsByCategoryProvider,
          name: r'itemsByCategoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$itemsByCategoryHash,
          dependencies: ItemsByCategoryFamily._dependencies,
          allTransitiveDependencies:
              ItemsByCategoryFamily._allTransitiveDependencies,
          categoryId: categoryId,
        );

  ItemsByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
  }) : super.internal();

  final String categoryId;

  @override
  Override overrideWith(
    List<Item> Function(ItemsByCategoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ItemsByCategoryProvider._internal(
        (ref) => create(ref as ItemsByCategoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<Item>> createElement() {
    return _ItemsByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ItemsByCategoryProvider && other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ItemsByCategoryRef on AutoDisposeProviderRef<List<Item>> {
  /// The parameter `categoryId` of this provider.
  String get categoryId;
}

class _ItemsByCategoryProviderElement
    extends AutoDisposeProviderElement<List<Item>> with ItemsByCategoryRef {
  _ItemsByCategoryProviderElement(super.provider);

  @override
  String get categoryId => (origin as ItemsByCategoryProvider).categoryId;
}

String _$overdueItemsHash() => r'8aeaafa250fd533d2861e97f157a2a82f11bb1e3';

/// See also [overdueItems].
@ProviderFor(overdueItems)
final overdueItemsProvider = AutoDisposeProvider<List<Item>>.internal(
  overdueItems,
  name: r'overdueItemsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$overdueItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef OverdueItemsRef = AutoDisposeProviderRef<List<Item>>;
String _$historyItemsHash() => r'36bc88e6798b26f92f3c76b4ed1e4b2d1885bd14';

/// See also [historyItems].
@ProviderFor(historyItems)
final historyItemsProvider = AutoDisposeProvider<List<Item>>.internal(
  historyItems,
  name: r'historyItemsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$historyItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HistoryItemsRef = AutoDisposeProviderRef<List<Item>>;
String _$itemsHash() => r'cf6bf35632e2750af2360ef72f2c4aa31e8e584f';

/// See also [Items].
@ProviderFor(Items)
final itemsProvider =
    AutoDisposeAsyncNotifierProvider<Items, List<Item>>.internal(
  Items.new,
  name: r'itemsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$itemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Items = AutoDisposeAsyncNotifier<List<Item>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
