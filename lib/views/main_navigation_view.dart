import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:hane/views/dashboard_view.dart';
import 'package:hane/views/profil_view.dart';
import 'package:hane/views/hareketler_view.dart';
import 'package:hane/views/projeler_view.dart';
import 'package:hane/views/yeni_islem_view.dart';
import 'package:hane/views/bildirimler_view.dart' as hano_bildirimler;
import 'package:hane/views/widgets/bottom_navbar.dart';
import 'package:hane/views/widgets/desktop_sidebar.dart';
import 'package:hane/views/widgets/zeynep_drawer.dart';
import 'package:hane/views/widgets/new_transaction_panel.dart';
import 'package:hane/views/yeni_proje_view.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentTabIndex = 0;
  String _selectedTransactionType = 'Ödeme';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _navbarToPageViewIndex(_currentTabIndex));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _navbarToPageViewIndex(int navbarIndex) {
    if (navbarIndex < 2) return navbarIndex;
    if (navbarIndex > 2) return navbarIndex - 1;
    return 0; // fallback
  }

  String _getHeaderTitle(int index) {
    switch (index) {
      case 0:
        return 'Genel Bakış';
      case 1:
        return 'Projeler';
      case 3:
        return 'Hareketler';
      case 4:
        return 'Profil';
      default:
        return 'Genel Bakış';
    }
  }

  // Methods to change tabs from the sidebar drawer or sub-pages
  void _selectTab(int index) {
    final int oldIndex = _currentTabIndex;
    setState(() {
      _currentTabIndex = index;
    });
    if (_pageController.hasClients) {
      if (index == 2) {
        // Overlay will slide in, no need to slide PageView
      } else if (oldIndex == 2) {
        // Coming back from YeniIslem, jump to target page instantly
        _pageController.jumpToPage(_navbarToPageViewIndex(index));
      } else {
        // Regular tab animation
        _pageController.animateToPage(
          _navbarToPageViewIndex(index),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _showNewTransactionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NewTransactionPanel(
        onTypeSelected: (type) {
          setState(() {
            _selectedTransactionType = type == 'Borç' ? 'Borçlanma' : type;
          });
          _selectTab(2);
        },
      ),
    ).whenComplete(() {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  List<Widget> get _screens => [
        DashboardScreen(),
        ProjelerScreen(),
        HareketlerView(),
        const ProfilScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return context.isDesktop ? _buildDesktop(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    final List<Widget> screens = _screens;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.colors.scaffold,
      drawer: ZeynepDrawer(
        selectedIndex: _currentTabIndex,
        onItemSelected: (index) {
          _selectTab(index);
        },
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (_currentTabIndex != 2)
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 12.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.menu_rounded, color: context.colors.brand, size: 28),
                              onPressed: () {
                                _scaffoldKey.currentState?.openDrawer();
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getHeaderTitle(_currentTabIndex),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        _currentTabIndex == 1
                            ? _yeniProjeButton(context)
                            : _notificationBell(context),
                      ],
                    ),
                  ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      int navbarIndex = index;
                      if (index >= 2) {
                        navbarIndex = index + 1;
                      }
                      setState(() {
                        _currentTabIndex = navbarIndex;
                      });
                    },
                    physics: const BouncingScrollPhysics(),
                    children: screens,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSlide(
            offset: _currentTabIndex == 2 ? Offset.zero : const Offset(1.0, 0.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: IgnorePointer(
              ignoring: _currentTabIndex != 2,
              child: YeniIslemScreen(
                initialType: _selectedTransactionType,
                onBack: () => _selectTab(0),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _currentTabIndex == 2
          ? null
          : CustomBottomNavbar(
              selectedIndex: _currentTabIndex,
              onTabSelected: (index) {
                if (index == 2) {
                  _showNewTransactionOptions(context);
                } else {
                  _selectTab(index);
                }
              },
            ),
    );
  }

  /// Geniş ekran (masaüstü/web) düzeni: kalıcı sol kenar menü + içerik.
  Widget _buildDesktop(BuildContext context) {
    final List<Widget> screens = _screens;
    final bool showTopBar = _currentTabIndex != 2;

    return Scaffold(
      backgroundColor: context.colors.scaffold,
      body: Row(
        children: [
          DesktopSidebar(
            selectedIndex: _currentTabIndex,
            onItemSelected: _selectTab,
            onNewTransaction: () => _showNewTransactionOptions(context),
          ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  if (showTopBar)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 20, 32, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getHeaderTitle(_currentTabIndex),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          _currentTabIndex == 1
                              ? _yeniProjeButton(context)
                              : _notificationBell(context),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            int navbarIndex = index;
                            if (index >= 2) {
                              navbarIndex = index + 1;
                            }
                            setState(() {
                              _currentTabIndex = navbarIndex;
                            });
                          },
                          physics: const NeverScrollableScrollPhysics(),
                          children: screens,
                        ),
                        AnimatedSlide(
                          offset: _currentTabIndex == 2 ? Offset.zero : const Offset(1.0, 0.0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: IgnorePointer(
                            ignoring: _currentTabIndex != 2,
                            child: YeniIslemScreen(
                              initialType: _selectedTransactionType,
                              onBack: () => _selectTab(0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "+ Yeni Proje Ekle" butonu (Projeler sekmesinde gösterilir).
  Widget _yeniProjeButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => YeniProjeView()));
      },
      style: TextButton.styleFrom(
        foregroundColor: context.colors.brand,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: const Text(
        '+ Yeni Proje Ekle',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Bildirim zili (üst köşe) — okunmamış varsa kırmızı nokta gösterir.
  Widget _notificationBell(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none_rounded, color: context.colors.textSecondary, size: 28),
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Dismiss',
              barrierColor: Colors.black.withValues(alpha: 0.4),
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, anim1, anim2) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: Material(
                    color: Colors.transparent,
                    child: hano_bildirimler.BildirimlerView(),
                  ),
                );
              },
              transitionBuilder: (context, anim1, anim2, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: const Offset(0, 0),
                  ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
                  child: child,
                );
              },
            );
          },
        ),
        // Sadece okunmamış bildirim varken kırmızı nokta göster.
        if (context.watch<FinanceProvider>().hasUnreadNotifications)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}
