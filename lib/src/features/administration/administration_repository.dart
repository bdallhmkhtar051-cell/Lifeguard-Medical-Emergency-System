import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'administration_models.dart';

abstract interface class AdministrationRepository {
  Future<List<AdminUser>> users();
  Future<AdminUser> updateStatus(String userId, {required bool isActive});
  Future<List<AccountAdministrationAudit>> accountAudit();
  Future<List<SystemAccessAudit>> accessAudit();
}

class ApiAdministrationRepository implements AdministrationRepository {
  ApiAdministrationRepository(this._api);

  static const _basePath = '/api/v1/admin';
  final ApiClient _api;

  @override
  Future<List<AdminUser>> users() async {
    final data = (await _api.getJson('$_basePath/users')).data;
    return _parseList(data, AdminUser.fromJson);
  }

  @override
  Future<AdminUser> updateStatus(
    String userId, {
    required bool isActive,
  }) async {
    try {
      final response = await _api.putJson(
        '$_basePath/users/$userId/status',
        body: <String, dynamic>{'isActive': isActive},
      );
      return AdminUser.fromJson(response.requireObject());
    } on FormatException {
      throw const ApiException.protocol();
    }
  }

  @override
  Future<List<AccountAdministrationAudit>> accountAudit() async {
    final data = (await _api.getJson('$_basePath/account-audit')).data;
    return _parseList(data, AccountAdministrationAudit.fromJson);
  }

  @override
  Future<List<SystemAccessAudit>> accessAudit() async {
    final data = (await _api.getJson('$_basePath/access-audit')).data;
    return _parseList(data, SystemAccessAudit.fromJson);
  }

  static List<T> _parseList<T>(
    Object? data,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (data is! List) throw const ApiException.protocol();
    try {
      return data.cast<Map<String, dynamic>>().map(parse).toList();
    } on FormatException {
      throw const ApiException.protocol();
    }
  }
}
