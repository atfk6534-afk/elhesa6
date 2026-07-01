import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// خدمة المصادقة: تسجيل الدخول/الخروج، وإدارة حسابات الخدام من قبل المدير
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<AppUser> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    return fetchAppUser(uid);
  }

  Future<void> signOut() => _auth.signOut();

  /// جلب بيانات المستخدم (الدور: مدير أو خادم) من Firestore
  Future<AppUser> fetchAppUser(String uid) async {
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) {
      throw Exception('لا يوجد حساب مرتبط بهذا المستخدم. تواصل مع المدير.');
    }
    return AppUser.fromMap(uid, doc.data()!);
  }

  /// مراقبة بيانات المستخدم الحالي (للتحقق من الصلاحيات بشكل مستمر)
  Stream<AppUser?> watchAppUser(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromMap(uid, doc.data()!) : null);
  }

  /// إضافة خادم جديد بواسطة المدير فقط
  /// يستخدم تطبيق Firebase ثانوي مؤقت حتى لا يتم تسجيل خروج المدير الحالي
  Future<void> addServant({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'tempAuthApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final newUid = credential.user!.uid;

      await _firestore.collection(AppConstants.usersCollection).doc(newUid).set({
        'email': email.trim(),
        'name': name,
        'role': roleToString(role),
      });

      await tempAuth.signOut();
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  /// حذف خادم (يحذف فقط مستند الصلاحية، حذف حساب Auth يتطلب Cloud Function)
  Future<void> removeServant(String uid) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).delete();
  }

  Future<List<AppUser>> getAllServants() async {
    final snapshot = await _firestore.collection(AppConstants.usersCollection).get();
    return snapshot.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
  }
}
