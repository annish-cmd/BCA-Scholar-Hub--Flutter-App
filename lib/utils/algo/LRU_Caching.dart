import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// LRU (Least Recently Used) Cache Manager for PDF Files
/// 
/// This class provides persistent file caching with automatic cleanup
/// when storage limits are exceeded. Files remain available offline
/// even after app restarts.
class LRUCaching {
  // Configuration constants
  static const int maxCachedFiles = 10; // Maximum number of cached PDFs
  static const int maxCacheSizeInBytes = 500 * 1024 * 1024; // 500MB limit
  static const String cacheFolderName = 'pdf_cache'; // Folder name in documents directory
  
  final Dio _dio = Dio();

  /// Returns the cache directory path
  /// Creates the directory if it doesn't exist
  Future<Directory> _getCacheDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory cacheDir = Directory('${appDocDir.path}/$cacheFolderName');
    
    // Create cache directory if it doesn't exist
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }

  /// Gets the local file path for a PDF
  /// Downloads the file if not cached, otherwise returns existing cached file
  /// 
  /// Parameters:
  ///   - url: The download URL of the PDF file
  ///   - filename: The desired filename (should include .pdf extension)
  /// 
  /// Returns: Local file path that can be used offline
  Future<String> getFile(String url, String filename) async {
    try {
      final Directory cacheDir = await _getCacheDirectory();
      final String localPath = '${cacheDir.path}/$filename';
      final File localFile = File(localPath);

      // Check if file already exists in cache
      if (await localFile.exists()) {
        print('📁 File found in cache: $filename');
        
        // Update the file's last access time to mark it as recently used
        await _updateAccessTime(localFile);
        
        return localPath;
      }

      // File not in cache - need to download
      print('⬇️ Downloading PDF: $filename');
      
      // Download the file from URL
      await _dio.download(
        url,
        localPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );

      print('✅ Download complete: $filename');

      // After download, check if we need to clean up old files
      await _cleanOldFiles();

      return localPath;
    } catch (e) {
      print('❌ Error in getFile: $e');
      rethrow;
    }
  }

  /// Updates the file's last modified time to current time
  /// This marks the file as "recently used" in LRU algorithm
  Future<void> _updateAccessTime(File file) async {
    try {
      final DateTime now = DateTime.now();
      await file.setLastModified(now);
      print('🕒 Updated access time for: ${file.path}');
    } catch (e) {
      print('⚠️ Could not update access time: $e');
    }
  }

  /// Cleans up old cached files when limits are exceeded
  /// Uses LRU (Least Recently Used) algorithm:
  /// - Deletes oldest files first if count exceeds maxCachedFiles
  /// - Deletes oldest files first if total size exceeds maxCacheSizeInBytes
  Future<void> _cleanOldFiles() async {
    try {
      final Directory cacheDir = await _getCacheDirectory();
      
      // Get all PDF files in cache directory
      final List<FileSystemEntity> entities = cacheDir.listSync();
      final List<File> cachedFiles = entities
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.pdf'))
          .toList();

      if (cachedFiles.isEmpty) {
        print('🗂️ Cache is empty, nothing to clean');
        return;
      }

      // Sort files by last modified time (oldest first)
      // This is the core of LRU algorithm - oldest = least recently used
      cachedFiles.sort((a, b) {
        final DateTime timeA = a.lastModifiedSync();
        final DateTime timeB = b.lastModifiedSync();
        return timeA.compareTo(timeB); // Ascending order (oldest first)
      });

      print('📊 Cache status: ${cachedFiles.length} files');

      // Calculate total cache size
      int totalSize = 0;
      for (final file in cachedFiles) {
        totalSize += await file.length();
      }
      
      final double totalSizeMB = totalSize / (1024 * 1024);
      print('💾 Total cache size: ${totalSizeMB.toStringAsFixed(2)} MB');

      // Determine how many files need to be deleted
      int filesToDelete = 0;

      // Check if we exceeded the file count limit
      if (cachedFiles.length > maxCachedFiles) {
        filesToDelete = cachedFiles.length - maxCachedFiles;
        print('⚠️ Cache has ${cachedFiles.length} files, limit is $maxCachedFiles');
      }

      // Check if we exceeded the size limit
      int currentSize = totalSize;
      if (currentSize > maxCacheSizeInBytes) {
        print('⚠️ Cache size ${totalSizeMB.toStringAsFixed(2)}MB exceeds limit ${(maxCacheSizeInBytes / (1024 * 1024)).toStringAsFixed(2)}MB');
        
        // Keep deleting oldest files until we're under the size limit
        for (int i = 0; i < cachedFiles.length; i++) {
          if (currentSize <= maxCacheSizeInBytes && cachedFiles.length - i <= maxCachedFiles) {
            break; // We're now within limits
          }
          
          final fileSize = await cachedFiles[i].length();
          currentSize -= fileSize;
          filesToDelete = i + 1;
        }
      }

      // Delete the oldest files (LRU deletion)
      if (filesToDelete > 0) {
        print('🗑️ Deleting $filesToDelete oldest file(s)...');
        
        for (int i = 0; i < filesToDelete; i++) {
          final File fileToDelete = cachedFiles[i];
          final String fileName = fileToDelete.path.split('/').last;
          
          await fileToDelete.delete();
          print('  ❌ Deleted: $fileName');
        }
        
        print('✅ Cache cleanup complete');
      } else {
        print('✅ Cache is within limits, no cleanup needed');
      }
    } catch (e) {
      print('❌ Error during cache cleanup: $e');
    }
  }

  /// Manually clears all cached files
  /// Useful for implementing a "Clear Cache" button in settings
  Future<void> clearAllCache() async {
    try {
      final Directory cacheDir = await _getCacheDirectory();
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(); // Recreate empty directory
        print('🗑️ All cache cleared successfully');
      }
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Gets current cache statistics
  /// Returns a map with cache info (file count, total size)
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final Directory cacheDir = await _getCacheDirectory();
      final List<FileSystemEntity> entities = cacheDir.listSync();
      final List<File> cachedFiles = entities
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.pdf'))
          .toList();

      int totalSize = 0;
      for (final file in cachedFiles) {
        totalSize += await file.length();
      }

      return {
        'fileCount': cachedFiles.length,
        'totalSizeBytes': totalSize,
        'totalSizeMB': totalSize / (1024 * 1024),
        'maxFiles': maxCachedFiles,
        'maxSizeMB': maxCacheSizeInBytes / (1024 * 1024),
      };
    } catch (e) {
      print('❌ Error getting cache stats: $e');
      return {
        'fileCount': 0,
        'totalSizeBytes': 0,
        'totalSizeMB': 0.0,
        'maxFiles': maxCachedFiles,
        'maxSizeMB': maxCacheSizeInBytes / (1024 * 1024),
      };
    }
  }

  /// Checks if a file exists in cache
  /// Useful to show "Available Offline" badge in UI
  Future<bool> isFileCached(String filename) async {
    try {
      final Directory cacheDir = await _getCacheDirectory();
      final File file = File('${cacheDir.path}/$filename');
      return await file.exists();
    } catch (e) {
      print('❌ Error checking cache: $e');
      return false;
    }
  }

  /// Deletes a specific file from cache
  /// Useful for implementing "Remove from offline" feature
  Future<bool> deleteFile(String filename) async {
    try {
      final Directory cacheDir = await _getCacheDirectory();
      final File file = File('${cacheDir.path}/$filename');
      
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Deleted from cache: $filename');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error deleting file: $e');
      return false;
    }
  }
}

