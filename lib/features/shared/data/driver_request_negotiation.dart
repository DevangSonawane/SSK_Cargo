/// Shared parsing for the `driver_requests` negotiation lock.
///
/// Every driver-request payload (REST + socket) carries `noNegotiation`, which
/// is true for both broker-assigned (`jobRequestId` set) and admin-assigned
/// (`isAdminAssigned: true`) rows. Callers must use that flag to decide whether
/// a Counter action is allowed — never re-derive it from `jobRequestId` alone,
/// which silently misses admin-assigned rows.
library;

const _noNegotiationKeys = ['noNegotiation', 'no_negotiation'];
const _isAdminAssignedKeys = ['isAdminAssigned', 'is_admin_assigned'];

bool hasNoNegotiationFlag(Map<String, dynamic> json) =>
    _noNegotiationKeys.any((key) => json[key] != null);

bool readIsAdminAssignedFlag(Map<String, dynamic> json) =>
    _readFlag(json, _isAdminAssignedKeys);

/// Reads the backend's `noNegotiation` flag. Only when a payload omits the
/// field entirely (older cached/socket payloads) do we fall back to the origin
/// markers, so a missing key can never unlock Counter on an assigned row.
bool readNoNegotiationFlag(
  Map<String, dynamic> json, {
  required String jobRequestId,
  required bool isAdminAssigned,
}) {
  if (hasNoNegotiationFlag(json)) {
    return _readFlag(json, _noNegotiationKeys);
  }
  return jobRequestId.trim().isNotEmpty || isAdminAssigned;
}

bool _readFlag(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'null') continue;
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}
