import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/logger.dart';
import 'package:logger/logger.dart';
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
    GetCurrentUser(authRepository),
    SignIn(authRepository),
    SignOut(authRepository),
    SignUp(authRepository),
  );
});

class UserState {
  final UserEntity.User? user;
  final bool isLoading;
  final String? error;

  UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    UserEntity.User? user,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final GetCurrentUser getCurrentUser;
  final SignIn signIn;
  final SignOut signOut;
  final SignUp signUp;
  final Logger _logger = getLogger('UserNotifier');

  UserNotifier(this.getCurrentUser, this.signIn, this.signOut, this.signUp)
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
      } else {
        _logger.w('User not authenticated');
        state =
            state.copyWith(isLoading: false, error: 'User not authenticated');
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

  Future<void> signUpUser(String email, String password) async {
    _logger.i('Starting signUpUser for email: $email');
    state = state.copyWith(isLoading: true);
    try {
      await signUp(email, password);
      _logger.i('Successfully signed up user with email: $email');
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
}
