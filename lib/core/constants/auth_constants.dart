/// Rules shared by the registration and login forms.
abstract final class AuthConstants {
  /// The only institutional domains allowed to sign up.
  static const List<String> allowedEmailDomains = <String>[
    'alustudent.com',
    'alueducation.com',
    staffEmailDomain,
  ];

  /// Accounts on this domain are created as staff and skip email
  /// verification. Mirrored in `firestore.rules` (`isStaffDomain()`).
  static const String staffEmailDomain = 'aluedu.com';

  static const int minPasswordLength = 6;

  /// Human readable domain list, e.g.
  /// `@alustudent.com, @alueducation.com or @aluedu.com`.
  static String get allowedDomainsLabel {
    final List<String> labels =
        allowedEmailDomains.map((String domain) => '@$domain').toList(growable: false);
    if (labels.length == 1) return labels.single;

    return '${labels.sublist(0, labels.length - 1).join(', ')} or ${labels.last}';
  }

  /// True when [email] uses one of [allowedEmailDomains].
  static bool isAluEmail(String email) {
    final String? domain = _domainOf(email);

    return domain != null && allowedEmailDomains.contains(domain);
  }

  /// True for staff-domain addresses, which get the staff role and do not need
  /// to verify their email.
  static bool isStaffEmail(String email) => _domainOf(email) == staffEmailDomain;

  static String? _domainOf(String email) {
    final String normalized = email.trim().toLowerCase();
    final int atIndex = normalized.lastIndexOf('@');
    if (atIndex <= 0 || atIndex == normalized.length - 1) return null;

    return normalized.substring(atIndex + 1);
  }
}
