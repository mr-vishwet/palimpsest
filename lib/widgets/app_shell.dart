import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../state/archive_controller.dart';
import '../state/ask_controller.dart';
import '../state/auth_controller.dart';

/// Makes the three controllers available to every screen below it.
class AppScope extends InheritedWidget {
  /// Creates the scope.
  const AppScope({
    required this.archive,
    required this.ask,
    required this.auth,
    required super.child,
    super.key,
  });

  /// The archive controller.
  final ArchiveController archive;

  /// The ask-flow controller.
  final AskController ask;

  /// The auth controller.
  final AuthController auth;

  /// Looks up the scope above [context].
  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      archive != oldWidget.archive ||
      ask != oldWidget.ask ||
      auth != oldWidget.auth;
}

/// The five main tabs.
class _Tab {
  const _Tab(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

const List<_Tab> _tabs = <_Tab>[
  _Tab('Home', Icons.home_outlined, Routes.home),
  _Tab('Ask', Icons.search, Routes.ask),
  _Tab('Library', Icons.grid_view_outlined, Routes.library),
  _Tab('Timeline', Icons.timeline_outlined, Routes.timeline),
  _Tab('Account', Icons.person_outline, Routes.account),
];

/// The responsive app shell: bottom navigation on mobile, a side rail
/// on wide layouts, warm charcoal space gradient behind everything.
///
/// Each screen passes its mobile body and its wide body; the shell
/// picks by [AppConstants.wideBreakpoint]. Set [showNav] false for
/// the onboarding and auth flows, which stand outside the tab bar.
class ResponsiveScaffold extends StatelessWidget {
  /// Creates the shell.
  const ResponsiveScaffold({
    required this.title,
    required this.mobile,
    required this.wide,
    this.tabIndex = -1,
    this.actions,
    this.showNav = true,
    this.floatingActionButton,
    super.key,
  });

  /// AppBar title.
  final String title;

  /// Mobile layout body.
  final Widget mobile;

  /// Wide (web) layout body.
  final Widget wide;

  /// Selected tab index (0–4), or -1 when no tab is selected.
  final int tabIndex;

  /// AppBar actions.
  final List<Widget>? actions;

  /// Whether to show the bottom nav / side rail.
  final bool showNav;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  void _goToTab(BuildContext context, int index) {
    if (index == tabIndex) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      _tabs[index].route,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppConstants.wideBreakpoint;
    const palette = Palette.v7;

    final body = Container(
      decoration: BoxDecoration(gradient: palette.spaceGradient),
      child: SafeArea(
        child: isWide
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.wideMaxWidth,
                  ),
                  child: wide,
                ),
              )
            : mobile,
      ),
    );

    if (isWide) {
      return Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        floatingActionButton: floatingActionButton,
        body: Row(
          children: <Widget>[
            if (showNav)
              NavigationRail(
                backgroundColor: palette.bg1,
                selectedIndex: tabIndex < 0 ? null : tabIndex,
                onDestinationSelected: (index) => _goToTab(context, index),
                leading: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SvgPicture.asset(
                    'assets/logos/icon.svg',
                    width: 36,
                    height: 36,
                  ),
                ),
                destinations: _tabs
                    .map(
                      (tab) => NavigationRailDestination(
                        icon: Icon(tab.icon),
                        label: Text(tab.label),
                      ),
                    )
                    .toList(growable: false),
              ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: body,
      bottomNavigationBar: showNav
          ? BottomNavigationBar(
              backgroundColor: palette.bg1,
              selectedItemColor: palette.gold,
              unselectedItemColor: palette.muted,
              type: BottomNavigationBarType.fixed,
              currentIndex: tabIndex < 0 ? 0 : tabIndex,
              onTap: (index) => _goToTab(context, index),
              items: _tabs
                  .map(
                    (tab) => BottomNavigationBarItem(
                      icon: Icon(tab.icon),
                      label: tab.label,
                    ),
                  )
                  .toList(growable: false),
            )
          : null,
    );
  }
}
