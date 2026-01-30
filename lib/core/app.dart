import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/datasources/profile_supabase_datasource.dart';
import '../data/datasources/delivery_settings_supabase_datasource.dart';
import '../data/datasources/menu_supabase_datasource.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../data/repositories/delivery_settings_repository_impl.dart';
import '../data/repositories/menu_repository_impl.dart';
import '../data/repositories/cart_repository_impl.dart';
import '../data/datasources/address_supabase_datasource.dart';
import '../data/repositories/address_repository_impl.dart';
import '../data/datasources/order_supabase_datasource.dart';
import '../data/datasources/chat_supabase_datasource.dart';
import '../data/datasources/notification_supabase_datasource.dart';
import '../data/datasources/review_supabase_datasource.dart';
import '../data/repositories/order_repository_impl.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../data/repositories/review_repository_impl.dart';
import '../data/services/supabase_storage_service.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/address_provider.dart';
import '../presentation/providers/cart_provider.dart';
import '../presentation/providers/delivery_settings_provider.dart';
import '../presentation/providers/menu_provider.dart';
import '../presentation/providers/order_provider.dart';
import '../presentation/providers/notification_provider.dart';
import '../presentation/providers/profile_provider.dart';
import '../presentation/screens/setup/supabase_setup_screen.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/repositories/cart_repository.dart';
import '../domain/repositories/address_repository.dart';
import '../domain/repositories/order_repository.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/review_repository.dart';
import '../domain/repositories/menu_repository.dart';
import '../domain/repositories/delivery_settings_repository.dart';
import 'constants/app_strings.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key, required this.isSupabaseConfigured});

  final bool isSupabaseConfigured;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light();
    final darkTheme = AppTheme.dark();

    if (!isSupabaseConfigured) {
      return MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const SupabaseSetupScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider<SupabaseClient>(create: (_) => Supabase.instance.client),
        Provider<SupabaseStorageService>(
          create: (context) => SupabaseStorageService(context.read<SupabaseClient>()),
        ),
        Provider<MenuRepository>(
          create: (context) => MenuRepositoryImpl(
            MenuSupabaseDatasource(context.read<SupabaseClient>()),
            context.read<SupabaseStorageService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => MenuProvider(repository: context.read<MenuRepository>()),
        ),
        Provider<DeliverySettingsRepository>(
          create: (context) => DeliverySettingsRepositoryImpl(
            DeliverySettingsSupabaseDatasource(context.read<SupabaseClient>()),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              DeliverySettingsProvider(repository: context.read<DeliverySettingsRepository>()),
        ),
        Provider<CartRepository>(create: (_) => CartRepositoryImpl()),
        ChangeNotifierProxyProvider3<MenuRepository, CartRepository, DeliverySettingsProvider,
            CartProvider>(
          create: (context) => CartProvider(
            repository: context.read<CartRepository>(),
            menuRepository: context.read<MenuRepository>(),
            deliveryBaseFee: context.read<DeliverySettingsProvider>().baseFee,
            minimumOrderSubtotal: context.read<DeliverySettingsProvider>().minimumOrderAmount,
          ),
          update: (context, menuRepo, cartRepo, delivery, provider) {
            provider ??= CartProvider(
              repository: cartRepo,
              menuRepository: menuRepo,
              deliveryBaseFee: delivery.baseFee,
              minimumOrderSubtotal: delivery.minimumOrderAmount,
            );
            provider.setDeliveryRules(
              deliveryBaseFee: delivery.baseFee,
              minimumOrderSubtotal: delivery.minimumOrderAmount,
            );
            return provider;
          },
        ),
        Provider<AddressRepository>(
          create: (context) => AddressRepositoryImpl(
            AddressSupabaseDatasource(context.read<SupabaseClient>()),
          ),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, AddressRepository, AddressProvider>(
          create: (context) => AddressProvider(repository: context.read<AddressRepository>()),
          update: (context, auth, repo, provider) {
            provider ??= AddressProvider(repository: repo);
            provider.setUserId(auth.user?.id);
            return provider;
          },
        ),
        Provider<OrderRepository>(
          create: (context) => OrderRepositoryImpl(
            OrderSupabaseDatasource(context.read<SupabaseClient>()),
          ),
        ),
        Provider<ChatRepository>(
          create: (context) => ChatRepositoryImpl(
            ChatSupabaseDatasource(context.read<SupabaseClient>()),
          ),
        ),
        Provider<NotificationRepository>(
          create: (context) => NotificationRepositoryImpl(
            NotificationSupabaseDatasource(context.read<SupabaseClient>()),
          ),
        ),
        Provider<ReviewRepository>(
          create: (context) => ReviewRepositoryImpl(
            ReviewSupabaseDatasource(context.read<SupabaseClient>()),
          ),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, NotificationRepository, NotificationProvider>(
          create: (context) =>
              NotificationProvider(repository: context.read<NotificationRepository>()),
          update: (context, auth, repo, provider) {
            provider ??= NotificationProvider(repository: repo);
            provider.setUserId(auth.user?.id);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<AuthProvider, OrderRepository, OrderProvider>(
          create: (context) => OrderProvider(repository: context.read<OrderRepository>()),
          update: (context, auth, repo, provider) {
            provider ??= OrderProvider(repository: repo);
            provider.setUserId(auth.user?.id);
            return provider;
          },
        ),
        Provider<ProfileRepository>(
          create: (context) => ProfileRepositoryImpl(
            ProfileSupabaseDatasource(context.read<SupabaseClient>()),
          ),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, ProfileRepository, ProfileProvider>(
          create: (context) => ProfileProvider(repository: context.read<ProfileRepository>()),
          update: (context, auth, repo, provider) {
            provider ??= ProfileProvider(repository: repo);
            provider.setUserId(auth.user?.id);
            return provider;
          },
        ),
        Provider<GoRouter>(create: (context) => AppRouter.create(context.read<AuthProvider>())),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: context.read<GoRouter>(),
          );
        },
      ),
    );
  }
}
