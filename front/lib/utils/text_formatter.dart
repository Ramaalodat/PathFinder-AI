import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextFormatter {
  /// Parses markdown-like text and returns a list of TextSpan widgets
  /// Supports: **bold**, *italic*, \n for new lines, bullet points, and basic formatting
  static List<TextSpan> parseMarkdownText(String text, {
    required Color textColor,
    required double fontSize,
    FontWeight? fontWeight,
  }) {
    if (text.isEmpty) return [];

    // First, preprocess the text to handle newlines and formatting
    String processedText = preprocessText(text);
    
    List<TextSpan> spans = [];
    String remainingText = processedText;
    int currentIndex = 0;

    while (currentIndex < remainingText.length) {
      // Look for **bold** text first (highest priority)
      final boldMatch = RegExp(r'\*\*(.*?)\*\*').firstMatch(remainingText.substring(currentIndex));
      if (boldMatch != null && boldMatch.start == 0) {
        // Add any text before the bold section
        if (currentIndex > 0) {
          spans.add(TextSpan(
            text: remainingText.substring(0, currentIndex),
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ));
        }
        
        // Add the bold text
        spans.add(TextSpan(
          text: boldMatch.group(1),
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ));
        
        // Update current index and remaining text
        currentIndex += boldMatch.end;
        remainingText = remainingText.substring(currentIndex);
        currentIndex = 0;
        continue;
      }

      // Look for *italic* text (but not if it's part of **bold**)
      final italicMatch = RegExp(r'(?<!\*)\*([^*]+)\*(?!\*)').firstMatch(remainingText.substring(currentIndex));
      if (italicMatch != null && italicMatch.start == 0) {
        // Add any text before the italic section
        if (currentIndex > 0) {
          spans.add(TextSpan(
            text: remainingText.substring(0, currentIndex),
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ));
        }
        
        // Add the italic text
        spans.add(TextSpan(
          text: italicMatch.group(1),
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: FontStyle.italic,
          ),
        ));
        
        // Update current index and remaining text
        currentIndex += italicMatch.end;
        remainingText = remainingText.substring(currentIndex);
        currentIndex = 0;
        continue;
      }

      // Look for bullet points (• or - or *) - only at start of line or after newline
      final bulletMatch = RegExp(r'^[\s]*[•\-\*]\s+').firstMatch(remainingText.substring(currentIndex));
      if (bulletMatch != null && bulletMatch.start == 0) {
        // Check if this bullet point should be on a new line
        bool shouldAddNewline = false;
        if (currentIndex > 0) {
          // Check if the character before currentIndex is not a newline
          String textBefore = remainingText.substring(0, currentIndex);
          if (textBefore.isNotEmpty && !textBefore.endsWith('\n')) {
            shouldAddNewline = true;
          }
        }
        
        // Add any text before the bullet
        if (currentIndex > 0) {
          spans.add(TextSpan(
            text: remainingText.substring(0, currentIndex),
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ));
        }
        
        // Add newline if needed, then bullet point
        if (shouldAddNewline) {
          spans.add(TextSpan(
            text: '\n',
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ));
        }
        
        // Add the bullet point with proper indentation
        spans.add(TextSpan(
          text: '• ',
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ));
        
        // Update current index and remaining text
        currentIndex += bulletMatch.end;
        remainingText = remainingText.substring(currentIndex);
        currentIndex = 0;
        continue;
      }

      // Look for numbered lists (1. 2. etc.)
      final numberedMatch = RegExp(r'^[\s]*\d+\.\s+').firstMatch(remainingText.substring(currentIndex));
      if (numberedMatch != null && numberedMatch.start == 0) {
        // Add any text before the numbered item
        if (currentIndex > 0) {
          spans.add(TextSpan(
            text: remainingText.substring(0, currentIndex),
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ));
        }
        
        // Add the numbered item
        spans.add(TextSpan(
          text: numberedMatch.group(0),
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ));
        
        // Update current index and remaining text
        currentIndex += numberedMatch.end;
        remainingText = remainingText.substring(currentIndex);
        currentIndex = 0;
        continue;
      }

      // Look for regular newlines
      final newlineMatch = RegExp(r'\n').firstMatch(remainingText.substring(currentIndex));
      if (newlineMatch != null && newlineMatch.start == 0) {
        // Add any text before the newline
        if (currentIndex > 0) {
          spans.add(TextSpan(
            text: remainingText.substring(0, currentIndex),
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ));
        }
        
        // Add the newline
        spans.add(TextSpan(
          text: '\n',
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ));
        
        // Update current index and remaining text
        currentIndex += newlineMatch.end;
        remainingText = remainingText.substring(currentIndex);
        currentIndex = 0;
        continue;
      }

      // If no special formatting found, move to next character
      currentIndex++;
    }

    // Add any remaining text
    if (remainingText.isNotEmpty) {
      spans.add(TextSpan(
        text: remainingText,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ));
    }

    return spans;
  }

  /// Creates a RichText widget with formatted text
  static Widget createFormattedText(String text, {
    required Color textColor,
    required double fontSize,
    FontWeight? fontWeight,
    TextAlign textAlign = TextAlign.left,
  }) {
    final spans = parseMarkdownText(
      text,
      textColor: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign,
    );
  }

  /// Preprocesses text to handle common Flowise formatting issues
  static String preprocessText(String text) {
    if (text.isEmpty) return text;
    
    // Handle escaped newlines first
    text = text.replaceAll('\\n', '\n');
    
    // Handle different types of newlines and line breaks
    text = text.replaceAll(RegExp(r'\r\n'), '\n'); // Windows line endings
    text = text.replaceAll(RegExp(r'\r'), '\n');   // Mac line endings
    
    // Clean up multiple spaces but preserve intentional spacing
    text = text.replaceAll(RegExp(r'[ \t]+'), ' '); // Replace multiple spaces/tabs with single space
    
    // Clean up multiple newlines (keep max 2 consecutive)
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    
    // Handle common Flowise formatting patterns
    // Ensure proper spacing around bold and italic markers
    text = text.replaceAll(RegExp(r'\\*\\*(\\w+)\\*\\*'), r'**$1**');
    text = text.replaceAll(RegExp(r'\\*(\\w+)\\*'), r'*$1*');
    
    // Normalize bullet points (only convert - and * to •, don't add extra newlines)
    text = text.replaceAll(RegExp(r'^[\s]*[-*]\s+', multiLine: true), '• ');
    
    // Ensure proper spacing after colons for lists
    text = text.replaceAll(RegExp(r':\s*\n'), ':\n');
    
    // Clean up any double newlines that might have been created
    text = text.replaceAll(RegExp(r'\n\n+'), '\n\n');
    
    return text.trim();
  }
}
