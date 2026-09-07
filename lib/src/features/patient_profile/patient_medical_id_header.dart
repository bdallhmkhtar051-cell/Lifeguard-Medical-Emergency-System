import 'package:flutter/material.dart';

import 'emergency_profile.dart';

const _navy = Color(0xFF0F172A);
const _slate = Color(0xFF1E293B);
const _border = Color(0xFF334155);
const _muted = Color(0xFFCBD5E1);
const _blue = Color(0xFF2563EB);
const _red = Color(0xFFDC2626);

/// React-inspired presentation for the real versioned ASP.NET/SQL profile.
class PatientMedicalIdHeader extends StatelessWidget {
  const PatientMedicalIdHeader({
    required this.profile,
    required this.onEdit,
    required this.onRefresh,
    super.key,
  });

  final EmergencyProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('medical-id-header'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400F172A),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF020617), _navy, Color(0xFF1E2E4A)],
            ),
            border: Border.all(color: _slate),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _TexturePainter()),
                ),
              ),
              const Positioned(right: -88, top: -105, child: _BlueGlow()),
              const Positioned(
                right: 8,
                top: -8,
                child: IgnorePointer(
                  child: Icon(
                    Icons.health_and_safety_outlined,
                    size: 152,
                    color: Color(0x20BAE6FD),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopRow(
                      profile: profile,
                      onEdit: onEdit,
                      onRefresh: onRefresh,
                    ),
                    const SizedBox(height: 20),
                    _Summary(profile: profile),
                    const SizedBox(height: 16),
                    _Actions(profile: profile, onRefresh: onRefresh),
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

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.profile,
    required this.onEdit,
    required this.onRefresh,
  });

  final EmergencyProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(name: profile.fullName),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _tag('PATIENT'),
                      _smallText('ID: ${_shortId(profile.id)}', mono: true),
                      _smallText(
                        'DOB: ${profile.dateOfBirth == null ? 'Not recorded' : _date(profile.dateOfBirth!)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roundButton(
              tooltip: 'View ICE network',
              icon: Icons.group_outlined,
              onTap: () => _showContacts(context, profile),
            ),
            _roundButton(
              tooltip: 'Refresh profile',
              icon: Icons.refresh,
              onTap: onRefresh,
            ),
            _roundButton(
              key: const ValueKey('edit-profile-button'),
              tooltip: 'Edit profile',
              icon: Icons.edit_outlined,
              onTap: onEdit,
            ),
            const SizedBox(width: 4),
            _BloodBadge(value: bloodGroupLabel(profile.bloodGroup)),
          ],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.profile});

  final EmergencyProfile profile;

  @override
  Widget build(BuildContext context) {
    final values = <Widget>[
      _smallText('Emergency profile'),
      _count('Allergies', profile.allergies.length, const Color(0xFFF87171)),
      _count(
        'Medications',
        profile.medications.length,
        const Color(0xFF60A5FA),
      ),
      _count(
        'ICE contacts',
        profile.emergencyContacts.length,
        const Color(0xFF34D399),
      ),
    ];
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: [
          for (var index = 0; index < values.length; index++) ...[
            if (index > 0) _smallText('•'),
            values[index],
          ],
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.profile, required this.onRefresh});

  final EmergencyProfile profile;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 900 ? 4 : (box.maxWidth >= 520 ? 2 : 1);
        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 5 : 3.15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ActionTile(
              eyebrow: 'Hospital access',
              label: 'Restricted',
              icon: Icons.key_outlined,
              onTap: () => _notice(
                context,
                'Access permissions are the next secure workflow.',
              ),
            ),
            _ActionTile(
              eyebrow: 'Last updated',
              label: profile.updatedAtUtc == null
                  ? 'Not recorded'
                  : _shortDate(profile.updatedAtUtc!),
              icon: Icons.calendar_month_outlined,
              onTap: onRefresh,
            ),
            _ActionTile(
              eyebrow: 'Medical ID',
              label: 'Display QR',
              icon: Icons.qr_code_2,
              color: _blue,
              borderColor: const Color(0x665B9CF6),
              onTap: () => _notice(
                context,
                'Secure Medical ID QR is scheduled after access control.',
              ),
            ),
            _ActionTile(
              eyebrow: 'Emergency',
              label: 'View ICE',
              icon: Icons.phone_in_talk_outlined,
              color: _red,
              borderColor: const Color(0x66F87171),
              onTap: () => _showContacts(context, profile),
            ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.eyebrow,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xA61E293B),
    this.borderColor = _border,
  });

  final String eyebrow;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: Colors.white70, size: 21),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Badge(
      alignment: const Alignment(1.2, 1.1),
      backgroundColor: const Color(0xFF059669),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      label: const Text(
        'SIGNED IN',
        style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900),
      ),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), _blue]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Text(
          _initials(name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _BloodBadge extends StatelessWidget {
  const _BloodBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        value.isEmpty ? '—' : value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _BlueGlow extends StatelessWidget {
  const _BlueGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 320,
        height: 320,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0x382BA8FF), Color(0x002BA8FF)],
          ),
        ),
      ),
    );
  }
}

class _TexturePainter extends CustomPainter {
  const _TexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final lines = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1;
    final dots = Paint()..color = const Color(0x102BA8FF);
    for (double x = -size.height; x < size.width; x += 42) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        lines,
      );
    }
    for (double y = 18; y < size.height; y += 36) {
      for (double x = 18; x < size.width; x += 36) {
        canvas.drawCircle(Offset(x, y), 1.1, dots);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TexturePainter oldDelegate) => false;
}

Widget _roundButton({
  Key? key,
  required String tooltip,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: IconButton(
      key: key,
      tooltip: tooltip,
      color: _muted,
      style: IconButton.styleFrom(backgroundColor: Colors.white10),
      onPressed: onTap,
      icon: Icon(icon, size: 20),
    ),
  );
}

Widget _tag(String text) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
  decoration: BoxDecoration(
    color: const Color(0x332563EB),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0x665B9CF6)),
  ),
  child: Text(
    text,
    style: const TextStyle(
      color: Color(0xFFBFDBFE),
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    ),
  ),
);

Widget _smallText(String text, {bool mono = false}) => Text(
  text,
  style: TextStyle(
    color: const Color(0xFF94A3B8),
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontFamily: mono ? 'monospace' : null,
  ),
);

Widget _count(String label, int value, Color color) => Text.rich(
  TextSpan(
    text: '$label: ',
    children: [
      TextSpan(
        text: '$value',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    ],
  ),
  style: const TextStyle(color: _muted, fontSize: 12),
);

String _shortId(String value) {
  final compact = value.replaceAll('-', '').toUpperCase();
  return compact.length <= 10 ? compact : compact.substring(0, 10);
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).take(2);
  return words.where((word) => word.isNotEmpty).map((word) => word[0]).join();
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _shortDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

void _notice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _showContacts(BuildContext context, EmergencyProfile profile) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Emergency contacts'),
      children: [
        if (profile.emergencyContacts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No emergency contacts have been recorded.'),
          ),
        for (final contact in profile.emergencyContacts)
          ListTile(
            leading: CircleAvatar(child: Text(_initials(contact.name))),
            title: Text(contact.name),
            subtitle: Text('${contact.relationship} • ${contact.phoneNumber}'),
            trailing: contact.isPrimary
                ? const Icon(Icons.star, color: Color(0xFFF59E0B))
                : null,
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ),
        ),
      ],
    ),
  );
}
