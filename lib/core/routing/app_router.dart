import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/account/account_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/checkout/checkout_screen.dart';
import '../../presentation/screens/checkout/address_edit_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/chat/order_chat_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/home/popular_items_screen.dart';
import '../../presentation/screens/inbox/inbox_screen.dart';
import '../../presentation/screens/menu/category_menu_screen.dart';
import '../../presentation/screens/menu/menu_item_detail_screen.dart';
import '../../presentation/screens/menu/search_screen.dart';
import '../../presentation/screens/payment/paystack_checkout_screen.dart';
import '../../presentation/screens/orders/orders_screen.dart';
import '../../presentation/screens/orders/order_tracking_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/reviews/order_review_screen.dart';
import '../../presentation/screens/profile/profile_setup_screen.dart';
import '../../presentation/screens/shell/app_scaffold.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/welcome/welcome_screen.dart';
import '../../domain/entities/address.dart';

class AppRouter {
  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: SplashScreen.routePath,
      refreshListenable: auth,
      routes: [
        GoRoute(
          path: SplashScreen.routePath,
          pageBuilder: (context, state) => _fade(state.pageKey, const SplashScreen()),
        ),
        GoRoute(
          path: OnboardingScreen.routePath,
          pageBuilder: (context, state) => _fade(state.pageKey, const OnboardingScreen()),
        ),
        GoRoute(
          path: WelcomeScreen.routePath,
          pageBuilder: (context, state) => _fade(state.pageKey, const WelcomeScreen()),
        ),
        GoRoute(
          path: LoginScreen.routePath,
          pageBuilder: (context, state) => _slideUp(state.pageKey, const LoginScreen()),
        ),
        GoRoute(
          path: SignupScreen.routePath,
          pageBuilder: (context, state) => _slideUp(state.pageKey, const SignupScreen()),
        ),
        GoRoute(
          path: PaystackCheckoutScreen.routePath,
          pageBuilder: (context, state) {
            final args = state.extra is PaystackCheckoutArgs ? state.extra as PaystackCheckoutArgs : null;
            return _slideUp(
              state.pageKey,
              args == null ? const SizedBox.shrink() : PaystackCheckoutScreen(args: args),
            );
          },
        ),
        GoRoute(
          path: ProfileSetupScreen.routePath,
          pageBuilder: (context, state) => _slideUp(state.pageKey, const ProfileSetupScreen()),
        ),
        GoRoute(
          path: CartScreen.routePath,
          pageBuilder: (context, state) => _slideUp(state.pageKey, const CartScreen()),
        ),
        GoRoute(
          path: CheckoutScreen.routePath,
          pageBuilder: (context, state) => _slideUp(state.pageKey, const CheckoutScreen()),
        ),
        GoRoute(
          path: AddressEditScreen.routePath,
          pageBuilder: (context, state) => _slideUp(
            state.pageKey,
            AddressEditScreen(initial: state.extra is Address ? state.extra as Address : null),
          ),
        ),
        GoRoute(
          path: OrderTrackingScreen.routePath,
          pageBuilder: (context, state) => _fade(
            state.pageKey,
            OrderTrackingScreen(orderId: state.pathParameters['orderId']!),
          ),
        ),
        GoRoute(
          path: OrderChatScreen.routePath,
          pageBuilder: (context, state) => _slideUp(
            state.pageKey,
            OrderChatScreen(orderId: state.pathParameters['orderId']!),
          ),
        ),
        GoRoute(
          path: OrderReviewScreen.routePath,
          pageBuilder: (context, state) => _slideUp(
            state.pageKey,
            OrderReviewScreen(orderId: state.pathParameters['orderId']!),
          ),
        ),
        GoRoute(
          path: InboxScreen.routePath,
          pageBuilder: (context, state) => _fade(state.pageKey, const InboxScreen()),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppScaffold(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: HomeScreen.routePath,
                  pageBuilder: (context, state) => _fade(state.pageKey, const HomeScreen()),
                  routes: [
                    GoRoute(
                      path: 'search',
                      pageBuilder: (context, state) => _slideUp(state.pageKey, const SearchScreen()),
                    ),
                    GoRoute(
                      path: 'popular',
                      pageBuilder: (context, state) => _fade(state.pageKey, const PopularItemsScreen()),
                    ),
                    GoRoute(
                      path: 'category/:categoryId',
                      pageBuilder: (context, state) => _fade(
                        state.pageKey,
                        CategoryMenuScreen(categoryId: state.pathParameters['categoryId']!),
                      ),
                    ),
                    GoRoute(
                      path: 'item/:itemId',
                      pageBuilder: (context, state) => _slideUp(
                        state.pageKey,
                        MenuItemDetailScreen(itemId: state.pathParameters['itemId']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: OrdersScreen.routePath,
                  pageBuilder: (context, state) => _fade(state.pageKey, const OrdersScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: ChatScreen.routePath,
                  pageBuilder: (context, state) => _fade(state.pageKey, const ChatScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AccountScreen.routePath,
                  pageBuilder: (context, state) => _fade(state.pageKey, const AccountScreen()),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static CustomTransitionPage<void> _fade(LocalKey key, Widget child) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondary, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        );
      },
    );
  }

  static CustomTransitionPage<void> _slideUp(LocalKey key, Widget child) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondary, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final offset = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(fade);
        return FadeTransition(opacity: fade, child: SlideTransition(position: offset, child: child));
      },
    );
  }
}
