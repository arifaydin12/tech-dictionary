import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/firebase_service.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseService _firebaseService = FirebaseService();

  /// Görsel seç ve yükle
  Future<String?> pickAndUploadImage(String wordId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await uploadImage(File(image.path), wordId);
    } catch (e) {
      print('Görsel seçme hatası: $e');
      return null;
    }
  }

  /// Kamera ile görsel çek ve yükle
  Future<String?> takeAndUploadImage(String wordId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await uploadImage(File(image.path), wordId);
    } catch (e) {
      print('Görsel çekme hatası: $e');
      return null;
    }
  }

  /// Görseli Firebase Storage'a yükle
  Future<String> uploadImage(File imageFile, String wordId) async {
    if (!_firebaseService.isLoggedIn) {
      throw Exception('Giriş yapılmadı');
    }

    try {
      final ref = _storage
          .ref()
          .child('word_images')
          .child('${_firebaseService.userId}')
          .child('$wordId.jpg');

      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      
      return url;
    } catch (e) {
      print('Görsel yükleme hatası: $e');
      rethrow;
    }
  }

  /// Görseli sil
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Görsel silme hatası: $e');
    }
  }
}

