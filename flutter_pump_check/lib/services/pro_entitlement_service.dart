import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProEntitlementService {
  const ProEntitlementService._();

  static Stream<bool> watchIsPro() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream<bool>.value(false);

      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) => isProFromData(snapshot.data() ?? const {}));
    });
  }

  static bool isProFromData(Map<String, dynamic> data) {
    final explicitPro = data['isPro'] == true || data['pro'] == true;
    final tier = (data['tier'] as String?)?.toLowerCase().trim();
    final plan = (data['plan'] as String?)?.toLowerCase().trim();
    final subscriptionStatus = (data['subscriptionStatus'] as String?)
        ?.toLowerCase()
        .trim();
    final entitlement = (data['entitlement'] as String?)?.toLowerCase().trim();

    return explicitPro ||
        tier == 'pro' ||
        plan == 'pro' ||
        entitlement == 'pro' ||
        subscriptionStatus == 'active' ||
        subscriptionStatus == 'trialing';
  }
}
