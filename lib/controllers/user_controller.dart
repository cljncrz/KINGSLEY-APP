import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class UserController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable for Firebase Auth User object
  Rx<User?> firebaseUser = Rx<User?>(null);
  // Observable for Firestore user document data
  Rx<Map<String, dynamic>?> firestoreUserData = Rx<Map<String, dynamic>?>(null);
  // Observable for loading state
  RxBool isLoading = false.obs;
  // Stream subscription to manage the auth state listener
  StreamSubscription<User?>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes and manage the subscription
    _authSubscription = _auth.authStateChanges().listen(
      _setInitialFirestoreUserData,
    );
  }

  @override
  void onClose() {
    // Cancel the subscription when the controller is removed from memory
    // to prevent memory leaks and errors.
    _authSubscription?.cancel();
    super.onClose();
  }

  // Callback to fetch Firestore data when the Firebase user changes
  void _setInitialFirestoreUserData(User? user) {
    firebaseUser.value = user; // Manually update the reactive user
    if (user != null) {
      fetchFirestoreUserData(user.uid);
    } else {
      isLoading.value = false; // Stop loading on logout
      firestoreUserData.value = null; // Clear data if user logs out
    }
  }

  // Fetches user data from Firestore
  Future<void> fetchFirestoreUserData(String uid) async {
    try {
      isLoading.value = true;
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        firestoreUserData.value = doc.data();
      } else {
        firestoreUserData.value =
            null; // Handle case where user doc doesn't exist
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Manually triggers a refresh of both Firebase Auth and Firestore user data.
  Future<void> refreshUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Refreshes the firebaseUser object
      await fetchFirestoreUserData(user.uid); // Refetches Firestore data
    }
  }
}
