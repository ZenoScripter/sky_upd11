/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart'
    show FieldValue, FirebaseFirestore;
import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException, GoogleAuthProvider, User;
import 'package:firebase_core/firebase_core.dart'
    show Firebase, FirebaseException;
import 'package:material_ui/material_ui.dart';
import 'package:musify/main.dart' show logger;
import 'package:musify/services/profile_manager.dart';
import 'package:musify/utilities/platform_utils.dart';
import 'package:musify/utilities/skyfy_text.dart';

/// Message meant to be shown to the user as it is.
class AccountException implements Exception {
  AccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Public profile stored in Firestore (`profiles/{uid}`). The e-mail address is
/// never stored here, so other users can not see it.
class AccountProfile {
  const AccountProfile({
    required this.username,
    required this.displayName,
    required this.bio,
    this.photo,
  });

  final String username;
  final String displayName;
  final String bio;

  /// `data:` URL of a small avatar.
  final String? photo;

  static AccountProfile? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final username = map['username']?.toString() ?? '';
    if (username.isEmpty) return null;
    return AccountProfile(
      username: username,
      displayName: map['displayName']?.toString() ?? username,
      bio: map['bio']?.toString() ?? '',
      photo: map['photo']?.toString(),
    );
  }
}

/// Firebase Authentication + Firestore profile. Everything is optional: when
/// Firebase is not configured (no google-services.json) or on desktop, the
/// service stays unavailable and the rest of the app works as before.
class AccountService {
  AccountService._();

  static final AccountService instance = AccountService._();

  static final RegExp usernameRegExp = RegExp(r'^[a-z0-9_]{3,20}$');
  static const int maxPhotoLength = 700000;

  /// Firebase is configured and initialised.
  final ValueNotifier<bool> available = ValueNotifier<bool>(false);
  final ValueNotifier<bool> signedIn = ValueNotifier<bool>(false);
  final ValueNotifier<AccountProfile?> profile =
      ValueNotifier<AccountProfile?>(null);

  /// The first profile snapshot of the signed in user has arrived.
  final ValueNotifier<bool> profileReady = ValueNotifier<bool>(false);

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<dynamic>? _profileSubscription;

  String? get uid => available.value ? FirebaseAuth.instance.currentUser?.uid : null;

  /// Name Google/Firebase knows for the signed in user (to pre-fill forms).
  String get authDisplayName => available.value
      ? (FirebaseAuth.instance.currentUser?.displayName ?? '')
      : '';

  Future<void> init() async {
    if (!isMobilePlatform || available.value) return;
    try {
      await Firebase.initializeApp();
    } catch (e, stackTrace) {
      logger.log(
        'Firebase is not configured, accounts are disabled',
        error: e,
        stackTrace: stackTrace,
      );
      return;
    }
    available.value = true;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthChanged,
      onError: (Object e, StackTrace stackTrace) {
        logger.log('Auth listener error', error: e, stackTrace: stackTrace);
      },
    );
  }

  void _onAuthChanged(User? user) {
    signedIn.value = user != null;
    unawaited(_profileSubscription?.cancel());
    _profileSubscription = null;
    profileReady.value = false;

    if (user == null) {
      profile.value = null;
      return;
    }

    _profileSubscription = FirebaseFirestore.instance
        .collection('profiles')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            final data = snapshot.exists ? snapshot.data() : null;
            final parsed = AccountProfile.fromMap(data);
            profile.value = parsed;
            profileReady.value = true;
            if (parsed != null) _mirrorToLocal(parsed);
          },
          onError: (Object e, StackTrace stackTrace) {
            logger.log(
              'Profile listener error',
              error: e,
              stackTrace: stackTrace,
            );
            profileReady.value = true;
          },
        );
  }

  /// Keeps the local name/photo (used all over the app) equal to the account,
  /// so a second device shows the same profile after signing in.
  void _mirrorToLocal(AccountProfile cloud) {
    final name = cloud.displayName.isEmpty
        ? profileName.value
        : cloud.displayName;
    final image = cloud.photo ?? profileImage.value;
    if (name != profileName.value || image != profileImage.value) {
      unawaited(saveProfile(name: name, image: image));
    }
  }

  // ---------------------------------------------------------------- sign in

  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    _ensureAvailable();
    final name = _validUsername(username);
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
    final user = credential.user;
    if (user == null) {
      throw AccountException(tt('Gagal membuat akun', 'Could not create the account'));
    }

    try {
      await _claimUsername(user.uid, name, displayName.trim());
      await user.updateDisplayName(displayName.trim());
    } catch (_) {
      // The username was taken (or the write failed): do not leave an account
      // without a profile behind.
      await user.delete().catchError((Object _) {});
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _ensureAvailable();
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    _ensureAvailable();
    await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());
  }

  Future<void> sendPasswordReset(String email) async {
    _ensureAvailable();
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    if (!available.value) return;
    await FirebaseAuth.instance.signOut();
  }

  // ---------------------------------------------------------------- profile

  /// Whether the signed in user already has a profile (a username).
  Future<bool> hasProfile(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .get();
    return snapshot.exists;
  }

  /// First time profile of a user who signed in with Google.
  Future<void> completeProfile({
    required String username,
    required String displayName,
  }) async {
    _ensureAvailable();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw AccountException(tt('Kamu belum masuk', 'You are not signed in'));
    }
    final name = _validUsername(username);
    await _claimUsername(user.uid, name, displayName.trim());
    await user.updateDisplayName(displayName.trim());
  }

  Future<void> updateProfile({
    required String displayName,
    required String bio,
    String? photo,
    bool removePhoto = false,
  }) async {
    _ensureAvailable();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw AccountException(tt('Kamu belum masuk', 'You are not signed in'));
    }
    if (photo != null && photo.length > maxPhotoLength) {
      throw AccountException(tt('Foto terlalu besar', 'The photo is too large'));
    }

    await FirebaseFirestore.instance.collection('profiles').doc(user.uid).update({
      'displayName': displayName.trim(),
      'bio': bio.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (photo != null)
        'photo': photo
      else if (removePhoto)
        'photo': FieldValue.delete(),
    });
    await user.updateDisplayName(displayName.trim());
  }

  // ---------------------------------------------------------------- helpers

  void _ensureAvailable() {
    if (!available.value) {
      throw AccountException(
        tt(
          'Akun belum dikonfigurasi di versi ini',
          'Accounts are not configured in this build',
        ),
      );
    }
  }

  String _validUsername(String username) {
    final name = username.trim().toLowerCase();
    if (!usernameRegExp.hasMatch(name)) {
      throw AccountException(
        tt(
          'Username 3-20 karakter: huruf kecil, angka, atau garis bawah',
          'Username must be 3-20 characters: lowercase letters, digits or underscore',
        ),
      );
    }
    return name;
  }

  /// Reserves the username and creates the profile in one transaction, so two
  /// users can never end up with the same username.
  Future<void> _claimUsername(
    String uid,
    String username,
    String displayName,
  ) async {
    final db = FirebaseFirestore.instance;
    final nameRef = db.collection('usernames').doc(username);
    final profileRef = db.collection('profiles').doc(uid);
    final privateRef = db.collection('users').doc(uid);
    final shownName = displayName.isEmpty ? username : displayName;

    await db.runTransaction((transaction) async {
      final taken = await transaction.get(nameRef);
      if (taken.exists) {
        throw AccountException(
          tt('Username sudah dipakai', 'This username is already taken'),
        );
      }
      transaction
        ..set(nameRef, {'uid': uid})
        ..set(profileRef, {
          'username': username,
          'displayName': shownName,
          'bio': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        // Private, owner-only data (never readable by other users).
        ..set(privateRef, {
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'privacy': {'showActivity': false, 'showOnline': false},
        });
    });
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _profileSubscription?.cancel();
  }
}

/// Turns any error from the account flow into a short message for the user.
String describeAccountError(Object error) {
  if (error is AccountException) return error.message;
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return tt('Format email tidak valid', 'The email address is not valid');
      case 'user-disabled':
        return tt('Akun ini dinonaktifkan', 'This account has been disabled');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return tt('Email atau password salah', 'Wrong email or password');
      case 'email-already-in-use':
        return tt('Email sudah terdaftar', 'This email is already registered');
      case 'weak-password':
        return tt(
          'Password terlalu lemah (minimal 6 karakter)',
          'The password is too weak (at least 6 characters)',
        );
      case 'network-request-failed':
        return tt(
          'Tidak ada koneksi internet',
          'No internet connection',
        );
      case 'too-many-requests':
        return tt(
          'Terlalu banyak percobaan, coba lagi nanti',
          'Too many attempts, try again later',
        );
      case 'account-exists-with-different-credential':
        return tt(
          'Email ini sudah dipakai dengan cara masuk lain',
          'This email is already used with another sign-in method',
        );
      case 'canceled':
      case 'web-context-canceled':
        return tt('Login dibatalkan', 'Sign-in was cancelled');
      default:
        return tt('Gagal masuk (${error.code})', 'Sign-in failed (${error.code})');
    }
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return tt(
      'Akses ditolak oleh aturan keamanan',
      'Access was denied by the security rules',
    );
  }
  return tt('Terjadi kesalahan, coba lagi', 'Something went wrong, try again');
}

/// Shrinks a picked photo to a small avatar so it fits in the profile
/// document. Returns null when the image can not be decoded.
Future<String?> shrinkAvatarDataUrl(String dataUrl) async {
  try {
    final data = dataUrl.contains(',') ? dataUrl.split(',').last : dataUrl;
    final codec = await ui.instantiateImageCodec(
      base64Decode(data),
      targetWidth: 256,
    );
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) return null;
    return 'data:image/png;base64,${base64Encode(png.buffer.asUint8List())}';
  } catch (_) {
    return null;
  }
}
