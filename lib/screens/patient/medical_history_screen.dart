import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/animations/animated_list_item.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock medical history data
  final List<Map<String, dynamic>> _conditions = [
    {
      'name': 'Hypertension',
      'status': 'Ongoing',
      'diagnosedDate': 'Jan 2020',
      'doctor': 'Dr. Ahmed Hassan',
      'icon': Icons.favorite,
      'color': Colors.red,
    },
    {
      'name': 'Type 2 Diabetes',
      'status': 'Controlled',
      'diagnosedDate': 'Mar 2019',
      'doctor': 'Dr. Sara Mohamed',
      'icon': Icons.bloodtype,
      'color': Colors.orange,
    },
    {
      'name': 'Seasonal Allergies',
      'status': 'Seasonal',
      'diagnosedDate': 'Jun 2015',
      'doctor': 'Dr. Omar Ali',
      'icon': Icons.grass,
      'color': Colors.green,
    },
  ];

  final List<Map<String, dynamic>> _medications = [
    {
      'name': 'Lisinopril',
      'dosage': '10mg',
      'frequency': 'Once daily',
      'startDate': 'Jan 2020',
      'status': 'Active',
    },
    {
      'name': 'Metformin',
      'dosage': '500mg',
      'frequency': 'Twice daily',
      'startDate': 'Mar 2019',
      'status': 'Active',
    },
    {
      'name': 'Cetirizine',
      'dosage': '10mg',
      'frequency': 'As needed',
      'startDate': 'Jun 2015',
      'status': 'As needed',
    },
  ];

  final List<Map<String, dynamic>> _allergies = [
    {
      'allergen': 'Penicillin',
      'reaction': 'Skin rash, difficulty breathing',
      'severity': 'Severe',
    },
    {'allergen': 'Peanuts', 'reaction': 'Mild hives', 'severity': 'Mild'},
  ];

  final List<Map<String, dynamic>> _procedures = [
    {
      'name': 'Appendectomy',
      'date': 'Aug 2018',
      'hospital': 'City Medical Center',
      'doctor': 'Dr. Fatima Youssef',
    },
    {
      'name': 'Dental Implant',
      'date': 'Feb 2021',
      'hospital': 'Smile Dental Clinic',
      'doctor': 'Dr. Khaled Ibrahim',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.get('medicalHistory'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: FadeSlideTransition(
            delay: const Duration(milliseconds: 200),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.primaryBlue,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: [
                Tab(text: AppLocalizations.of(context)!.get('conditions')),
                Tab(text: AppLocalizations.of(context)!.get('medications')),
                Tab(text: AppLocalizations.of(context)!.get('allergies')),
                Tab(text: AppLocalizations.of(context)!.get('procedures')),
              ],
            ),
          ),
        ),
      ),
      body: DecoratedBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildConditionsTab(),
            _buildMedicationsTab(),
            _buildAllergiesTab(),
            _buildProceduresTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: _conditions.length,
      itemBuilder: (context, index) {
        final condition = _conditions[index];
        return AnimatedListItem(
          index: index,
          child: _buildConditionCard(condition),
        );
      },
    );
  }

  Widget _buildConditionCard(Map<String, dynamic> condition) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
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
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (condition['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                condition['icon'] as IconData,
                color: condition['color'] as Color,
                size: 28,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    condition['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diagnosed: ${condition['diagnosedDate']}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    condition['doctor'],
                    style: TextStyle(
                      color: AppColors.primaryBlue.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusChip(condition['status']),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final medication = _medications[index];
        return AnimatedListItem(
          index: index,
          child: _buildMedicationCard(medication),
        );
      },
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final isActive = medication['status'] == 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isActive
                  ? AppColors.accentTeal.withValues(alpha: 0.3)
                  : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.medication,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        Text(
                          medication['dosage'],
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildStatusChip(medication['status']),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoPill(Icons.schedule, medication['frequency']),
                const SizedBox(width: 12),
                _buildInfoPill(
                  Icons.calendar_today,
                  'Since ${medication['startDate']}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergiesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: _allergies.length,
      itemBuilder: (context, index) {
        final allergy = _allergies[index];
        return AnimatedListItem(
          index: index,
          child: _buildAllergyCard(allergy),
        );
      },
    );
  }

  Widget _buildAllergyCard(Map<String, dynamic> allergy) {
    final isSevere = allergy['severity'] == 'Severe';
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: isSevere ? Colors.red : Colors.orange,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isSevere ? Colors.red : Colors.orange).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: isSevere ? Colors.red : Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        allergy['allergen'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSevere
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          allergy['severity'],
                          style: TextStyle(
                            color: isSevere ? Colors.red : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    allergy['reaction'],
                    style: const TextStyle(color: AppColors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProceduresTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: _procedures.length,
      itemBuilder: (context, index) {
        final procedure = _procedures[index];
        return AnimatedListItem(
          index: index,
          child: _buildProcedureCard(procedure),
        );
      },
    );
  }

  Widget _buildProcedureCard(Map<String, dynamic> procedure) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
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
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        procedure['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      Text(
                        procedure['date'],
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.local_hospital,
                  size: 16,
                  color: AppColors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    procedure['hospital'],
                    style: const TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.grey),
                const SizedBox(width: 6),
                Text(
                  procedure['doctor'],
                  style: TextStyle(
                    color: AppColors.primaryBlue.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'active':
      case 'ongoing':
        chipColor = AppColors.accentTeal;
        break;
      case 'controlled':
        chipColor = Colors.green;
        break;
      case 'severe':
        chipColor = Colors.red;
        break;
      default:
        chipColor = AppColors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: AppColors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
