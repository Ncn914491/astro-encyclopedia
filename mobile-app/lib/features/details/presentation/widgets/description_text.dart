import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// DescriptionText Widget - Renders description with proper styling
/// 
/// Features:
/// - Detects and parses Markdown content
/// - Good typography with fontSize: 16 and height: 1.5
/// - Handles HTML links in NASA descriptions
/// - Clickable links open in browser
class DescriptionText extends StatelessWidget {
  final String description;
  final String? title;

  const DescriptionText({
    super.key,
    required this.description,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    final cleanedContent = _cleanContent(description);
    final isMarkdown = _hasMarkdownOrHtml(cleanedContent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (isMarkdown)
          _buildMarkdownContent(context, cleanedContent)
        else
          _buildPlainText(cleanedContent),
      ],
    );
  }

  /// Clean up NASA HTML content to be more readable
  String _cleanContent(String content) {
    // Convert HTML links to Markdown links
    var cleaned = content.replaceAllMapped(
      RegExp(r'<a href="([^"]*)"[^>]*>([^<]*)</a>'),
      (match) => '[${match[2]}](${match[1]})',
    );
    
    // Remove remaining HTML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');
    
    // Clean up multiple newlines
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // Trim and clean
    return cleaned.trim();
  }

  /// Check if content contains Markdown or HTML formatting
  bool _hasMarkdownOrHtml(String content) {
    // Check for Markdown syntax
    if (content.contains('**') || 
        content.contains('__') ||
        content.contains('##') ||
        content.contains('- ') ||
        content.contains('* ') ||
        RegExp(r'\[.*\]\(.*\)').hasMatch(content)) {
      return true;
    }
    
    // Check for HTML
    if (content.contains('<') && content.contains('>')) {
      return true;
    }
    
    return false;
  }

  Widget _buildMarkdownContent(BuildContext context, String content) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          height: 1.5,
        ),
        h1: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        h2: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h3: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        strong: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        em: const TextStyle(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
        ),
        a: const TextStyle(
          color: Colors.lightBlueAccent,
          decoration: TextDecoration.underline,
        ),
        blockquote: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 16,
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
        listBullet: const TextStyle(
          color: Colors.white70,
        ),
      ),
      onTapLink: (text, href, title) async {
        if (href != null) {
          final uri = Uri.tryParse(href);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
    );
  }

  Widget _buildPlainText(String content) {
    return Text(
      content,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        height: 1.5,
      ),
    );
  }
}
