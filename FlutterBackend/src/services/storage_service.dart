import '../core/supabase_client.dart';

/// Service for handling file storage operations
class StorageService {
  final SupabaseClient _supabaseClient;
  
  /// Constructor that takes a Supabase client
  StorageService(this._supabaseClient);
  
  /// Upload a file to storage
  Future<String?> uploadFile(String bucketName, String path, List<int> fileBytes, {
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final response = await _supabaseClient.db.storage
          .from(bucketName)
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
      
      if (response.error != null) {
        print('Error uploading file: ${response.error!.message}');
        return null;
      }
      
      // If metadata is provided, update the file metadata
      if (metadata != null && metadata.isNotEmpty) {
        await _supabaseClient.db.storage
            .from(bucketName)
            .updateMetadata(path, metadata);
      }
      
      // Return the public URL for the file
      return _supabaseClient.db.storage
          .from(bucketName)
          .getPublicUrl(path);
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
  
  /// Download a file from storage
  Future<List<int>?> downloadFile(String bucketName, String path) async {
    try {
      final response = await _supabaseClient.db.storage
          .from(bucketName)
          .download(path);
      
      return response;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }
  
  /// Get a public URL for a file
  Future<String?> getPublicUrl(String bucketName, String path) async {
    try {
      return _supabaseClient.db.storage
          .from(bucketName)
          .getPublicUrl(path);
    } catch (e) {
      print('Error getting public URL: $e');
      return null;
    }
  }
  
  /// Delete a file from storage
  Future<bool> deleteFile(String bucketName, String path) async {
    try {
      await _supabaseClient.db.storage
          .from(bucketName)
          .remove([path]);
      
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
  
  /// List files in a bucket with an optional prefix
  Future<List<FileObject>?> listFiles(String bucketName, {String? prefix}) async {
    try {
      final response = await _supabaseClient.db.storage
          .from(bucketName)
          .list(path: prefix);
      
      return response;
    } catch (e) {
      print('Error listing files: $e');
      return null;
    }
  }
  
  /// Create a signed URL for temporary access to a file
  Future<String?> createSignedUrl(String bucketName, String path, {int expiresIn = 3600}) async {
    try {
      final response = await _supabaseClient.db.storage
          .from(bucketName)
          .createSignedUrl(path, expiresIn);
      
      return response;
    } catch (e) {
      print('Error creating signed URL: $e');
      return null;
    }
  }
}

/// File object returned from the storage API
class FileObject {
  final String name;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastAccessedAt;
  final Map<String, dynamic>? metadata;
  
  FileObject({
    required this.name,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.lastAccessedAt,
    this.metadata,
  });
  
  factory FileObject.fromJson(Map<String, dynamic> json) {
    return FileObject(
      name: json['name'],
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastAccessedAt: json['last_accessed_at'] != null
          ? json['last_accessed_at']
          : null,
      metadata: json['metadata'],
    );
  }
}