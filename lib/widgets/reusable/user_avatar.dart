import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/constants.dart';

/// Global static cache: maps a key (url/path hash) → decoded bytes.
/// Lives for the whole app session — prevents re-decoding base64 on every
/// widget rebuild / screen navigation.
class _ImageCache {
  _ImageCache._();

  static final Map<String, Uint8List> _bytes = {};

  static Uint8List? get(String key) => _bytes[key];

  static void put(String key, Uint8List bytes) {
    // Keep cache bounded — evict oldest when > 30 entries
    if (_bytes.length >= 30) {
      _bytes.remove(_bytes.keys.first);
    }
    _bytes[key] = bytes;
  }
}

/// A reusable avatar widget that displays a user's profile image.
///
/// Supports:
/// - Network URLs (http/https)  — loaded & disk-cached by [CachedNetworkImage]
/// - Base64 data URIs           — decoded once, then kept in a static memory cache
/// - Local file paths           — loaded via [FileImage]
/// - Fallback to initials or a default icon
class UserAvatar extends StatelessWidget {
  /// The profile image URL (can be a network URL, base64 data URI, or local path).
  final String? imageUrl;

  /// The user's name (used for generating initials as fallback).
  final String? name;

  /// The radius of the circle avatar.
  final double radius;

  /// Background color when showing initials/icon fallback.
  final Color? backgroundColor;

  /// Text color for initials.
  final Color? foregroundColor;

  /// Icon to show when no image and no name is available.
  final IconData fallbackIcon;

  /// Size of the fallback icon.
  final double? iconSize;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.fallbackIcon = Icons.person,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primaryBlue.withValues(alpha: 0.1);
    final fg = foregroundColor ?? AppColors.primaryBlue;
    final diameter = radius * 2;

    final url = imageUrl;

    // ── Network URL ──────────────────────────────────────────────────────────
    if (url != null &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          // Shimmer placeholder while loading
          placeholder: (_, __) => _shimmerCircle(diameter, bg),
          // Fallback on error
          errorWidget: (_, __, ___) => _fallback(bg, fg),
        ),
      );
    }

    // ── Base64 data URI ──────────────────────────────────────────────────────
    if (url != null && url.startsWith('data:image')) {
      final bytes = _decodeBase64Cached(url);
      if (bytes != null) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          backgroundImage: MemoryImage(bytes),
          onBackgroundImageError: (_, __) {},
        );
      }
    }

    // ── Local file path ──────────────────────────────────────────────────────
    if (url != null && url.isNotEmpty) {
      final file = File(url);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          backgroundImage: FileImage(file),
          onBackgroundImageError: (_, __) {},
        );
      }
    }

    // ── Fallback ─────────────────────────────────────────────────────────────
    return _fallback(bg, fg);
  }

  // ---------------------------------------------------------------------------

  /// Decodes a base64 data URI, caching the result so subsequent builds skip
  /// the expensive decode step entirely.
  static Uint8List? _decodeBase64Cached(String dataUri) {
    // Use the last 32 chars of the URI as a lightweight cache key
    final key = dataUri.length > 48 ? dataUri.substring(dataUri.length - 48) : dataUri;
    final cached = _ImageCache.get(key);
    if (cached != null) return cached;

    try {
      final base64Str = dataUri.split(',').last;
      final bytes = base64Decode(base64Str);
      _ImageCache.put(key, bytes);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Widget _fallback(Color bg, Color fg) {
    if (name != null && name!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Text(
          name![0].toUpperCase(),
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Icon(
        fallbackIcon,
        color: fg,
        size: iconSize ?? radius * 0.9,
      ),
    );
  }

  Widget _shimmerCircle(double size, Color baseColor) {
    return Shimmer.fromColors(
      baseColor: baseColor.withValues(alpha: 0.3),
      highlightColor: Colors.white.withValues(alpha: 0.6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: baseColor),
      ),
    );
  }
}
