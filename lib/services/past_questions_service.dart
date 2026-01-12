import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/past_question_model.dart';

class PastQuestionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  static const String _collection = 'past_questions';

  // Upload past question
  Future<String?> uploadPastQuestion({
    String? courseCode, // Made optional
    required String courseName,
    required String programName,
    required String facultyName,
    required int level,
    required int semester,
    required int year,
    required Uint8List fileBytes,
    required String fileName,
    required String fileType,
    required String uploadedBy,
    required String uploaderName,
  }) async {
    try {
      // Create unique file path
      final codeForPath = courseCode?.isNotEmpty == true ? courseCode : 'NO_CODE';
      final storagePath = 'past_questions/$facultyName/$programName/$codeForPath/${year}_$fileName';
      final ref = _storage.ref().child(storagePath);
      
      // Upload file
      await ref.putData(fileBytes, SettableMetadata(contentType: _getContentType(fileType)));
      final fileUrl = await ref.getDownloadURL();
      
      // Save to Firestore
      final docRef = await _firestore.collection(_collection).add({
        'courseCode': courseCode ?? '', // Store empty string if not provided
        'courseName': courseName,
        'programName': programName,
        'facultyName': facultyName,
        'level': level,
        'semester': semester,
        'year': year,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileType': fileType,
        'uploadedBy': uploadedBy,
        'uploaderName': uploaderName,
        'uploadedAt': Timestamp.now(),
        'downloadCount': 0,
      });
      
      return docRef.id;
    } catch (e) {
      print('Error uploading past question: $e');
      return null;
    }
  }

  // Get past questions for a course
  Stream<List<PastQuestionModel>> getPastQuestions({
    required String courseCode,
    required int level,
    required int semester,
    int? year,
  }) {
    Query query = _firestore.collection(_collection)
        .where('courseCode', isEqualTo: courseCode)
        .where('level', isEqualTo: level)
        .where('semester', isEqualTo: semester);
    
    if (year != null) {
      query = query.where('year', isEqualTo: year);
    }
    
    return query.orderBy('year', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PastQuestionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get all past questions for a program/level/semester
  Stream<List<PastQuestionModel>> getPastQuestionsByProgram({
    required String programName,
    required int level,
    required int semester,
  }) {
    return _firestore.collection(_collection)
        .where('programName', isEqualTo: programName)
        .where('level', isEqualTo: level)
        .where('semester', isEqualTo: semester)
        .orderBy('year', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PastQuestionModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Delete past question
  Future<bool> deletePastQuestion(String questionId, String fileUrl) async {
    try {
      // Delete from Storage
      await _storage.refFromURL(fileUrl).delete();
      // Delete from Firestore
      await _firestore.collection(_collection).doc(questionId).delete();
      return true;
    } catch (e) {
      print('Error deleting past question: $e');
      return false;
    }
  }

  // Update download count
  Future<void> incrementDownloadCount(String questionId) async {
    await _firestore.collection(_collection).doc(questionId).update({
      'downloadCount': FieldValue.increment(1),
    });
  }

  // Get user's uploaded questions
  Stream<List<PastQuestionModel>> getUserUploadedQuestions(String userId) {
    return _firestore.collection(_collection)
        .where('uploadedBy', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PastQuestionModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  String _getContentType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
