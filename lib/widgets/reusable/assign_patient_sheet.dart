import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../services/doctor_api_service.dart';
import '../../models/patient_search_model.dart';
import '../../models/patient_response_model.dart';
import '../../core/api/api_exceptions.dart';

/// Search mode: by patient name or by phone number.
enum _SearchMode { name, phone }

/// A bottom sheet that lets a doctor search for patients by name or phone
/// number and assign them. Shows user-friendly error messages for network
/// and server problems.
class AssignPatientSheet extends StatefulWidget {
  final int doctorId;

  /// Called after a successful assignment, passing the newly assigned patient
  /// so the caller can update its list immediately (optimistic update).
  final void Function(PatientResponseModel patient)? onAssigned;

  const AssignPatientSheet({
    super.key,
    required this.doctorId,
    this.onAssigned,
  });

  /// Show the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required int doctorId,
    void Function(PatientResponseModel patient)? onAssigned,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AssignPatientSheet(doctorId: doctorId, onAssigned: onAssigned),
    );
  }

  @override
  State<AssignPatientSheet> createState() => _AssignPatientSheetState();
}

class _AssignPatientSheetState extends State<AssignPatientSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  _SearchMode _searchMode = _SearchMode.name;
  List<PatientSearchModel> _results = [];
  bool _isSearching = false;
  bool _isAssigning = false;
  String? _errorMessage;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final List<PatientSearchModel> results;
      if (_searchMode == _SearchMode.name) {
        results = await DoctorApiService.searchByName(widget.doctorId, query);
      } else {
        results = await DoctorApiService.searchByPhone(widget.doctorId, query);
      }
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
          _hasSearched = true;
        });
      }
    } on NetworkException catch (e) {
      log('Network error during search: ${e.message}', name: 'AssignPatient');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
          _errorMessage = AppLocalizations.of(context)!.get('connectionError');
        });
      }
    } on ServerException catch (e) {
      log('Server error during search: ${e.message}', name: 'AssignPatient');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
          _errorMessage = AppLocalizations.of(context)!.get('serverError');
        });
      }
    } on ApiException catch (e) {
      log('API error during search: ${e.message}', name: 'AssignPatient');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
          _errorMessage = e.message;
        });
      }
    } on DioException catch (e) {
      log('Dio error during search: ${e.message}', name: 'AssignPatient');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
          _errorMessage = _connectionErrorMessage();
        });
      }
    } catch (e) {
      log('Unexpected error during search: $e', name: 'AssignPatient');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
          _errorMessage = AppLocalizations.of(context)!.get('unexpectedError');
        });
      }
    }
  }

  Future<void> _assignPatient(PatientSearchModel patient) async {
    setState(() {
      _isAssigning = true;
      _errorMessage = null;
    });

    try {
      await DoctorApiService.assignPatient(widget.doctorId, patient.id);
      if (mounted) {
        final assigned = PatientResponseModel(
          id: patient.id,
          fullName: patient.fullName,
          email: patient.email,
          priority: 'MEDIUM', // default priority on new assignment
        );
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.get('patientAssigned'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
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
        widget.onAssigned?.call(assigned);
      }
    } on NetworkException catch (e) {
      log('Network error during assign: ${e.message}', name: 'AssignPatient');
      if (mounted) {
        setState(() {
          _isAssigning = false;
          _errorMessage = AppLocalizations.of(context)!.get('connectionError');
        });
      }
    } on ServerException catch (e) {
      log('Server error during assign: ${e.message}', name: 'AssignPatient');
      if (mounted) {
        setState(() {
          _isAssigning = false;
          _errorMessage = AppLocalizations.of(context)!.get('serverError');
        });
      }
    } on ValidationException catch (e) {
      log(
        'Validation error during assign: ${e.message}',
        name: 'AssignPatient',
      );
      if (mounted) {
        setState(() {
          _isAssigning = false;
          _errorMessage = e.message;
        });
      }
    } on ApiException catch (e) {
      log('API error during assign: ${e.message}', name: 'AssignPatient');
      if (mounted) {
        setState(() {
          _isAssigning = false;
          _errorMessage = e.message;
        });
      }
    } on DioException catch (e) {
      log('Dio error during assign: ${e.message}', name: 'AssignPatient');
      if (mounted) {
        setState(() {
          _isAssigning = false;
          _errorMessage = _connectionErrorMessage();
        });
      }
    } catch (e) {
      log('Unexpected error during assign: $e', name: 'AssignPatient');
      if (mounted) {
        setState(() {
          _isAssigning = false;
          _errorMessage = AppLocalizations.of(context)!.get('unexpectedError');
        });
      }
    }
  }

  String _connectionErrorMessage() {
    return AppLocalizations.of(context)!.get('connectionError');
  }

  void _switchMode(_SearchMode mode) {
    if (_searchMode == mode) return;
    setState(() {
      _searchMode = mode;
      _results = [];
      _hasSearched = false;
      _errorMessage = null;
    });
    // Re-trigger search if there's already text
    final query = _searchController.text.trim();
    if (query.length >= 2) {
      _performSearch(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.get('assignPatient'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeButton(
                      icon: Icons.person_outlined,
                      label: loc.get('searchByNameLabel'),
                      isActive: _searchMode == _SearchMode.name,
                      onTap: () => _switchMode(_SearchMode.name),
                    ),
                  ),
                  Expanded(
                    child: _buildModeButton(
                      icon: Icons.phone_outlined,
                      label: loc.get('searchByPhoneLabel'),
                      isActive: _searchMode == _SearchMode.phone,
                      onTap: () => _switchMode(_SearchMode.phone),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onQueryChanged,
                autofocus: true,
                keyboardType:
                    _searchMode == _SearchMode.phone
                        ? TextInputType.phone
                        : TextInputType.text,
                decoration: InputDecoration(
                  hintText:
                      _searchMode == _SearchMode.name
                          ? loc.get('searchByNameHint')
                          : loc.get('searchByPhoneHint'),
                  hintStyle: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    _searchMode == _SearchMode.name
                        ? Icons.search
                        : Icons.phone,
                    color: AppColors.primaryBlue,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.grey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onQueryChanged('');
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Error banner
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_hasSearched)
                      TextButton(
                        onPressed: () {
                          final query = _searchController.text.trim();
                          if (query.length >= 2) {
                            _performSearch(query);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          loc.get('retry'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Results list
          Flexible(child: _buildResultsArea(loc)),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.primaryBlue : AppColors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primaryBlue : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsArea(AppLocalizations loc) {
    if (_isSearching) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.get('searching'),
              style: const TextStyle(color: AppColors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 56,
              color: AppColors.primaryBlue.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              loc.get('typeToSearch'),
              style: const TextStyle(color: AppColors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty && _errorMessage == null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              loc.get('noResults'),
              style: const TextStyle(color: AppColors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final patient = _results[index];
        return _buildPatientResultTile(patient, loc);
      },
    );
  }

  Widget _buildPatientResultTile(
    PatientSearchModel patient,
    AppLocalizations loc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isAssigning ? null : () => _assignPatient(patient),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.15),
                        AppColors.secondaryBlue.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      patient.fullName.isNotEmpty
                          ? patient.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        patient.email,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (patient.phoneNumber != null &&
                          patient.phoneNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 12,
                                color: AppColors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                patient.phoneNumber!,
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Assign button
                _isAssigning
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        loc.get('assign'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
