import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'
    show GoogleSignIn, GoogleSignInAccount, GoogleSignInClientAuthorization;

class AutProvider extends ChangeNotifier {
  static final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  static bool isinitialized = false;

  static Future<void> _initSignin() async {
    if (!isinitialized) {
      await googleSignIn.initialize(
        serverClientId:
            "508373593061-botbk4jkrohufi7r9nhd2k1fpa37vsu7.apps.googleusercontent.com",
      );
    }
    isinitialized = true;
  }

  // Sign in with Google
  static Future<UserCredential> signinWithGoogle() async {
    _initSignin();

    final GoogleSignInAccount account = await googleSignIn.authenticate();

    final idToken = account.authentication.idToken;
    final authClient = account.authorizationClient;

    GoogleSignInClientAuthorization? auth = await authClient
        .authorizationForScopes(['email', 'profile']);

    final aaccessToken = auth?.accessToken;

    if (aaccessToken == null || idToken == null) {
      throw FirebaseAuthException(
        code: 'Google SignIn Failed',
        message: 'Failed to retrieve Google auth tokens.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: auth?.accessToken,
      idToken: idToken,
    );

    // Sign in to Firebase with the Google credential
    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    // After successful sign-in, create a user document in Firestore if it doesn't exist
    if (userCredential.user != null) {
      final User user = userCredential.user!;
      final DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final doc = await userDocRef.get();
      if (!doc.exists) {
        // New user: create their profile in Firestore.
        await userDocRef.set({
          'fullName': user.displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'createdAt': Timestamp.now(),
          'role': 'user', // Assign default user role
        });
      } else {
        // Existing user: update their profile with the latest from Google.
        // This keeps the profile fresh if they change their Google name/photo.
        await userDocRef.update({
          'fullName': user.displayName,
          'email': user.email, // Email can also be updated if it changes
          'photoUrl': user.photoURL,
        });
      }
    }

    return userCredential;
  }

  // Sign out from Google
  static Future<void> signOutFromGoogle() async {
    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
