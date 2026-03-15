import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:runway_ddl/core/constants/app_colors.dart';
import 'package:runway_ddl/presentation/providers/home_data_provider.dart';
import 'package:runway_ddl/presentation/providers/items_provider.dart';
import 'package:runway_ddl/presentation/providers/view_mode_provider.dart';
import 'package:runway_ddl/presentation/pages/home/widgets/overdue_section.dart';
import 'package:runway_ddl/presentation/pages/home/widgets/history_section.dart';
import 'package:runway_ddl/presentation/pages/home/widgets/date_stream_matrix.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homeDataProvider);
    final viewMode = ref.watch(viewModeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RunwayDDL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () =>
                ref.read(viewModeNotifierProvider.notifier).toggle(),
            tooltip: '切换视图',
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.push('/categories'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _buildBody(homeData, viewMode),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(HomePageData homeData, ViewMode viewMode) {
    if (homeData.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        if (homeData.hasOverdue)
          SliverToBoxAdapter(
            child: OverdueSection(
              items: homeData.overdueItems,
              onToggleStatus: (item) => _toggleItemStatus(item.id),
            ),
          ),
        if (homeData.hasHistory)
          SliverToBoxAdapter(
            child: HistorySection(
              items: homeData.historyItems,
              onToggleStatus: (item) => _toggleItemStatus(item.id),
            ),
          ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '未来事项',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ViewModeScope(
            viewMode: viewMode,
            child: DateStreamMatrixWithMode(
              data: homeData.mainStreamMatrix,
              horizontalController: _horizontalScrollController,
              onToggleStatus: (item) => _toggleItemStatus(item.id),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_available,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无事项',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加新事项',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    context.push('/items/new');
  }

  Future<void> _toggleItemStatus(String itemId) async {
    await ref.read(itemsProvider.notifier).toggleStatus(itemId);
  }
}
