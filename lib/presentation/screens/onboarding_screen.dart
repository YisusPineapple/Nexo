import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../domain/entities/app_preferences.dart';
import '../providers/app_preferences_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() => _hasPermissions = true);
      return;
    }
    
    final audioStatus = await Permission.audio.status;
    final storageStatus = await Permission.storage.status;
    
    if (audioStatus.isGranted || storageStatus.isGranted) {
      setState(() => _hasPermissions = true);
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // FIX: Request notification permission for Android 13+ foreground service
      await Permission.notification.request();

      // Android 13+ uses Permission.audio, older versions use Permission.storage
      final audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) {
        setState(() => _hasPermissions = true);
        _nextPage();
        return;
      }
      
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        setState(() => _hasPermissions = true);
        _nextPage();
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required to find your music.')),
        );
      }
    } else {
      // Desktop platforms don't need this specific runtime permission flow
      setState(() => _hasPermissions = true);
      _nextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _WelcomePage(onNext: _nextPage),
            _PermissionsPage(
              hasPermissions: _hasPermissions,
              onRequest: _requestPermissions,
              onNext: _nextPage,
            ),
            _PerformancePage(onNext: _nextPage),
            _ThemePage(
              onFinish: () {
                ref.read(appPreferencesProvider.notifier).completeOnboarding();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(PhosphorIconsFill.speakerHifi, size: 100, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            'Welcome to Nexo',
            style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your local music oasis.\nOffline, fast, and tailored for your hardware.',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({
    required this.hasPermissions,
    required this.onRequest,
    required this.onNext,
  });

  final bool hasPermissions;
  final VoidCallback onRequest;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(PhosphorIconsRegular.folderLock, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            'Library Access',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Nexo needs access to your storage to find and play your local music files. We never collect telemetry or modify your files.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: hasPermissions ? onNext : onRequest,
              child: Text(hasPermissions ? 'Continue' : 'Grant Permission'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformancePage extends ConsumerWidget {
  const _PerformancePage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Performance Profile',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tailor Nexo to your device\'s capabilities.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _ProfileCard(
                  title: 'Vivo',
                  subtitle: 'Full animations, blur effects, high-res covers.',
                  icon: PhosphorIconsFill.sparkle,
                  isSelected: prefs.performanceProfile == PerformanceProfile.vivo,
                  onTap: () => ref.read(appPreferencesProvider.notifier).updateProfile(PerformanceProfile.vivo),
                ),
                const SizedBox(height: 12),
                _ProfileCard(
                  title: 'Balanced',
                  subtitle: 'Standard animations, medium covers. Recommended.',
                  icon: PhosphorIconsFill.scales,
                  isSelected: prefs.performanceProfile == PerformanceProfile.balanced,
                  onTap: () => ref.read(appPreferencesProvider.notifier).updateProfile(PerformanceProfile.balanced),
                ),
                const SizedBox(height: 12),
                _ProfileCard(
                  title: 'Eco',
                  subtitle: 'No animations, low-res covers. Best for older hardware.',
                  icon: PhosphorIconsFill.leaf,
                  isSelected: prefs.performanceProfile == PerformanceProfile.eco,
                  onTap: () => ref.read(appPreferencesProvider.notifier).updateProfile(PerformanceProfile.eco),
                ),
                const SizedBox(height: 12),
                _ProfileCard(
                  title: 'Custom',
                  subtitle: 'Tweak individual settings later.',
                  icon: PhosphorIconsFill.slidersHorizontal,
                  isSelected: prefs.performanceProfile == PerformanceProfile.custom,
                  onTap: () => ref.read(appPreferencesProvider.notifier).updateProfile(PerformanceProfile.custom),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePage extends ConsumerWidget {
  const _ThemePage({required this.onFinish});
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Choose Theme',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'How do you want Nexo to look?',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          
          RadioGroup<AppThemeMode>(
            groupValue: prefs.themeMode, 
            onChanged: (val) {
              if (val != null) {
                ref.read(appPreferencesProvider.notifier).updateTheme(val);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<AppThemeMode>(
                  title: Text('System Default'),
                  secondary: Icon(PhosphorIconsRegular.deviceMobile),
                  value: AppThemeMode.system,
                ),
                RadioListTile<AppThemeMode>(
                  title: Text('Light (Cream)'),
                  secondary: Icon(PhosphorIconsRegular.sun),
                  value: AppThemeMode.light,
                ),
                RadioListTile<AppThemeMode>(
                  title: Text('Dark (Terracotta)'),
                  secondary: Icon(PhosphorIconsRegular.moon),
                  value: AppThemeMode.dark,
                ),
              ],
            ),
          ),
          
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onFinish,
              child: const Text('Finish Setup'),
            ),
          ),
        ],
      ),
    );
  }
}