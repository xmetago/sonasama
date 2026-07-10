import 'package:flutter/material.dart';

/// Kategori [iconPath] (string) → [IconData] eşlemesi.
/// [CategoryModel.iconPath] ve [initialCategories] ile kullanılır.
IconData categoryIconFromPath(String? iconPath) {
  if (iconPath == null || iconPath.isEmpty) return Icons.category;
  switch (iconPath) {
    case 'category':
      return Icons.category;
    case 'star':
      return Icons.star;
    case 'heart_broken':
      return Icons.heart_broken;
    case 'favorite':
      return Icons.favorite;
    case 'people':
      return Icons.people;
    case 'family_restroom':
      return Icons.family_restroom;
    case 'group':
      return Icons.group;
    case 'warning':
      return Icons.warning;
    case 'person':
      return Icons.person;
    case 'account_balance':
      return Icons.account_balance;
    case 'work':
      return Icons.work;
    case 'school':
      return Icons.school;
    case 'church':
      return Icons.church;
    case 'apartment':
      return Icons.apartment;
    case 'sports_soccer':
      return Icons.sports_soccer;
    case 'groups':
      return Icons.groups;
    case 'local_hospital':
      return Icons.local_hospital;
    case 'medical_services':
      return Icons.medical_services;
    case 'share':
      return Icons.share;
    case 'badge':
      return Icons.badge;
    case 'gavel':
      return Icons.gavel;
    case 'eco':
      return Icons.eco;
    case 'psychology':
      return Icons.psychology;
    case 'movie':
      return Icons.movie;
    case 'directions_car':
      return Icons.directions_car;
    case 'help_outline':
      return Icons.help_outline;
    default:
      return Icons.category;
  }
}
