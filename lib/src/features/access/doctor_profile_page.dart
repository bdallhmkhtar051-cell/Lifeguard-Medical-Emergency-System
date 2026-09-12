import 'package:flutter/material.dart';
import 'access_models.dart';
import 'access_repository.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({required this.repository, super.key});
  final AccessRepository repository;
  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final hospital = TextEditingController();
  final department = TextEditingController();
  final license = TextEditingController();
  final phone = TextEditingController();
  DoctorProfessionalProfile? profile;
  String? error;
  bool busy = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    title.dispose();
    hospital.dispose();
    department.dispose();
    license.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final value = await widget.repository.doctorProfile();
      if (!mounted) return;
      title.text = value.professionalTitle;
      hospital.text = value.hospitalName;
      department.text = value.department;
      license.text = value.licenseNumber;
      phone.text = value.phoneNumber;
      setState(() {
        profile = value;
        busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Professional profile could not be loaded.';
          busy = false;
        });
      }
    }
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final current = profile!;
      final saved = await widget.repository.updateDoctorProfile(
        DoctorProfessionalProfile(
          displayName: current.displayName,
          email: current.email,
          professionalTitle: title.text.trim(),
          hospitalName: hospital.text.trim(),
          department: department.text.trim(),
          licenseNumber: license.text.trim(),
          phoneNumber: phone.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() {
        profile = saved;
        busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Professional profile saved.')),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Professional profile could not be saved.';
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: busy && profile == null
                  ? const Center(child: CircularProgressIndicator())
                  : profile == null
                  ? Text(error ?? 'Profile unavailable')
                  : Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Professional profile',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('${profile!.displayName} • ${profile!.email}'),
                          const SizedBox(height: 14),
                          const Text(
                            'Self-reported professional information. A licence number shown here is not independently verified by LifeGuard.',
                            style: TextStyle(color: Color(0xFF92400E)),
                          ),
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),
                          field(title, 'Professional title', 100),
                          field(hospital, 'Hospital or organization', 150),
                          field(department, 'Department', 100),
                          field(license, 'Licence number (not verified)', 80),
                          field(phone, 'Professional phone', 24),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            key: const ValueKey('save-doctor-profile'),
                            onPressed: busy ? null : save,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save professional profile'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget field(TextEditingController controller, String label, int maximum) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          maxLength: maximum,
          decoration: InputDecoration(labelText: label),
          validator: (value) => (value?.trim().length ?? 0) > maximum
              ? 'Maximum $maximum characters.'
              : null,
        ),
      );
}
