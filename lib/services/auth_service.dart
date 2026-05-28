import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> forgotPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential?> signInWithGoogle() async {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  final GoogleSignInAccount? googleUser =
      await googleSignIn.signIn();

  if (googleUser == null) {
    return null;
  }

  final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  return await _auth.signInWithCredential(credential);
}

  Future<void> logout() => _auth.signOut();
}
