import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/firestore_date.dart';

/// Role of a registered campus user.
enum UserRole {
  student('student', 'Student'),
  staff('staff', 'Staff');

  const UserRole(this.value, this.label);

  /// Exact value stored in Firestore (`role` field).
  final String value;

  /// Human readable label.
  final String label;

  /// Parses a Firestore value, falling back to [UserRole.student].
  static UserRole fromValue(String? value) {
    return values.firstWhere(
      (UserRole role) => role.value == value,
      orElse: () => UserRole.student,
    );
  }
}

/// A document in the `users/{uid}` collection.
@immutable
class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.department,
    required this.location,
    required this.createdAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final UserRole role;
  final String department;
  final String location;
  final DateTime createdAt;

  /// [uid] is passed separately so it can be taken from the document id when
  /// the stored field is missing.
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: (map['uid'] as String?) ?? uid,
      fullName: (map['fullName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: UserRole.fromValue(map['role'] as String?),
      department: (map['department'] as String?) ?? '',
      location: (map['location'] as String?) ?? '',
      createdAt: dateFromMap(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role.value,
      'department': department,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    UserRole? role,
    String? department,
    String? location,
  }) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      location: location ?? this.location,
      createdAt: createdAt,
    );
  }
}
