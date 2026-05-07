import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/logger.dart';
import 'package:logger/logger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart' as UserEntity;
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/use_cases/get_current_user_use_case.dart';
import '../../domain/use_cases/sign_in_use_case.dart';
import '../../domain/use_cases/sign_out_use_case.dart';
import '../../domain/use_cases/sign_up_use_case.dart';

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl();
});

final userNotifierProvider =
    StateNotifierProvider<UserNotifier, UserState>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return UserNotifier(
    authRepository,
    GetCurrentUser(authRepository),
    SignIn(authRepository),
    SignOut(authRepository),
    SignUp(authRepository),
  );
});

class UserState {
  final UserEntity.User? user;
  final UserProfile? profile;
  final bool isLoading;
  final bool isProfileLoading;
  final String? error;

  UserState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.isProfileLoading = false,
    this.error,
  });

  UserState copyWith({
    UserEntity.User? user,
    UserProfile? profile,
    bool? isLoading,
    bool? isProfileLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isProfileLoading: isProfileLoading ?? this.isProfileLoading,
      error: error ?? this.error,
    );
  }
}

class UserProfile {
  final String id;
  final String displayName;

  const UserProfile({
    required this.id,
    required this.displayName,
  });
}

class UserNotifier extends StateNotifier<UserState> {
  final AuthRepositoryImpl authRepository;
  final GetCurrentUser getCurrentUser;
  final SignIn signIn;
  final SignOut signOut;
  final SignUp signUp;
  final Logger _logger = getLogger('UserNotifier');

  UserNotifier(
    this.authRepository,
    this.getCurrentUser,
    this.signIn,
    this.signOut,
    this.signUp,
  )
      : super(UserState()) {
    loadUserData();
  }

  Future<void> loadUserData() async {
    _logger.i('Starting loadUserData');
    state = state.copyWith(isLoading: true);
    try {
      final user = await getCurrentUser();
      if (user != null) {
        _logger.i('Successfully loaded user data: $user');
        state = state.copyWith(user: user, isLoading: false);
        await _loadOrCreateProfile(user);
      } else {
        _logger.w('User not authenticated');
        state = UserState(
          isLoading: false,
          error: 'User not authenticated',
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Error during loadUserData', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInUser(String email, String password) async {
    _logger.i('Starting signInUser for email: $email');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Versuche, den Benutzer anzumelden
      await signIn(email, password);
      _logger.i('Successfully signed in user with email: $email');

      // Lade die Benutzerdaten nach erfolgreichem Login
      await loadUserData();
    } on AuthException catch (e) {
      // Behandle spezifische Authentifizierungsfehler basierend auf Supabase-Fehlercodes
      _logger.e('AuthException during signInUser', e);

      // Aktualisiere den Zustand mit dem Fehler
      state = state.copyWith(isLoading: false, error: e.code);
      _logger.w('Error message set in state: ${e.code}');
      throw Exception(e.code); // Fehler weiterwerfen, falls benötigt
    } catch (e, stackTrace) {
      // Behandle allgemeine Fehler
      _logger.e('Unexpected error during signInUser', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
      throw Exception(e); // Fehler weiterwerfen, falls benötigt
    }
  }

  Future<void> signUpUser(
    String email,
    String password, {
    String? displayName,
  }) async {
    _logger.i('Starting signUpUser for email: $email');
    state = state.copyWith(isLoading: true);
    try {
      final cleanedDisplayName = displayName?.trim();
      final response = await signUp(
        email,
        password,
        data: cleanedDisplayName == null || cleanedDisplayName.isEmpty
            ? null
            : {'display_name': cleanedDisplayName},
      );
      _logger.i('Successfully signed up user with email: $email');

      final newUser = response.user;
      if (newUser != null) {
        final mappedUser = UserEntity.User(
          id: newUser.id,
          email: newUser.email ?? email,
        );
        state = state.copyWith(user: mappedUser);
        await _loadOrCreateProfile(
          mappedUser,
          preferredDisplayName: cleanedDisplayName,
        );
      }

      await loadUserData();
    } on AuthException catch (e) {
      _logger.e('AuthException during signUpUser', e);

      state = state.copyWith(isLoading: false, error: e.code);
      throw Exception(e.code);
    } catch (e, stackTrace) {
      _logger.e('Unexpected error during signUpUser', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
      throw Exception(
          'Ein unerwarteter Fehler ist aufgetreten: ${e.toString()}');
    }
  }

  String _generateNonce([int length = 32]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<void> signOutUser() async {
    _logger.i('Starting signOutUser');
    state = state.copyWith(isLoading: true);
    try {
      await signOut();
      _logger.i('Successfully signed out user');
      state = UserState();
    } catch (e, stackTrace) {
      _logger.e('Error during signOutUser', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteCurrentUserAccount() async {
    _logger.i('Starting deleteCurrentUserAccount');
    state = state.copyWith(isLoading: true, error: null);

    try {
      await authRepository.deleteCurrentUserAccount();
      state = UserState();
      _logger.i('Successfully deleted current user account');
    } catch (e, stackTrace) {
      _logger.e('Error during deleteCurrentUserAccount', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    _logger.i('Starting signInWithApple');
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Zufälligen Nonce erzeugen, SHA-256 hashen für Apple, Klartext an Supabase
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) throw Exception('Apple ID Token ist null');

      // ignore: deprecated_member_use
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      await loadUserData();
      final currentUser = state.user;
      if (currentUser != null) {
        final authUser = Supabase.instance.client.auth.currentUser;
        final metaName = authUser?.userMetadata?['display_name']?.toString();
        await _loadOrCreateProfile(
          currentUser,
          preferredDisplayName: metaName,
        );
      }
      _logger.i('Successfully signed in with Apple');
    } on SignInWithAppleAuthorizationException catch (e) {
      _logger.e('Apple Sign In abgebrochen oder fehlgeschlagen', e);
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } on AuthException catch (e) {
      _logger.e('Supabase AuthException during Apple sign in', e);
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Unexpected error during Apple sign in', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProfileName(String displayName) async {
    final user = state.user;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final sanitized = displayName.trim();
    if (sanitized.isEmpty) {
      throw Exception('Name darf nicht leer sein');
    }

    state = state.copyWith(isProfileLoading: true, error: null);

    try {
      await Supabase.instance.client.from('profiles').upsert(
        {
          'id': user.id,
          'display_name': sanitized,
        },
        onConflict: 'id',
      );

      state = state.copyWith(
        isProfileLoading: false,
        profile: UserProfile(id: user.id, displayName: sanitized),
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating profile name', e, stackTrace);
      state = state.copyWith(isProfileLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> _loadOrCreateProfile(
    UserEntity.User user, {
    String? preferredDisplayName,
  }) async {
    state = state.copyWith(isProfileLoading: true);

    try {
      final existing = await Supabase.instance.client
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();

      final existingDisplayName = existing?['display_name']?.toString().trim();
      if (existingDisplayName != null && existingDisplayName.isNotEmpty) {
        state = state.copyWith(
          isProfileLoading: false,
          profile: UserProfile(id: user.id, displayName: existingDisplayName),
        );
        return;
      }

      final fallbackName = preferredDisplayName?.trim().isNotEmpty == true
          ? preferredDisplayName!.trim()
          : _deriveDisplayNameFromEmail(user.email);

      await Supabase.instance.client.from('profiles').upsert(
        {
          'id': user.id,
          'display_name': fallbackName,
        },
        onConflict: 'id',
      );

      state = state.copyWith(
        isProfileLoading: false,
        profile: UserProfile(id: user.id, displayName: fallbackName),
      );
    } catch (e, stackTrace) {
      _logger.e('Error loading/creating profile', e, stackTrace);
      state = state.copyWith(isProfileLoading: false, error: e.toString());
    }
  }

  String _deriveDisplayNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'Nutzer';

    final normalized = localPart.replaceAll(RegExp(r'[._\-+]'), ' ').trim();
    if (normalized.isEmpty) return 'Nutzer';

    return normalized
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ')
        .trim();
  }
}
