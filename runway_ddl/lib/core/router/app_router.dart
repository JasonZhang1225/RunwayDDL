import 'package:go_router/go_router.dart';
import 'package:runway_ddl/presentation/pages/home/home_page.dart';
import 'package:runway_ddl/presentation/pages/category/category_page.dart';
import 'package:runway_ddl/presentation/pages/item_detail/item_detail_page.dart';
import 'package:runway_ddl/presentation/pages/add_item/add_item_page.dart';
import 'package:runway_ddl/presentation/pages/settings/settings_page.dart';
import 'package:runway_ddl/presentation/pages/settings/api_config_page.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoryPage(),
    ),
    GoRoute(
      path: '/items/new',
      builder: (context, state) => const AddItemPage(),
    ),
    GoRoute(
      path: '/items/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ItemDetailPage(itemId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/settings/api-config',
      builder: (context, state) => const ApiConfigPage(),
    ),
  ],
);
