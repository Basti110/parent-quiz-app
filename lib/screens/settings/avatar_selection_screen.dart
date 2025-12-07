import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settings_providers.dart';
import '../main_navigation.dart';

class AvatarSelectionScreen extends ConsumerStatefulWidget {
  final bool isRegistrationFlow;
  final String? userId;

  const AvatarSelectionScreen({
    super.key,
    this.isRegistrationFlow = false,
    this.userId,
  });

  @override
  ConsumerState<AvatarSelectionScreen> createState() =>
      _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends ConsumerState<AvatarSelectionScreen> {
  String? _selectedAvatar;
  bool _isSaving = false;

  final List<String> _avatars = [
    'assets/app_images/avatars/avatar_1.png',
    'assets/app_images/avatars/avatar_2.png',
    'assets/app_images/avatars/avatar_3.png',
    'assets/app_images/avatars/avatar_4.png',
    'assets/app_images/avatars/avatar_5.png',
    'assets/app_images/avatars/avatar_6.png',
  ];

  @override
  void initState() {
    super.initState();
    // Only load current avatar in settings mode
    if (!widget.isRegistrationFlow) {
      _loadCurrentAvatar();
    }
  }

  Future<void> _loadCurrentAvatar() async {
    final settingsService = ref.read(settingsServiceProvider);
    final currentAvatar = await settingsService.getAvatarPath();
    if (mounted) {
      setState(() {
        _selectedAvatar = currentAvatar;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !widget.isRegistrationFlow,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.selectAvatar),
          automaticallyImplyLeading: !widget.isRegistrationFlow,
          actions: [
            if (_selectedAvatar != null)
              TextButton(
                onPressed: _isSaving ? null : _saveAvatar,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isRegistrationFlow ? 'Continue' : l10n.save),
              ),
          ],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _avatars.length,
          itemBuilder: (context, index) {
            final avatar = _avatars[index];
            final isSelected = _selectedAvatar == avatar;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedAvatar = avatar);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    width: 4,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipOval(
                    child: Image.asset(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 48),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveAvatar() async {
    if (_selectedAvatar == null) {
      // Show validation error if no avatar selected
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an avatar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isRegistrationFlow) {
        // Registration mode: Use UserService to update Firestore
        if (widget.userId == null) {
          throw Exception('User ID is required for registration flow');
        }

        final userService = ref.read(userServiceProvider);
        await userService.updateAvatarPath(widget.userId!, _selectedAvatar!);

        if (mounted) {
          // Navigate to home screen (MainNavigationScreen)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
            (route) => false,
          );
        }
      } else {
        // Settings mode: Update both Firebase and local storage
        final currentUserId = ref.read(currentUserIdProvider);
        if (currentUserId == null) {
          throw Exception('User must be logged in to update avatar');
        }

        // Update Firebase
        final userService = ref.read(userServiceProvider);
        await userService.updateAvatarPath(currentUserId, _selectedAvatar!);

        // Update local storage
        final settingsService = ref.read(settingsServiceProvider);
        await settingsService.setAvatarPath(_selectedAvatar!);

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.save}d'), // "Saved"
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
