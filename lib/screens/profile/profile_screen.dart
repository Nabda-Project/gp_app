import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../utils/constants.dart';
import '../../models/user_model.dart';
import '../../utils/app_localizations.dart';
import '../../services/storage_service.dart';
import '../../services/user_api_service.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../widgets/reusable/logout_dialog.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/animations/animated_list_item.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadProfileImage();
  }

  void _loadUser() {
    setState(() {
      _currentUser = StorageService.getUser();
    });
  }

  /// Per-user Hive key for profile image path.
  String get _profileKey => 'profileImagePath_${_currentUser?.backendId ?? 'unknown'}';

  Future<void> _loadProfileImage() async {
    final box = await Hive.openBox('profileBox');
    // Use a user-scoped key so different users don't share the same cached image
    final localPath = box.get(_profileKey) as String?;
    if (localPath != null && File(localPath).existsSync()) {
      setState(() => _profileImagePath = localPath);
      return;
    }
    // Fallback: if the user model has a backend profileImageUrl (base64 data URI
    // or network URL), decode and cache it locally so the avatar shows correctly.
    final backendUrl = _currentUser?.profileImageUrl;
    if (backendUrl != null && backendUrl.isNotEmpty && backendUrl.startsWith('data:image')) {
      try {
        final base64Str = backendUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        final appDir = await getApplicationDocumentsDirectory();
        final file = File('${appDir.path}/profile_${_currentUser!.backendId}.jpg');
        await file.writeAsBytes(bytes);
        await box.put(_profileKey, file.path);
        if (mounted) setState(() => _profileImagePath = file.path);
      } catch (e) {
        log('Failed to decode backend profile image: $e', name: 'ProfileScreen');
      }
    }
  }

  Future<void> _saveProfileImage(String path) async {
    // Copy image to app's permanent directory
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await File(path).copy('${appDir.path}/$fileName');

    // Save locally with user-scoped key
    final box = await Hive.openBox('profileBox');
    await box.put(_profileKey, savedFile.path);
    setState(() => _profileImagePath = savedFile.path);

    // Upload to backend as base64 data URI
    try {
      final bytes = await savedFile.readAsBytes();
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';

      await UserApiService.updateProfile({'profileImageUrl': dataUri});

      // Update local user model with the new image URL
      if (_currentUser != null) {
        final updated = _currentUser!.copyWith(profileImageUrl: dataUri);
        StorageService.saveUser(updated);
        setState(() => _currentUser = updated);
      }
      log('Profile image uploaded to backend', name: 'ProfileScreen');
    } catch (e) {
      log('Failed to upload profile image to backend: $e', name: 'ProfileScreen');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (picked == null) return;

    // Launch cropper — WhatsApp/Facebook style circular crop
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'تعديل الصورة',
          toolbarColor: AppColors.primaryBlue,
          toolbarWidgetColor: Colors.white,
          statusBarColor: AppColors.darkBlue,
          activeControlsWidgetColor: AppColors.accentTeal,
          cropFrameColor: AppColors.accentTeal,
          cropGridColor: Colors.white54,
          backgroundColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'تعديل الصورة',
          doneButtonTitle: 'حفظ',
          cancelButtonTitle: 'إلغاء',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          cropStyle: CropStyle.circle,
        ),
      ],
    );

    if (cropped != null) {
      await _saveProfileImage(cropped.path);
    }
  }

  void _showImagePickerSheet() {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.get('changeProfilePicture'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    title: Text(loc.get('takePhoto')),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: AppColors.accentTeal,
                      ),
                    ),
                    title: Text(loc.get('chooseFromGallery')),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_profileImagePath != null)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: AppColors.error),
                      ),
                      title: Text(loc.get('removePhoto')),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final box = await Hive.openBox('profileBox');
                        await box.delete(_profileKey);
                        setState(() => _profileImagePath = null);
                        // Also remove from backend
                        try {
                          await UserApiService.updateProfile({'profileImageUrl': ''});
                          if (_currentUser != null) {
                            final updated = _currentUser!.copyWith(profileImageUrl: '');
                            StorageService.saveUser(updated);
                            setState(() => _currentUser = updated);
                          }
                        } catch (e) {
                          log('Failed to remove profile image from backend: $e', name: 'ProfileScreen');
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
    );
  }

  void _showEditProfileSheet() {
    if (_currentUser == null) return;
    final loc = AppLocalizations.of(context)!;

    final nameController = TextEditingController(text: _currentUser!.fullName);
    final phoneController = TextEditingController(
      text: _currentUser!.phoneNumber ?? '',
    );
    final heightController = TextEditingController(
      text: _currentUser!.height?.toStringAsFixed(1) ?? '',
    );
    final weightController = TextEditingController(
      text: _currentUser!.weight?.toStringAsFixed(1) ?? '',
    );

    final isPatient = _currentUser!.role != 'Doctor';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.get('editProfile'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Name field
                  _buildEditField(
                    label: loc.get('fullName'),
                    controller: nameController,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),

                  // Phone field
                  _buildEditField(
                    label: loc.get('phoneNumber'),
                    controller: phoneController,
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Height and Weight (patients only)
                  if (isPatient) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildEditField(
                            label: loc.get('heightCm'),
                            controller: heightController,
                            icon: Icons.height,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildEditField(
                            label: loc.get('weightKg'),
                            controller: weightController,
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),

                  // Save button
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        final newPhone = phoneController.text.trim();
                        final newHeight =
                            isPatient && heightController.text.trim().isNotEmpty
                                ? double.tryParse(heightController.text.trim())
                                : null;
                        final newWeight =
                            isPatient && weightController.text.trim().isNotEmpty
                                ? double.tryParse(weightController.text.trim())
                                : null;

                        final updatedUser = _currentUser!.copyWith(
                          fullName:
                              newName.isNotEmpty
                                  ? newName
                                  : _currentUser!.fullName,
                          phoneNumber:
                              newPhone.isNotEmpty
                                  ? newPhone
                                  : _currentUser!.phoneNumber,
                          height: newHeight ?? _currentUser!.height,
                          weight: newWeight ?? _currentUser!.weight,
                        );

                        // Save locally first
                        await StorageService.saveUser(updatedUser);
                        setState(() => _currentUser = updatedUser);

                        // Sync with backend
                        try {
                          final backendData = <String, dynamic>{};
                          if (newName.isNotEmpty)
                            backendData['fullName'] = newName;
                          if (newPhone.isNotEmpty)
                            backendData['phoneNumber'] = newPhone;
                          if (newHeight != null)
                            backendData['height'] = newHeight;
                          if (newWeight != null)
                            backendData['weight'] = newWeight;

                          if (backendData.isNotEmpty) {
                            await UserApiService.updateProfile(backendData);
                            log(
                              'Profile synced with backend',
                              name: 'ProfileScreen',
                            );
                          }
                        } catch (e) {
                          log(
                            'Backend profile sync failed: $e',
                            name: 'ProfileScreen',
                          );
                          // Local save succeeded — show warning but don't block
                        }

                        if (ctx.mounted) Navigator.pop(ctx);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(loc.get('profileUpdated')),
                                ],
                              ),
                              backgroundColor: AppColors.accentTeal,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        loc.get('saveChanges'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.grey),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _genderDisplay(String? gender) {
    if (gender == null) return '—';
    final loc = AppLocalizations.of(context)!;
    switch (gender.toUpperCase()) {
      case 'MALE':
        return loc.get('male');
      case 'FEMALE':
        return loc.get('female');
      default:
        return gender;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isPatient = _currentUser?.role != 'Doctor';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBackground(
        child: CustomScrollView(
          slivers: [
            // ── Gradient App Bar ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                    Positioned(
                      top: -60,
                      right: -30,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -40,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Stack(
                          children: [
                            // Logout button at top-right
                            Positioned(
                              top: 8,
                              right: 0,
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: () => LogoutDialog.show(context),
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Icon(
                                      Icons.logout_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Centered profile content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 16),
                                  // Profile Picture
                                  GestureDetector(
                                    onTap: _showImagePickerSheet,
                                    child: Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                              width: 3,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 50,
                                            backgroundColor: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            backgroundImage:
                                                _profileImagePath != null
                                                    ? FileImage(
                                                      File(_profileImagePath!),
                                                    )
                                                    : null,
                                            child:
                                                _profileImagePath == null
                                                    ? const Icon(
                                                      Icons.person,
                                                      size: 50,
                                                      color: Colors.white,
                                                    )
                                                    : null,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentTeal,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _currentUser?.fullName ?? loc.get('guestUser'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentUser?.email ?? loc.get('noEmail'),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _currentUser?.role ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
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
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Edit Profile Button ──────────────────────────
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 100),
                      child: GestureDetector(
                        onTap: _showEditProfileSheet,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF407BFF), Color(0xFF00B4D8)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                loc.get('editProfile'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Personal Information Card ────────────────────
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 200),
                      child: _buildInfoSection(
                        title: loc.get('personalInfo'),
                        children: [
                          _buildInfoTile(
                            icon: Icons.person_outline,
                            label: loc.get('fullName'),
                            value: _currentUser?.fullName ?? '—',
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.email_outlined,
                            label: loc.get('emailAddress'),
                            value: _currentUser?.email ?? '—',
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.phone_outlined,
                            label: loc.get('phoneNumber'),
                            value: _currentUser?.phoneNumber ?? '—',
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.wc_rounded,
                            label: loc.get('gender'),
                            value: _genderDisplay(_currentUser?.gender),
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.cake_outlined,
                            label: loc.get('dateOfBirth'),
                            value: _formatDate(_currentUser?.dateOfBirth),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Health Info (Patients only) ──────────────────
                    if (isPatient)
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 300),
                        child: _buildInfoSection(
                          title: loc.get('healthInfo'),
                          children: [
                            _buildInfoTile(
                              icon: Icons.height,
                              label: loc.get('heightCm'),
                              value:
                                  _currentUser?.height != null
                                      ? '${_currentUser!.height!.toStringAsFixed(1)} cm'
                                      : '—',
                            ),
                            _buildDivider(),
                            _buildInfoTile(
                              icon: Icons.monitor_weight_outlined,
                              label: loc.get('weightKg'),
                              value:
                                  _currentUser?.weight != null
                                      ? '${_currentUser!.weight!.toStringAsFixed(1)} kg'
                                      : '—',
                            ),
                          ],
                        ),
                      ),
                    if (isPatient) const SizedBox(height: 16),

                    // ── Options ──────────────────────────────────────
                    AnimatedListItem(
                      index: 0,
                      child: _buildProfileOption(
                        icon: Icons.settings,
                        title: loc.get('settings'),
                        onTap: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ),
                    // Medical History - only visible for patients, not doctors
                    // if (_currentUser?.role != 'Doctor')
                    //   AnimatedListItem(
                    //     index: 1,
                    //     child: _buildProfileOption(
                    //       icon: Icons.history,
                    //       title: loc.get('medicalHistory'),
                    //       onTap: () {
                    //         Navigator.pushNamed(context, '/medical_history');
                    //       },
                    //     ),
                    //   ),
                    const SizedBox(height: AppDimensions.paddingL),
                    AnimatedListItem(
                      index: 2,
                      child: _buildProfileOption(
                        icon: Icons.logout,
                        title: loc.get('logout'),
                        onTap: () => LogoutDialog.show(context),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: AppColors.lightGrey.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
        onTap: onTap,
      ),
    );
  }
}
