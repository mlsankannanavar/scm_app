import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:intl/intl.dart';
import '../models/local_batch_data.dart';

/// Local OCR service using Google ML Kit for text extraction and batch matching
class LocalOcrService {
  static final LocalOcrService _instance = LocalOcrService._internal();
  factory LocalOcrService() => _instance;
  LocalOcrService._internal();

  late final TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  /// Initialize the OCR service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _isInitialized = true;
    print('🔍 LOCAL_OCR: Initialized Google ML Kit text recognizer');
  }

  /// Extract text from image using Google ML Kit
  Future<String> extractTextFromImage(File imageFile) async {
    if (!_isInitialized) await initialize();
    
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      print('🔍 LOCAL_OCR: Extracted text: ${recognizedText.text.substring(0, recognizedText.text.length > 200 ? 200 : recognizedText.text.length)}...');
      return recognizedText.text;
    } catch (e) {
      print('❌ LOCAL_OCR: Error extracting text: $e');
      return '';
    }
  }

  /// Extract text from image bytes
  Future<String> extractTextFromBytes(Uint8List imageBytes) async {
    if (!_isInitialized) await initialize();
    
    try {
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: const InputImageMetadata(
          size: Size(640, 480), // Default size
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 640,
        ),
      );
      
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('❌ LOCAL_OCR: Error extracting text from bytes: $e');
      return '';
    }
  }

  /// Find batch number in extracted text using fuzzy matching
  /// Ports the logic from Python backend find_batch_in_text()
  Future<LocalMatchResult> findBatchInText(
    String extractedText,
    Map<String, LocalBatchData> availableBatches, {
    double threshold = 75.0,
  }) async {
    print('🔍 LOCAL_OCR: Searching for batch in text with ${availableBatches.length} available batches');
    
    if (extractedText.isEmpty || availableBatches.isEmpty) {
      return LocalMatchResult();
    }

    // Clean and prepare text for matching
    final cleanText = _cleanText(extractedText);
    final List<String> candidateBatches = [];
    double bestSimilarity = 0.0;
    String? bestMatch;
    LocalBatchData? bestBatchData;

    // Step 1: Check for exact matches first
    for (final entry in availableBatches.entries) {
      final batchNumber = entry.key;
      final batchData = entry.value;
      
      if (cleanText.contains(batchNumber)) {
        print('✅ LOCAL_OCR: Found exact match: $batchNumber');
        return LocalMatchResult(
          matchedBatch: batchNumber,
          confidence: 100.0,
          expiryDate: batchData.expiryDate,
          itemName: batchData.itemName,
          isExactMatch: true,
        );
      }
    }

    // Step 2: Fuzzy matching with similarity threshold
    for (final entry in availableBatches.entries) {
      final batchNumber = entry.key;
      final batchData = entry.value;
      
      // Calculate similarity using string similarity
      final similarity = _calculateSimilarityInText(batchNumber, cleanText);
      
      if (similarity >= threshold) {
        candidateBatches.add(batchNumber);
        
        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestMatch = batchNumber;
          bestBatchData = batchData;
        }
        
        print('🎯 LOCAL_OCR: Found candidate: $batchNumber (similarity: ${similarity.toStringAsFixed(1)}%)');
      }
    }

    // Step 3: Validate with expiry date if available
    if (bestMatch != null && bestBatchData != null) {
      final isValidated = await _validateWithExpiryDate(cleanText, bestBatchData.expiryDate);
      
      if (isValidated) {
        print('✅ LOCAL_OCR: Best match validated with expiry: $bestMatch (${bestSimilarity.toStringAsFixed(1)}%)');
        return LocalMatchResult(
          matchedBatch: bestMatch,
          confidence: bestSimilarity,
          expiryDate: bestBatchData.expiryDate,
          itemName: bestBatchData.itemName,
          isExactMatch: false,
          candidateBatches: candidateBatches,
        );
      }
    }

    print('❌ LOCAL_OCR: No valid batch found. Candidates: ${candidateBatches.length}');
    return LocalMatchResult(candidateBatches: candidateBatches);
  }

  /// Clean text for better matching (port of Python logic)
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s/.-]'), ' ')  // Remove special chars except common ones
        .replaceAll(RegExp(r'\s+'), ' ')          // Normalize whitespace
        .toUpperCase()                            // Uppercase for consistency
        .trim();
  }

  /// Calculate similarity between batch number and text
  /// Ports the calculate_similarity_in_text() logic from Python
  double _calculateSimilarityInText(String batchNumber, String text) {
    // Direct similarity check
    final directSimilarity = batchNumber.similarityTo(text) * 100;
    
    // Check if batch number appears as substring with surrounding context
    final words = text.split(' ');
    double maxWordSimilarity = 0.0;
    
    for (final word in words) {
      if (word.length >= 3) {  // Only check meaningful words
        final wordSimilarity = batchNumber.similarityTo(word) * 100;
        if (wordSimilarity > maxWordSimilarity) {
          maxWordSimilarity = wordSimilarity;
        }
      }
    }
    
    // Return the higher similarity
    return directSimilarity > maxWordSimilarity ? directSimilarity : maxWordSimilarity;
  }

  /// Validate batch match with expiry date
  /// Ports the expiry date validation logic from Python
  Future<bool> _validateWithExpiryDate(String extractedText, String? expiryDate) async {
    if (expiryDate == null || expiryDate.isEmpty) return true;  // No expiry to validate
    
    try {
      final expiryDateTime = DateTime.parse(expiryDate);
      final dateFormats = _generateDateFormats(expiryDateTime);
      
      // Check if any generated format appears in the extracted text
      for (final format in dateFormats) {
        if (extractedText.contains(format)) {
          print('✅ LOCAL_OCR: Expiry date validated: $format found in text');
          return true;
        }
      }
      
      print('⚠️ LOCAL_OCR: Expiry date not found in text, but allowing match');
      return true;  // Don't reject matches solely on expiry date
    } catch (e) {
      print('⚠️ LOCAL_OCR: Error validating expiry date: $e');
      return true;  // Don't reject on validation errors
    }
  }

  /// Generate multiple date formats for expiry validation
  /// Ports the generate_date_formats() logic from Python
  List<String> _generateDateFormats(DateTime date) {
    final formats = <String>[];
    
    // Common date formats
    formats.addAll([
      DateFormat('dd/MM/yyyy').format(date),
      DateFormat('MM/dd/yyyy').format(date),
      DateFormat('dd-MM-yyyy').format(date),
      DateFormat('MM-dd-yyyy').format(date),
      DateFormat('yyyy-MM-dd').format(date),
      DateFormat('dd.MM.yyyy').format(date),
      DateFormat('MM.dd.yyyy').format(date),
      DateFormat('dd/MM/yy').format(date),
      DateFormat('MM/dd/yy').format(date),
      DateFormat('dd-MM-yy').format(date),
      DateFormat('MM-dd-yy').format(date),
      DateFormat('yy-MM-dd').format(date),
      DateFormat('dd.MM.yy').format(date),
      DateFormat('MM.dd.yy').format(date),
      DateFormat('ddMMyyyy').format(date),
      DateFormat('MMddyyyy').format(date),
      DateFormat('yyyyMMdd').format(date),
      DateFormat('ddMMyy').format(date),
      DateFormat('MMddyy').format(date),
      DateFormat('yyMMdd').format(date),
      DateFormat('dd MMM yyyy').format(date),
      DateFormat('MMM dd yyyy').format(date),
      DateFormat('dd-MMM-yyyy').format(date),
      DateFormat('MMM-dd-yyyy').format(date),
      DateFormat('dd MMM yy').format(date),
      DateFormat('MMM dd yy').format(date),
      DateFormat('dd-MMM-yy').format(date),
      DateFormat('MMM-dd-yy').format(date),
      DateFormat('MMMM dd, yyyy').format(date),
      DateFormat('dd MMMM yyyy').format(date),
    ]);
    
    return formats;
  }

  /// Find best batch match from a list of LocalBatchData objects
  Future<BatchMatchResult> findBestBatchMatch(String extractedText, List<LocalBatchData> batches) async {
    if (batches.isEmpty) {
      print('🔍 LOCAL_OCR: No batches available for matching');
      return BatchMatchResult(batchNumber: '', confidence: 0.0);
    }

    final cleanText = extractedText.toUpperCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    print('🔍 LOCAL_OCR: Searching for batch numbers in: ${cleanText.substring(0, cleanText.length > 100 ? 100 : cleanText.length)}...');

    String bestMatch = '';
    double bestConfidence = 0.0;

    // Step 1: Check for exact matches first
    for (final batch in batches) {
      final batchNumber = batch.batchNumber.toUpperCase();
      
      if (cleanText.contains(batchNumber)) {
        print('🔍 LOCAL_OCR: Found exact match: ${batch.batchNumber}');
        return BatchMatchResult(
          batchNumber: batch.batchNumber,
          confidence: 1.0,
        );
      }
    }

    // Step 2: Check for partial matches with similarity scoring
    for (final batch in batches) {
      final batchNumber = batch.batchNumber.toUpperCase();
      
      // Check if any word in the text is similar to the batch number
      final words = cleanText.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length >= 3) { // Only check words with at least 3 characters
          final similarity = batchNumber.similarityTo(word);
          
          if (similarity > bestConfidence && similarity > 0.7) { // Minimum 70% similarity
            bestMatch = batch.batchNumber;
            bestConfidence = similarity;
          }
        }
      }
    }

    if (bestMatch.isNotEmpty) {
      print('🔍 LOCAL_OCR: Found similarity match: $bestMatch (confidence: ${bestConfidence.toStringAsFixed(2)})');
      return BatchMatchResult(
        batchNumber: bestMatch,
        confidence: bestConfidence,
      );
    }

    print('🔍 LOCAL_OCR: No batch number found in extracted text');
    return BatchMatchResult(batchNumber: '', confidence: 0.0);
  }

  /// Dispose of resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _textRecognizer.close();
      _isInitialized = false;
      print('🔍 LOCAL_OCR: Disposed text recognizer');
    }
  }
}

/// Result of batch matching operation
class BatchMatchResult {
  final String batchNumber;
  final double confidence;

  BatchMatchResult({
    required this.batchNumber,
    required this.confidence,
  });
}
