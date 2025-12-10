import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users';

  /// Save user profile to Firestore
  static Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).set(user.toMap());
    } catch (e) {
      log("Error saving user to Firestore: $e", name: 'FirestoreService');
      rethrow;
    }
  }

  /// Get user profile from Firestore
  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      log("Error getting user from Firestore: $e", name: 'FirestoreService');
      return null;
    }
  }

  /// Check if user profile exists
  static Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      log("Error checking user existence: $e", name: 'FirestoreService');
      return false;
    }
  }
}
