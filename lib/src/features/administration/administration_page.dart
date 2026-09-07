import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_error_panel.dart';
import '../auth/auth_models.dart';
import 'administration_models.dart';
import 'administration_repository.dart';

class AdministrationPage extends StatefulWidget {
  const AdministrationPage({
    required this.repository,
    required this.currentUser,
    super.key,
  });

  final AdministrationRepository repository;
  final AppUser currentUser;

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  List<AdminUser> _users = const [];
  List<AccountAdministrationAudit> _audit = const [];
  List<SystemAccessAudit> _accessAudit = const [];
  final Set<String> _changingUsers = <String>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.repository.users(),
        widget.repository.accountAudit(),
        widget.repository.accessAudit(),
      ]);
      if (!mounted) return;
      setState(() {
        _users = results[0] as List<AdminUser>;
        _audit = results[1] as List<AccountAdministrationAudit>;
        _accessAudit = results[2] as List<SystemAccessAudit>;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : 'The administration dashboard could not be loaded.';
        _loading = false;
      });
    }
  }

  Future<void> _changeStatus(AdminUser user) async {
    final activate = !user.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${activate ? 'Activate' : 'Deactivate'} account?'),
        content: Text(
          activate
              ? '${user.displayName} will be allowed to sign in again.'
              : '${user.displayName} will be signed out and prevented from signing in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-status-change'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(activate ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _changingUsers.add(user.id));
    try {
      final updated = await widget.repository.updateStatus(
        user.id,
        isActive: activate,
      );
      final audit = await widget.repository.accountAudit();
      if (!mounted) return;
      setState(() {
        _users = [
          for (final item in _users)
            if (item.id == user.id) updated else item,
        ];
        _audit = audit;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${updated.displayName} is now ${updated.isActive ? 'active' : 'inactive'}.',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'The account could not be updated.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _changingUsers.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const ValueKey('administration-page'),
          padding: const EdgeInsets.all(24),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Align(alignment: Alignment.topCenter, child: _content()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 120),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error case final message?) {
      return AsyncErrorPanel(
        title: 'Administration unavailable',
        message: message,
        onRetry: _load,
      );
    }

    final active = _users.where((user) => user.isActive).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'System administration',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage account availability and review administrator actions.',
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              label: 'TOTAL ACCOUNTS',
              value: '${_users.length}',
              icon: Icons.people_outline,
            ),
            _SummaryCard(
              label: 'ACTIVE',
              value: '$active',
              icon: Icons.verified_user_outlined,
              color: AppTheme.teal,
            ),
            _SummaryCard(
              label: 'INACTIVE',
              value: '${_users.length - active}',
              icon: Icons.person_off_outlined,
              color: Colors.red.shade700,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionCard(
          title: 'User accounts',
          icon: Icons.manage_accounts_outlined,
          child: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 760
                ? _UserTable(
                    users: _users,
                    currentUserId: widget.currentUser.id,
                    changingUsers: _changingUsers,
                    onChangeStatus: _changeStatus,
                  )
                : Column(
                    children: [
                      for (final user in _users)
                        _UserCard(
                          user: user,
                          isCurrentUser: user.id == widget.currentUser.id,
                          busy: _changingUsers.contains(user.id),
                          onChangeStatus: () => _changeStatus(user),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        _SectionCard(
          title: 'Emergency access activity',
          icon: Icons.shield_outlined,
          child: _accessAudit.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No emergency access events have been recorded.'),
                )
              : Column(
                  children: _accessAudit.map(_AccessAuditTile.new).toList(),
                ),
        ),
        const SizedBox(height: 24),
        _SectionCard(
          title: 'Account activity',
          icon: Icons.policy_outlined,
          child: _audit.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No account status changes have been recorded.'),
                )
              : Column(children: _audit.map(_AuditTile.new).toList()),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppTheme.blue,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.blue),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _UserTable extends StatelessWidget {
  const _UserTable({
    required this.users,
    required this.currentUserId,
    required this.changingUsers,
    required this.onChangeStatus,
  });
  final List<AdminUser> users;
  final String currentUserId;
  final Set<String> changingUsers;
  final ValueChanged<AdminUser> onChangeStatus;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('USER')),
        DataColumn(label: Text('ROLE')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('ACTION')),
      ],
      rows: users
          .map(
            (user) => DataRow(
              cells: [
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                DataCell(Text(user.roleLabel)),
                DataCell(_StatusChip(active: user.isActive)),
                DataCell(
                  _StatusButton(
                    user: user,
                    disabled:
                        user.id == currentUserId ||
                        changingUsers.contains(user.id),
                    onPressed: () => onChangeStatus(user),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    ),
  );
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isCurrentUser,
    required this.busy,
    required this.onChangeStatus,
  });
  final AdminUser user;
  final bool isCurrentUser;
  final bool busy;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: AppTheme.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        Text(user.email, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Text(user.roleLabel)),
            _StatusChip(active: user.isActive),
            const SizedBox(width: 8),
            _StatusButton(
              user: user,
              disabled: isCurrentUser || busy,
              onPressed: onChangeStatus,
            ),
          ],
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(active ? 'Active' : 'Inactive'),
    avatar: Icon(active ? Icons.check_circle : Icons.block, size: 16),
    visualDensity: VisualDensity.compact,
  );
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.user,
    required this.disabled,
    required this.onPressed,
  });
  final AdminUser user;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    key: ValueKey('toggle-user-${user.id}'),
    onPressed: disabled ? null : onPressed,
    child: Text(user.isActive ? 'Deactivate' : 'Activate'),
  );
}

class _AuditTile extends StatelessWidget {
  const _AuditTile(this.audit);
  final AccountAdministrationAudit audit;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      child: Icon(
        audit.action == 'Activated'
            ? Icons.person_add_alt_1
            : Icons.person_off_outlined,
      ),
    ),
    title: Text('${audit.targetUserName} was ${audit.action.toLowerCase()}'),
    subtitle: Text(
      'By ${audit.administratorName} • ${audit.occurredAtUtc.toLocal()}',
    ),
  );
}

class _AccessAuditTile extends StatelessWidget {
  const _AccessAuditTile(this.audit);
  final SystemAccessAudit audit;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const CircleAvatar(child: Icon(Icons.security_outlined)),
    title: Text('${audit.actorName}: ${_words(audit.action)}'),
    subtitle: Text(
      'Patient: ${audit.patientName} • ${_words(audit.accessType)} • ${audit.occurredAtUtc.toLocal()}',
    ),
  );

  static String _words(String value) => value
      .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
      .toLowerCase();
}
