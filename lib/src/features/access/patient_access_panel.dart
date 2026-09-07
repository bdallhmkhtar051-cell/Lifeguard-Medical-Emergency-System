import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'access_models.dart';
import 'access_repository.dart';

class PatientAccessPanel extends StatefulWidget {
  const PatientAccessPanel({required this.repository, super.key});
  final AccessRepository repository;

  @override
  State<PatientAccessPanel> createState() => _PatientAccessPanelState();
}

class _PatientAccessPanelState extends State<PatientAccessPanel> {
  PatientAccessDashboard? _data;
  String? _doctorEmail;
  int _minutes = 60;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.repository.patientDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _doctorEmail ??= data.doctors.firstOrNull?.email;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _grant() async {
    final email = _doctorEmail;
    if (email == null) return;
    setState(() => _busy = true);
    try {
      await widget.repository.grant(doctorEmail: email, minutes: _minutes);
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _message(error);
        });
      }
    }
  }

  Future<void> _revoke(String id) async {
    setState(() => _busy = true);
    try {
      await widget.repository.revoke(id);
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _message(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Card(
      key: const ValueKey('patient-access-panel'),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Doctor emergency access',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Grant temporary, read-only access. You can revoke it immediately.',
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            if (_busy && data == null)
              const Center(child: CircularProgressIndicator())
            else if (data != null) ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: DropdownButtonFormField<String>(
                      initialValue: _doctorEmail,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Authorized doctor',
                      ),
                      items: data.doctors
                          .map(
                            (doctor) => DropdownMenuItem(
                              value: doctor.email,
                              child: Text(
                                '${doctor.name} • ${doctor.email}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _doctorEmail = value),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<int>(
                      initialValue: _minutes,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Duration'),
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 minutes')),
                        DropdownMenuItem(value: 60, child: Text('1 hour')),
                        DropdownMenuItem(value: 240, child: Text('4 hours')),
                        DropdownMenuItem(value: 1440, child: Text('24 hours')),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _minutes = value ?? 60),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _busy || _doctorEmail == null ? null : _grant,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Grant access'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Access grants',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (data.grants.isEmpty)
                const Text('No access has been granted.')
              else
                for (final grant in data.grants)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      grant.active ? Icons.lock_open : Icons.lock_outline,
                    ),
                    title: Text(grant.doctorName),
                    subtitle: Text(
                      '${switch (grant.accessType) {
                        EmergencyAccessKind.breakGlass => 'Emergency override',
                        EmergencyAccessKind.qrConsented => 'Medical ID QR consent',
                        EmergencyAccessKind.consented => 'Patient consent',
                      }} • '
                      '${grant.active ? 'Active until' : 'Inactive'} ${_time(grant.expiresAt)}'
                      '${grant.emergencyReason == null ? '' : '\nReason: ${grant.emergencyReason}'}',
                    ),
                    trailing: grant.active
                        ? OutlinedButton(
                            onPressed: _busy ? null : () => _revoke(grant.id),
                            child: const Text('Revoke'),
                          )
                        : null,
                  ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Access history'),
                children: data.audit.isEmpty
                    ? const [ListTile(title: Text('No access activity yet.'))]
                    : data.audit
                          .map(
                            (item) => ListTile(
                              leading: Icon(_auditIcon(item.action)),
                              title: Text('${item.action} by ${item.actor}'),
                              subtitle: Text(_time(item.time)),
                            ),
                          )
                          .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _message(Object error) => error is ApiException
    ? error.message
    : 'Access information could not be updated.';
String _time(DateTime value) => value.toLocal().toString().substring(0, 16);
IconData _auditIcon(String action) => switch (action) {
  'Granted' => Icons.check_circle_outline,
  'Viewed' => Icons.visibility_outlined,
  'Revoked' => Icons.block_outlined,
  'BreakGlassActivated' => Icons.emergency_outlined,
  _ => Icons.history,
};
