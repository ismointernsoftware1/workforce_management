import 'package:flutter/material.dart';

enum SearchResultType { task, teamMember, expense, conversation }

class SearchResult {
  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.avatarText,
    this.email,
    this.role,
  });

  final SearchResultType type;
  final String id;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? avatarText; // For displaying initials in avatar
  final String? email;
  final String? role;
}

