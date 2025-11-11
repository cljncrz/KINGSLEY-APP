import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();
  final _auth = FirebaseAuth.instance;

  final RxBool _isFirstTime = true.obs;
  final Rx<User?> _firebaseUser = Rx<User?>(null);

  bool get isFirstTime => _isFirstTime.value;
  bool get isLoggedIn => _firebaseUser.value != null;
  User? get user => _firebaseUser.value;

  @override
  void onInit() {
    super.onInit();
    _loadInitialState();
    _firebaseUser.bindStream(_auth.authStateChanges());
  }

  void _loadInitialState() {
    _isFirstTime.value = _storage.read('isFirstTime') ?? true;
  }

  void setFirstTimeDone() {
    _isFirstTime.value = false;
    _storage.write('isFirstTime', false);
  }
}
