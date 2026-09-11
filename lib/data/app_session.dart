import 'package:flutter/foundation.dart';

/// The signed-in user's role. Elevated roles (manager, department head,
/// executive) can review approvals and file the extra "Other Requests".
enum UserRole { employee, manager, head, executive }

/// Lightweight session state. In production the role comes from the backend on
/// sign-in; here it defaults to an elevated role so the manager-only sections
/// are visible in the demo. Set [role] to [UserRole.employee] to see the
/// regular employee view.
class AppSession extends ChangeNotifier {
  AppSession._();
  static final AppSession instance = AppSession._();

  UserRole _role = UserRole.manager;

  UserRole get role => _role;

  /// True for manager / head / executive — the roles that can approve records
  /// and requests and see the extra request types.
  bool get canApprove => _role != UserRole.employee;

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }
}
