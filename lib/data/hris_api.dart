import 'app_session.dart';
import 'api_client.dart';
import 'mock_data.dart';
import 'tenants.dart';

// ---------------------------------------------------------------------------
// Models that only the API needs (the four UI models live in mock_data.dart).
// ---------------------------------------------------------------------------

class PersonalBackground {
  PersonalBackground({
    this.dateOfBirth,
    this.civilStatus,
    this.contactNumber,
    this.address,
    this.dateHired,
    this.sss,
    this.philhealth,
    this.tin,
    this.pagibig,
    this.driversLicense,
  });

  final String? dateOfBirth;
  final String? civilStatus;
  final String? contactNumber;
  final String? address;
  final String? dateHired;
  final String? sss;
  final String? philhealth;
  final String? tin;
  final String? pagibig;
  final String? driversLicense;

  factory PersonalBackground.fromJson(Map<String, dynamic> j) =>
      PersonalBackground(
        dateOfBirth: j['date_of_birth'] as String?,
        civilStatus: j['civil_status'] as String?,
        contactNumber: j['contact_number'] as String?,
        address: j['address'] as String?,
        dateHired: j['date_hired'] as String?,
        sss: j['sss'] as String?,
        philhealth: j['philhealth'] as String?,
        tin: j['tin'] as String?,
        pagibig: j['pagibig'] as String?,
        driversLicense: j['drivers_license'] as String?,
      );
}

class Profile {
  Profile({
    required this.userId,
    required this.name,
    required this.role,
    required this.department,
    required this.email,
    required this.employeeId,
    required this.privilege,
    required this.yearsOfService,
    required this.background,
  });

  final String userId;
  final String name;
  final String role;
  final String department;
  final String email;
  final String employeeId;
  final String privilege;
  final String yearsOfService;
  final PersonalBackground background;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        userId: (j['user_id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        role: (j['role'] ?? '') as String,
        department: (j['department'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        employeeId: (j['employee_id'] ?? '') as String,
        privilege: (j['privilege'] ?? 'employee') as String,
        yearsOfService: (j['years_of_service'] ?? '').toString(),
        background: PersonalBackground.fromJson(
            (j['personal_background'] as Map?)?.cast<String, dynamic>() ?? {}),
      );
}

// ---- Profile extras (Personal Background, MDR, Linked Accounts) ----

class ProfileBackground {
  ProfileBackground({
    required this.personalInfo,
    required this.emergency,
    required this.family,
    required this.education,
    required this.previousEmployment,
  });

  /// Ordered label -> value for the Personal Information card.
  final Map<String, String> personalInfo;
  final Map<String, String> emergency; // name / relationship / phone
  final List<Map<String, String>> family;
  final List<Map<String, String>> education;
  final List<Map<String, String>> previousEmployment;

  static String _s(dynamic v) => (v ?? '').toString();

  static List<Map<String, String>> _rows(dynamic list) =>
      ((list as List?) ?? [])
          .map((e) => (e as Map)
              .map((k, v) => MapEntry(k.toString(), _s(v))))
          .toList();

  factory ProfileBackground.fromJson(Map<String, dynamic> j) {
    final pi = (j['personal_info'] as Map?)?.cast<String, dynamic>() ?? {};
    final ec = (j['emergency_contact'] as Map?)?.cast<String, dynamic>() ?? {};
    return ProfileBackground(
      personalInfo: {
        'Nickname': _s(pi['nickname']),
        'Full Name': _s(pi['full_name']),
        'Mobile': _s(pi['mobile']),
        'Telephone': _s(pi['telephone']),
        'Email': _s(pi['email']),
        'Birthplace': _s(pi['birthplace']),
        'Address': _s(pi['address']),
        'Civil Status': _s(pi['civil_status']),
        'Religion': _s(pi['religion']),
      },
      emergency: {
        'name': _s(ec['name']),
        'relationship': _s(ec['relationship']),
        'phone': _s(ec['phone']),
      },
      family: _rows(j['family']),
      education: _rows(j['education']),
      previousEmployment: _rows(j['previous_employment']),
    );
  }
}

class Mdr {
  Mdr({
    required this.status,
    required this.items,
  });

  final String status;

  /// Ordered label -> value for the MDR summary card.
  final Map<String, String> items;

  factory Mdr.fromJson(Map<String, dynamic> j) {
    String s(dynamic v) => (v ?? '').toString();
    // Preferred shape: an ordered `items` object of label -> value. Falls back
    // to the older flat keys (still used by the seed) for compatibility.
    final raw = j['items'];
    final Map<String, String> items = raw is Map
        ? raw.map((k, v) => MapEntry(k.toString(), s(v)))
        : {
            'PhilHealth PIN': s(j['philhealth_pin']),
            'Membership Category': s(j['membership_category']),
            'Employer': s(j['employer']),
            'Declared Dependents': s(j['declared_dependents']),
          };
    return Mdr(
      status: s(j['status']).isEmpty ? 'ACTIVE' : s(j['status']),
      items: items,
    );
  }
}

/// Result of starting 2FA enrollment (POST /auth/2fa/setup).
class TwoFactorSetup {
  TwoFactorSetup({
    required this.secret,
    required this.otpauthUrl,
    required this.account,
    required this.issuer,
  });

  final String secret;
  final String otpauthUrl;
  final String account;
  final String issuer;

  factory TwoFactorSetup.fromJson(Map<String, dynamic> j) => TwoFactorSetup(
        secret: (j['secret'] ?? '') as String,
        otpauthUrl: (j['otpauth_url'] ?? '') as String,
        account: (j['account'] ?? '') as String,
        issuer: (j['issuer'] ?? '') as String,
      );
}

/// One certification the employee may hold (Versatech).
class Cert {
  Cert({
    required this.certNo,
    required this.name,
    required this.active,
    required this.fileName,
    required this.dateUploaded,
  });

  final int certNo;
  final String name;
  final bool active;
  final String fileName;
  final String dateUploaded;

  factory Cert.fromJson(Map<String, dynamic> j) => Cert(
        certNo: (j['cert_no'] as num?)?.toInt() ?? 0,
        name: (j['name'] ?? '') as String,
        active: (j['active'] ?? false) as bool,
        fileName: (j['file_name'] ?? '') as String,
        dateUploaded: (j['date_uploaded'] ?? '') as String,
      );
}

/// A certification level with its certificates.
class CertLevel {
  CertLevel({required this.level, required this.items});
  final int level;
  final List<Cert> items;

  factory CertLevel.fromJson(Map<String, dynamic> j) => CertLevel(
        level: (j['level'] as num?)?.toInt() ?? 1,
        items: ((j['items'] as List?) ?? [])
            .map((e) => Cert.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class LinkedAccount {
  LinkedAccount({
    required this.provider,
    required this.title,
    required this.subtitle,
    required this.connected,
  });

  final String provider;
  final String title;
  final String subtitle;
  final bool connected;

  factory LinkedAccount.fromJson(Map<String, dynamic> j) => LinkedAccount(
        provider: (j['provider'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        subtitle: (j['subtitle'] ?? '') as String,
        connected: (j['connected'] ?? false) as bool,
      );
}

class LeaveBucket {
  LeaveBucket({required this.type, required this.remaining});
  final String type;
  final double remaining;

  factory LeaveBucket.fromJson(Map<String, dynamic> j) => LeaveBucket(
        type: (j['type'] ?? '') as String,
        remaining: (j['remaining'] as num?)?.toDouble() ?? 0,
      );
}

class LeaveBalance {
  LeaveBalance({
    required this.year,
    required this.totalRemainingDays,
    required this.buckets,
    this.approvedLeaveHours,
    this.approvedUtHours,
    this.approvedLeave,
    this.approvedUt,
    this.additionalVl,
    this.slPaid,
    this.vlPaid,
    this.slPaidHours,
    this.vlPaidHours,
  });

  final int year;
  final double totalRemainingDays;
  final List<LeaveBucket> buckets;
  final num? approvedLeaveHours;
  final num? approvedUtHours;

  // "Remaining Leave Hours" tiles as HH:MM strings (null -> show a dash).
  final String? approvedLeave;
  final String? approvedUt;
  final String? additionalVl;
  final String? slPaid;
  final String? vlPaid;

  // Raw hours for the dashboard leave credits.
  final num? slPaidHours;
  final num? vlPaidHours;

  factory LeaveBalance.fromJson(Map<String, dynamic> j) {
    String? s(dynamic v) {
      final str = v?.toString().trim();
      return (str == null || str.isEmpty) ? null : str;
    }

    return LeaveBalance(
      year: (j['year'] as num?)?.toInt() ?? 0,
      totalRemainingDays: (j['total_remaining_days'] as num?)?.toDouble() ?? 0,
      buckets: ((j['buckets'] as List?) ?? [])
          .map((e) => LeaveBucket.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      approvedLeaveHours: j['approved_leave_hours'] as num?,
      approvedUtHours: j['approved_ut_hours'] as num?,
      approvedLeave: s(j['approved_leave']),
      approvedUt: s(j['approved_ut']),
      additionalVl: s(j['additional_vl']),
      slPaid: s(j['sl_paid']),
      vlPaid: s(j['vl_paid']),
      slPaidHours: j['sl_paid_hours'] as num?,
      vlPaidHours: j['vl_paid_hours'] as num?,
    );
  }
}

class PayPeriod {
  PayPeriod({required this.code, required this.range, this.year});
  final String code;
  final String range;
  final String? year;

  factory PayPeriod.fromJson(Map<String, dynamic> j) => PayPeriod(
        code: (j['code'] ?? '') as String,
        range: (j['range'] ?? '') as String,
        year: j['year']?.toString(),
      );
}

class AttendanceToday {
  AttendanceToday({
    required this.status,
    required this.shift,
    required this.timeIn,
    required this.timeOut,
    required this.breakMinutes,
    required this.overtime,
    required this.totalHoursToday,
    required this.date,
  });

  final String status; // CLOCKED_IN | CLOCKED_OUT
  final String shift;
  final String? timeIn;
  final String? timeOut;
  final int breakMinutes;
  final String overtime;
  final String totalHoursToday;
  final String date;

  bool get isClockedIn => status == 'CLOCKED_IN';

  factory AttendanceToday.fromJson(Map<String, dynamic> j) => AttendanceToday(
        status: (j['status'] ?? 'CLOCKED_OUT') as String,
        shift: (j['shift'] ?? '') as String,
        timeIn: j['time_in'] as String?,
        timeOut: j['time_out'] as String?,
        breakMinutes: (j['break_minutes'] as num?)?.toInt() ?? 0,
        overtime: (j['overtime'] ?? '') as String,
        totalHoursToday: (j['total_hours_today'] ?? '') as String,
        date: (j['date'] ?? '') as String,
      );
}

class AttendanceDay {
  AttendanceDay({required this.day, required this.hours, required this.today});
  final String day;
  final double hours;
  final bool today;

  factory AttendanceDay.fromJson(Map<String, dynamic> j) => AttendanceDay(
        day: (j['day'] ?? '') as String,
        hours: (j['hours'] as num?)?.toDouble() ?? 0,
        today: (j['today'] ?? false) as bool,
      );
}

class AttendanceSummary {
  AttendanceSummary(
      {required this.present, required this.late, required this.leave});
  final int present;
  final int late;
  final int leave;

  factory AttendanceSummary.fromJson(Map<String, dynamic> j) =>
      AttendanceSummary(
        present: (j['present'] as num?)?.toInt() ?? 0,
        late: (j['late'] as num?)?.toInt() ?? 0,
        leave: (j['leave'] as num?)?.toInt() ?? 0,
      );
}

class Attendance {
  Attendance({required this.today, required this.week, required this.summary});
  final AttendanceToday today;
  final List<AttendanceDay> week;
  final AttendanceSummary summary;

  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
        today: AttendanceToday.fromJson(
            (j['today'] as Map).cast<String, dynamic>()),
        week: ((j['week'] as List?) ?? [])
            .map((e) =>
                AttendanceDay.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        summary: AttendanceSummary.fromJson(
            (j['summary'] as Map).cast<String, dynamic>()),
      );
}

class Approval {
  Approval({
    required this.id,
    required this.employee,
    required this.type,
    required this.detail,
    required this.days,
    required this.status,
    required this.filed,
  });

  final int id;
  final String employee;
  final String type;
  final String detail;
  final String days;
  final String status;
  final String filed;

  factory Approval.fromJson(Map<String, dynamic> j) => Approval(
        id: (j['id'] as num).toInt(),
        employee: (j['employee'] ?? '') as String,
        type: (j['type'] ?? '') as String,
        detail: (j['detail'] ?? '') as String,
        days: (j['days'] ?? '') as String,
        status: (j['status'] ?? 'Pending') as String,
        filed: (j['filed'] ?? '') as String,
      );
}

class NotificationsResult {
  NotificationsResult({required this.items, required this.unread});
  final List<AppNotification> items;
  final int unread;
}

/// Whether the signed-in user is a department approver, and how many filings are
/// awaiting their decision. Drives the Approvals entry visibility + badge.
class ApprovalAccess {
  const ApprovalAccess({
    required this.isApprover,
    required this.pending,
    this.pendingRequests = 0,
  });
  final bool isApprover;

  /// Records Approval (LOA / CA / MAD / OT) awaiting a decision.
  final int pending;

  /// Request Approval (Other Requests — th_request_head) awaiting a decision.
  final int pendingRequests;
}

/// One filing in the approver's inbox (a team member's request). Carries the
/// request [type] + numeric [id] so a decision can be posted through the
/// per-type action endpoint.
class ApprovalTask {
  const ApprovalTask({
    required this.type,
    required this.app,
    required this.id,
    required this.no,
    required this.employee,
    required this.employeeId,
    required this.category,
    required this.detail,
    required this.appliedHours,
    required this.approvedOtHours,
    required this.dateApplied,
    required this.dateSent,
    required this.txnDate,
    required this.approvedBy,
    required this.approvedDate,
    required this.status,
    this.company = '',
    this.requestTypeName = '',
    this.reason = '',
  });

  /// Backend request type: loa | call-approval | manual-ad | overtime.
  final String type;

  /// Short application code shown in the list: LOA | CA | MAD | OT, or the
  /// request code (COE | EPP | ITR | COL | BUP | ID) for the requests module.
  final String app;
  final int id;
  final String no;
  final String employee;
  final String employeeId;
  final String category;
  final String detail;

  /// Requests module only: company, full request-type name, and the reason.
  final String company;
  final String requestTypeName;
  final String reason;

  /// hh:mm strings (e.g. "9:00", "3:30").
  final String appliedHours;
  final String approvedOtHours;
  final String dateApplied;
  final String dateSent;
  final String txnDate;
  final String approvedBy;
  final String approvedDate;
  final String status;

  /// A stable per-row key (type + id) for selection sets.
  String get key => '$type#$id';

  /// True while the filing still needs a decision.
  bool get isPending =>
      status == 'For Approval' || status == 'For Witness Approval';

  factory ApprovalTask.fromJson(Map<String, dynamic> j) {
    String s(dynamic v) => (v ?? '').toString();
    return ApprovalTask(
      type: s(j['type']),
      app: s(j['app']),
      id: (j['id'] as num?)?.toInt() ?? 0,
      no: s(j['no']),
      employee: s(j['employee']),
      employeeId: s(j['employee_id']),
      category: s(j['category']),
      detail: s(j['detail']),
      appliedHours: s(j['applied_hours']).isEmpty ? '0:00' : s(j['applied_hours']),
      approvedOtHours:
          s(j['approved_ot_hours']).isEmpty ? '0:00' : s(j['approved_ot_hours']),
      dateApplied: s(j['date_applied']),
      dateSent: s(j['date_sent']),
      txnDate: s(j['txn_date']),
      approvedBy: s(j['approved_by']),
      approvedDate: s(j['approved_date']),
      status: s(j['status']).isEmpty ? 'For Approval' : s(j['status']),
      company: s(j['company']),
      requestTypeName: s(j['request_type_name']),
      reason: s(j['reason']),
    );
  }
}

DateTime? parseAppDateTime(dynamic val, {bool isFrom = true}) {
  if (val == null) return null;
  if (val is DateTime) return val;
  final str = val.toString().trim();
  if (str.isEmpty) return null;

  final iso = DateTime.tryParse(str);
  if (iso != null) {
    if (str.length <= 10) {
      return DateTime(iso.year, iso.month, iso.day, isFrom ? 8 : 18, 0);
    }
    return iso;
  }

  const months = {
    'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5,
    'june': 6, 'july': 7, 'august': 8, 'september': 9, 'october': 10,
    'november': 11, 'december': 12, 'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
    'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  final m1 = RegExp(
          r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:\s+(\d{1,2}):(\d{1,2})(?:\s*(AM|PM))?)?',
          caseSensitive: false)
      .firstMatch(str);
  if (m1 != null) {
    final mon = int.parse(m1.group(1)!);
    final day = int.parse(m1.group(2)!);
    final yr = int.parse(m1.group(3)!);
    if (m1.group(4) != null) {
      var hr = int.parse(m1.group(4)!);
      final min = int.parse(m1.group(5) ?? '0');
      final ampm = m1.group(6)?.toUpperCase();
      if (ampm == 'PM' && hr < 12) hr += 12;
      if (ampm == 'AM' && hr == 12) hr = 0;
      return DateTime(yr, mon, day, hr, min);
    }
    return DateTime(yr, mon, day, isFrom ? 8 : 18, 0);
  }

  final m2 = RegExp(
          r'^([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})(?:\s+(\d{1,2}):(\d{1,2})(?:\s*(AM|PM))?)?',
          caseSensitive: false)
      .firstMatch(str);
  if (m2 != null) {
    final mon = months[m2.group(1)!.toLowerCase()];
    if (mon != null) {
      final day = int.parse(m2.group(2)!);
      final yr = int.parse(m2.group(3)!);
      if (m2.group(4) != null) {
        var hr = int.parse(m2.group(4)!);
        final min = int.parse(m2.group(5) ?? '0');
        final ampm = m2.group(6)?.toUpperCase();
        if (ampm == 'PM' && hr < 12) hr += 12;
        if (ampm == 'AM' && hr == 12) hr = 0;
        return DateTime(yr, mon, day, hr, min);
      }
      return DateTime(yr, mon, day, isFrom ? 8 : 18, 0);
    }
  }

  return null;
}

/// A record in the Record / Request hub (Leave of Absence, Call Approval,
/// Manual Arrival/Departure, Overtime). One flexible shape; type-specific
/// fields are nullable.
class RequestRecord {
  RequestRecord({
    required this.id,
    required this.no,
    required this.dateApplied,
    required this.txnDate,
    required this.status,
    this.leaveType,
    this.requestType,
    this.filedBy,
    this.approvedBy,
    this.approvedDate,
    this.witnessedBy,
    this.appliedHours,
    this.approvedHours,
    this.reason,
    this.dateFrom,
    this.dateTo,
    this.timeFrom,
    this.timeTo,
    this.noOfHours,
    this.rawJson,
  });

  final int id;
  final String no;
  final String dateApplied;
  final String txnDate;
  final String status;
  final String? leaveType;

  /// Other Requests type code (e.g. COE / COL / ITR).
  final String? requestType;
  final String? filedBy;
  final String? approvedBy;
  final String? approvedDate;
  final String? witnessedBy;
  final String? appliedHours;
  final String? approvedHours;
  final String? reason;
  final String? dateFrom;
  final String? dateTo;
  final String? timeFrom;
  final String? timeTo;
  final double? noOfHours;
  final Map<String, dynamic>? rawJson;

  DateTime? get appliedDate => parseAppDateTime(dateApplied);

  factory RequestRecord.fromJson(Map<String, dynamic> j) {
    String? s(dynamic v) {
      if (v == null) return null;
      final str = v.toString().trim();
      return str.isEmpty ? null : str;
    }

    String sOr(dynamic v, String def) => s(v) ?? def;

    final idVal = j['id'] ??
        j['loa_id'] ??
        j['leave_id'] ??
        j['request_id'] ??
        j['record_id'] ??
        j['trans_id'] ??
        j['pk'] ??
        j['id_no'];
    final id = idVal is num
        ? idVal.toInt()
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    final dFrom = s(j['date_from'] ??
        j['start_date'] ??
        j['from_date'] ??
        j['from'] ??
        j['date_start'] ??
        j['time_from'] ??
        j['from_time'] ??
        j['period_from'] ??
        j['start_datetime'] ??
        j['from_datetime'] ??
        j['start_time']);

    final dTo = s(j['date_to'] ??
        j['end_date'] ??
        j['to_date'] ??
        j['to'] ??
        j['date_end'] ??
        j['time_to'] ??
        j['to_time'] ??
        j['period_to'] ??
        j['end_datetime'] ??
        j['to_datetime'] ??
        j['end_time']);

    final rsn = s(j['reason'] ??
        j['remarks'] ??
        j['purpose'] ??
        j['description'] ??
        j['notes'] ??
        j['details'] ??
        j['justification'] ??
        j['reason_for_leave'] ??
        j['loa_reason'] ??
        j['comment'] ??
        j['comments']);

    final lType = s(j['leave_type'] ??
        j['leave_type_name'] ??
        j['type'] ??
        j['type_name'] ??
        j['leave_name'] ??
        j['category'] ??
        j['loa_type']);

    final tDate = sOr(
        j['txn_date'] ??
            j['transaction_date'] ??
            j['loa_date'] ??
            j['leave_date'] ??
            j['date'] ??
            dFrom ??
            j['created_at'],
        '');

    return RequestRecord(
      id: id,
      no: sOr(
          j['no'] ??
              j['reference_no'] ??
              j['ref_no'] ??
              j['doc_no'] ??
              j['txn_no'] ??
              j['control_no'] ??
              j['code'] ??
              (id > 0 ? 'LOA-$id' : ''),
          ''),
      dateApplied: sOr(
          j['date_applied'] ??
              j['applied_date'] ??
              j['created_at'] ??
              j['date_created'] ??
              j['filing_date'] ??
              j['filed_date'],
          ''),
      txnDate: tDate,
      status: sOr(j['status'] ?? j['request_status'] ?? j['state'], 'Pending'),
      leaveType: lType,
      requestType: s(j['request_type']),
      filedBy: s(j['filed_by'] ??
          j['employee_name'] ??
          j['name'] ??
          j['emp_name'] ??
          j['employee']),
      approvedBy: s(j['approved_by'] ??
          j['approver'] ??
          j['approver_name'] ??
          j['approved_by_name']),
      approvedDate: s(j['approved_date'] ??
          j['approval_date'] ??
          j['date_approved']),
      witnessedBy: s(j['witnessed_by'] ??
          j['witness'] ??
          j['witness_name'] ??
          j['witnessed_by_name']),
      appliedHours: s(j['applied_hours'] ??
          j['hours'] ??
          j['applied_hrs'] ??
          j['no_of_hours'] ??
          j['duration']),
      approvedHours: s(j['approved_hours'] ?? j['approved_hrs']),
      reason: rsn,
      dateFrom: dFrom,
      dateTo: dTo,
      timeFrom: s(j['time_from']),
      timeTo: s(j['time_to']),
      noOfHours: (j['no_of_hours'] ?? j['hours'] ?? j['applied_hours'] ?? j['applied_hrs']) is num
          ? (j['no_of_hours'] ?? j['hours'] ?? j['applied_hours'] ?? j['applied_hrs']).toDouble()
          : double.tryParse((j['no_of_hours'] ?? j['hours'] ?? j['applied_hours'] ?? j['applied_hrs'] ?? '').toString()),
      rawJson: j,
    );
  }
}

/// One "out of office" record from the anihrs.vw_whos_out view, as returned by
/// GET /api/v1/hris/whosout. This is the same source the web calendar reads, so
/// the mobile per-day counts match the web and the database exactly.
class WhosOutRecord {
  WhosOutRecord({
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.from,
    required this.to,
    this.remarks,
  });

  final String name;

  /// Raw category from the view: `loa` (Leave of Absence) or `ca` (Call
  /// Approval).
  final String type;

  /// Human-readable label supplied by the backend (`type_label`).
  final String typeLabel;

  final DateTime from;
  final DateTime to;
  final String? remarks;

  /// Parses the backend's date strings, keeping only the calendar day so a
  /// record that spans midnight still lands on the right dates.
  static DateTime _day(dynamic v) {
    final parsed = DateTime.tryParse((v ?? '').toString());
    final d = parsed ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  factory WhosOutRecord.fromJson(Map<String, dynamic> j) => WhosOutRecord(
        name: (j['name'] ?? '').toString().trim(),
        type: (j['type'] ?? '').toString(),
        typeLabel: (j['type_label'] ?? j['type'] ?? '').toString(),
        from: _day(j['date_from']),
        to: _day(j['date_to']),
        remarks: j['remarks'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Service. One method per backend endpoint. All calls reuse the shared
// ApiClient (and its bearer token) held on AppSession.
// ---------------------------------------------------------------------------

class HrisApi {
  HrisApi._();
  static final HrisApi instance = HrisApi._();

  ApiClient get _api => AppSession.instance.api;

  List<Map<String, dynamic>> _dataList(dynamic res) {
    final list = (res is Map ? res['data'] : res) as List? ?? [];
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Map<String, dynamic> _asMap(dynamic res) =>
      (res as Map).cast<String, dynamic>();

  // ---- Tenants (public — no auth needed) ----
  Future<List<Tenant>> tenants() async =>
      _dataList(await _api.get('/public/tenants'))
          .map(Tenant.fromJson)
          .toList();

  // ---- App version gate (public — checked on launch, before login) ----
  // Returns { minSupportedVersion, latestVersion, storeUrl, platform }.
  Future<Map<String, dynamic>> appVersion({
    required String platform,
    String? tenant,
  }) async {
    final q = StringBuffer('/public/app-version?platform=$platform');
    if (tenant != null && tenant.isNotEmpty) q.write('&tenant=$tenant');
    return _asMap((await _api.get(q.toString()))['data']);
  }

  // Requests a password-reset email for the given employee ID or email address
  // in the selected tenant. The backend always returns success regardless of
  // whether the account exists (no account enumeration).
  Future<void> forgotPassword({required String identifier, String? tenant}) =>
      _api.post('/public/forgot-password', body: {
        'identifier': identifier,
        if (tenant != null && tenant.isNotEmpty) 'tenant': tenant,
      });

  // ---- Profile ----
  Future<Profile> getProfile() async =>
      Profile.fromJson(_asMap(await _api.get('/auth/profile')));

  Future<ProfileBackground> profileBackground() async =>
      ProfileBackground.fromJson(_asMap(await _api.get('/auth/profile/background')));

  Future<Mdr> profileMdr() async =>
      Mdr.fromJson(_asMap(await _api.get('/auth/profile/mdr')));

  Future<List<CertLevel>> certificates() async =>
      ((_asMap(await _api.get('/auth/profile/certificates'))['levels']
                  as List?) ??
              [])
          .map((e) => CertLevel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

  Future<List<LinkedAccount>> linkedAccounts() async =>
      _dataList(await _api.get('/auth/profile/linked-accounts'))
          .map(LinkedAccount.fromJson)
          .toList();

  Future<void> updateProfile(
      {String? email, String? department, String? role}) async {
    await _api.put('/auth/profile', body: {
      'email': ?email,
      'department': ?department,
      'role': ?role,
    });
  }

  // ---- Security: change password + TOTP 2FA ----
  Future<void> changePassword({
    required String current,
    required String next,
    required String confirm,
  }) async {
    await _api.post('/auth/profile/change-password', body: {
      'current_password': current,
      'new_password': next,
      'confirm_password': confirm,
    });
  }

  /// Confirms the signed-in user's current password (for enabling biometrics).
  Future<bool> verifyPassword(String password) async =>
      (_asMap(await _api.post('/auth/verify-password',
              body: {'password': password}))['valid'] as bool?) ??
      false;

  /// Whether TOTP two-factor is currently enabled for the signed-in user.
  Future<bool> twoFactorStatus() async =>
      (_asMap(await _api.get('/auth/2fa/status'))['enabled'] as bool?) ?? false;

  /// Begins 2FA enrollment: returns the shared secret and the `otpauth://` URI
  /// to render as a QR for Google/Microsoft Authenticator.
  Future<TwoFactorSetup> twoFactorSetup() async =>
      TwoFactorSetup.fromJson(_asMap(await _api.post('/auth/2fa/setup')));

  /// Confirms the 6-digit [code] and activates 2FA.
  Future<void> twoFactorVerify(String code) async {
    await _api.post('/auth/2fa/verify', body: {'code': code});
  }

  /// Turns 2FA off (requires a valid current [code]).
  Future<void> twoFactorDisable(String code) async {
    await _api.post('/auth/2fa/disable', body: {'code': code});
  }

  // ---- Directory ----
  Future<List<Employee>> directory({String? search, String? department}) async {
    final q = <String>[];
    if (search != null && search.isNotEmpty) {
      q.add('search=${Uri.encodeQueryComponent(search)}');
    }
    if (department != null && department.isNotEmpty && department != 'All') {
      q.add('department=${Uri.encodeQueryComponent(department)}');
    }
    final path = '/auth/directory${q.isEmpty ? '' : '?${q.join('&')}'}';
    return _dataList(await _api.get(path)).map(Employee.fromJson).toList();
  }

  Future<List<Employee>> whosOut() async =>
      _dataList(await _api.get('/auth/directory/whos-out'))
          .map(Employee.fromJson)
          .toList();

  /// Everyone out (LOA + Call Approval) whose date range touches [month]/[year].
  /// Backs the Who's Out calendar; mirrors the web calendar's month filter.
  Future<List<WhosOutRecord>> whosOutMonth(int month, int year) async =>
      _dataList(await _api.get('/hris/whosout?month=$month&year=$year'))
          .map(WhosOutRecord.fromJson)
          .toList();

  // ---- Leaves ----
  Future<List<LeaveRequest>> leaves({String status = 'All'}) async =>
      _dataList(await _api.get(
              '/auth/leaves?status=${Uri.encodeQueryComponent(status)}'))
          .map(LeaveRequest.fromJson)
          .toList();

  Future<LeaveRequest> fileLeave({
    required String type,
    required String startDate,
    String? endDate,
    String? days,
    String? reason,
  }) async {
    final res = await _api.post('/auth/leaves', body: {
      'type': type,
      'start_date': startDate,
      'end_date': ?endDate,
      'days': ?days,
      'reason': ?reason,
    });
    return LeaveRequest.fromJson(_asMap(_asMap(res)['data']));
  }

  Future<LeaveBalance> leaveBalance() async =>
      LeaveBalance.fromJson(_asMap(await _api.get('/auth/leaves/balance')));

  Future<LeaveBalance> leaveHours() async =>
      LeaveBalance.fromJson(_asMap(await _api.get('/auth/leaves/hours')));

  // ---- Payroll ----
  Future<List<Payslip>> payslips() async =>
      _dataList(await _api.get('/auth/payslips'))
          .map(Payslip.fromJson)
          .toList();

  Future<Payslip> payslip(String id) async =>
      Payslip.fromJson(_asMap(await _api.get('/auth/payslips/$id')));

  /// Pay periods that have data for the current employee. Pass [type]
  /// ('timesheet' or 'payslip') to filter to periods that actually exist.
  Future<List<PayPeriod>> payPeriods({String? type}) async =>
      _dataList(await _api.get(
              '/auth/pay-periods${type != null ? '?type=$type' : ''}'))
          .map(PayPeriod.fromJson)
          .toList();

  Future<TimesheetDetail> timesheet(String id) async =>
      TimesheetDetail.fromJson(_asMap(await _api.get('/auth/timesheets/$id')));

  // ---- Attendance ----
  Future<Attendance> attendance() async =>
      Attendance.fromJson(_asMap(await _api.get('/auth/attendance')));

  Future<AttendanceToday> clockIn() async => AttendanceToday.fromJson(
      _asMap(_asMap(await _api.post('/auth/attendance/clock-in'))['data']));

  Future<AttendanceToday> clockOut() async => AttendanceToday.fromJson(
      _asMap(_asMap(await _api.post('/auth/attendance/clock-out'))['data']));

  // ---- Notifications ----
  Future<NotificationsResult> notifications() async {
    final res = _asMap(await _api.get('/auth/notifications'));
    return NotificationsResult(
      items: _dataList(res).map(AppNotification.fromJson).toList(),
      unread: (res['unread'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> markNotificationRead(int id) async =>
      _api.post('/auth/notifications/$id/read');

  Future<void> markAllNotificationsRead() async =>
      _api.post('/auth/notifications/read-all');

  // ---- Record / Request hub ----
  // type: 'loa' | 'call-approval' | 'manual-ad' | 'overtime'
  Future<List<RequestRecord>> requestRecords(String type) async =>
      _dataList(await _api.get('/auth/requests/$type'))
          .map(RequestRecord.fromJson)
          .toList();

  Future<RequestRecord> getRequest(String type, int id) async {
    final endpoints = <String>[
      '/auth/requests/$type/$id',
      '/hris/requests/$type/$id',
      if (type == 'loa') ...[
        '/auth/leaves/$id',
        '/hris/leaves/$id',
        '/auth/loa/$id',
        '/hris/loa/$id',
      ],
      '/auth/requests/$id',
      '/auth/$type/$id',
    ];

    dynamic lastError;
    for (final ep in endpoints) {
      try {
        final res = await _api.get(ep);
        if (res != null) {
          final map = _extractMap(res);
          if (map.isNotEmpty) {
            return RequestRecord.fromJson(map);
          }
        }
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw lastError;
    throw ApiException('Request record not found');
  }

  static Map<String, dynamic> _extractMap(dynamic res) {
    if (res is! Map) return {};
    var map = res.cast<String, dynamic>();
    if (map['data'] is Map) {
      map = (map['data'] as Map).cast<String, dynamic>();
    } else if (map['record'] is Map) {
      map = (map['record'] as Map).cast<String, dynamic>();
    } else if (map['result'] is Map) {
      map = (map['result'] as Map).cast<String, dynamic>();
    } else if (map['item'] is Map) {
      map = (map['item'] as Map).cast<String, dynamic>();
    } else if (map['loa'] is Map) {
      map = (map['loa'] as Map).cast<String, dynamic>();
    } else if (map['leave'] is Map) {
      map = (map['leave'] as Map).cast<String, dynamic>();
    }
    return map;
  }

  Future<RequestRecord> createRequest(
      String type, Map<String, dynamic> body) async {
    final res = await _api.post('/auth/requests/$type', body: body);
    final data = res is Map && res['data'] != null ? res['data'] : res;
    return RequestRecord.fromJson(_asMap(data));
  }

  Future<RequestRecord> updateRequest(
      String type, int id, Map<String, dynamic> body) async {
    final res = await _api.put('/auth/requests/$type/$id', body: body);
    final data = res is Map && res['data'] != null ? res['data'] : res;
    return RequestRecord.fromJson(_asMap(data));
  }

  Future<void> sendForApproval(String type, int id) async {
    try {
      await _api.post('/auth/requests/$type/$id/send');
    } catch (_) {
      await _api.put('/auth/requests/$type/$id', body: {'status': 'For Approval'});
    }
  }

  Future<void> reverseRecord(String type, int id) async {
    try {
      await _api.post('/auth/requests/$type/$id/reverse');
    } catch (_) {
      await _api.put('/auth/requests/$type/$id', body: {'status': 'Reversed'});
    }
  }

  Future<void> resendRecord(String type, int id) async {
    try {
      await _api.post('/auth/requests/$type/$id/resend');
    } catch (_) {
      await _api.put('/auth/requests/$type/$id', body: {'status': 'For Approval'});
    }
  }

  Future<void> cancelRecord(String type, int id) async {
    try {
      await _api.post('/auth/requests/$type/$id/cancel');
    } catch (_) {
      await _api.put('/auth/requests/$type/$id', body: {'status': 'Cancelled'});
    }
  }

  /// Approve a request record (LOA / Call Approval / Manual A-D / Overtime).
  /// Posts the decision + approver stamp to the record's real table.
  Future<void> approveRecord(String type, int id) async {
    try {
      await _api.post('/auth/requests/$type/$id/approve');
    } catch (_) {
      await _api.put('/auth/requests/$type/$id', body: {'status': 'Approved'});
    }
  }

  /// Disapprove (reject) a request record, stamping the approver + decision.
  Future<void> disapproveRecord(String type, int id) async {
    try {
      await _api.post('/auth/requests/$type/$id/disapprove');
    } catch (_) {
      await _api.put('/auth/requests/$type/$id', body: {'status': 'Disapproved'});
    }
  }

  // ---- Approvals (approver roles only) ----
  Future<List<Approval>> approvals({String status = ''}) async {
    final path =
        '/auth/approvals${status.isEmpty ? '' : '?status=${Uri.encodeQueryComponent(status)}'}';
    return _dataList(await _api.get(path)).map(Approval.fromJson).toList();
  }

  Future<Approval> approve(int id) async => Approval.fromJson(
      _asMap(_asMap(await _api.post('/auth/approvals/$id/approve'))['data']));

  Future<Approval> reject(int id) async => Approval.fromJson(
      _asMap(_asMap(await _api.post('/auth/approvals/$id/reject'))['data']));

  // ---- Approvals inbox (department approvers) ----

  /// Whether the signed-in user is a department approver (+ pending count).
  Future<ApprovalAccess> approvalAccess() async {
    try {
      final m = _asMap(await _api.get('/auth/approvals/access'));
      return ApprovalAccess(
        isApprover: m['isApprover'] == true,
        pending: (m['pending'] as num?)?.toInt() ?? 0,
        pendingRequests: (m['pendingRequests'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return const ApprovalAccess(isApprover: false, pending: 0);
    }
  }

  /// The approver's inbox. [scope] is 'pending' (awaiting decision) or
  /// 'history' (already decided). [module] is 'records' (LOA/CA/MAD/OT) or
  /// 'requests' (Other Requests — th_request_head).
  Future<List<ApprovalTask>> approvalTasks(
    String scope, {
    String module = 'records',
  }) async =>
      _dataList(await _api.get('/auth/approvals?scope=$scope&module=$module'))
          .map(ApprovalTask.fromJson)
          .toList();

  // ---- Push notifications (FCM device tokens) ----

  /// Register this device's FCM token so the backend can push to it.
  Future<void> registerFcmToken({
    required String token,
    required String platform,
    String? deviceId,
    String? deviceModel,
  }) async {
    await _api.post('/auth/fcm-token', body: {
      'fcm_token': token,
      'platform': platform,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceModel != null) 'device_model': deviceModel,
    });
  }

  /// Remove a device token (on logout) so a signed-out phone stops receiving.
  Future<void> unregisterFcmToken(String token) async {
    await _api.post('/auth/fcm-token/remove', body: {'fcm_token': token});
  }
}
