import 'package:flutter/material.dart';

class FocusFlowIconMapper {
  const FocusFlowIconMapper._();

  static const choices = <IconData>[
    Icons.person_outline_rounded,
    Icons.work_outline_rounded,
    Icons.school_outlined,
    Icons.code_rounded,
    Icons.fitness_center_rounded,
    Icons.menu_book_rounded,
    Icons.business_center_outlined,
    Icons.home_outlined,
    Icons.star_border_rounded,
    Icons.category_outlined,
    Icons.favorite_border_rounded,
    Icons.lightbulb_outline_rounded,
    Icons.attach_money_rounded,
    Icons.directions_run_rounded,
    Icons.laptop_mac_rounded,
    Icons.track_changes_rounded,
  ];

  static IconData parseIcon(String code) {
    switch (code) {
      case 'person_outline_rounded':
        return Icons.person_outline_rounded;
      case 'work_outline_rounded':
        return Icons.work_outline_rounded;
      case 'school_outlined':
        return Icons.school_outlined;
      case 'code_rounded':
        return Icons.code_rounded;
      case 'fitness_center_rounded':
        return Icons.fitness_center_rounded;
      case 'menu_book_rounded':
        return Icons.menu_book_rounded;
      case 'business_center_outlined':
        return Icons.business_center_outlined;
      case 'home_outlined':
        return Icons.home_outlined;
      case 'star_border_rounded':
        return Icons.star_border_rounded;
      case 'category_outlined':
        return Icons.category_outlined;
      case 'favorite_border_rounded':
        return Icons.favorite_border_rounded;
      case 'lightbulb_outline_rounded':
        return Icons.lightbulb_outline_rounded;
      case 'attach_money_rounded':
        return Icons.attach_money_rounded;
      case 'directions_run_rounded':
        return Icons.directions_run_rounded;
      case 'laptop_mac_rounded':
        return Icons.laptop_mac_rounded;
      case 'track_changes_rounded':
      default:
        return Icons.track_changes_rounded;
    }
  }

  static String reverseParseIcon(IconData icon) {
    if (icon == Icons.person_outline_rounded) return 'person_outline_rounded';
    if (icon == Icons.work_outline_rounded) return 'work_outline_rounded';
    if (icon == Icons.school_outlined) return 'school_outlined';
    if (icon == Icons.code_rounded) return 'code_rounded';
    if (icon == Icons.fitness_center_rounded) return 'fitness_center_rounded';
    if (icon == Icons.menu_book_rounded) return 'menu_book_rounded';
    if (icon == Icons.business_center_outlined) return 'business_center_outlined';
    if (icon == Icons.home_outlined) return 'home_outlined';
    if (icon == Icons.star_border_rounded) return 'star_border_rounded';
    if (icon == Icons.category_outlined) return 'category_outlined';
    if (icon == Icons.favorite_border_rounded) return 'favorite_border_rounded';
    if (icon == Icons.lightbulb_outline_rounded) return 'lightbulb_outline_rounded';
    if (icon == Icons.attach_money_rounded) return 'attach_money_rounded';
    if (icon == Icons.directions_run_rounded) return 'directions_run_rounded';
    if (icon == Icons.laptop_mac_rounded) return 'laptop_mac_rounded';
    return 'track_changes_rounded';
  }
}
