import 'package:cloud_firestore/cloud_firestore.dart';

/// Friendly copy for Firestore, Storage and upload failures.
String dataErrorMessage(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'You do not have permission to do that.',
      'unauthenticated' => 'Please sign in again to continue.',
      'unavailable' || 'network-request-failed' =>
        'No internet connection. Check your network and try again.',
      'not-found' => 'That report no longer exists.',
      'cancelled' => 'The action was cancelled.',
      'deadline-exceeded' => 'The request took too long. Please try again.',
      'unauthorized' => 'You do not have permission to upload this file.',
      'retry-limit-exceeded' => 'The upload failed. Please try again.',
      'object-not-found' => 'That file no longer exists.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  if (error is StateError) return error.message.toString();

  return 'Something went wrong. Please try again.';
}
