import 'package:flutter/material.dart';

/// الباك اند بيخزّن اسم الأيقونة كنص، وفلاتر محتاج كائن [IconData].
///
/// التحويل بيتعمل بجدول صريح مش بالبحث بالاسم وقت التشغيل، لأن فلاتر بيشيل
/// الأيقونات غير المستخدمة وقت البناء، فالبحث الديناميكي بيرجع فاضي في نسخة الإصدار.
const Map<String, IconData> _iconsByName = <String, IconData>{
  'category': Icons.category_outlined,
  'local_drink': Icons.local_drink_outlined,
  'fastfood': Icons.fastfood_outlined,
  'cleaning_services': Icons.cleaning_services_outlined,
  'egg': Icons.egg_outlined,
  'bakery_dining': Icons.bakery_dining_outlined,
  'kitchen': Icons.kitchen_outlined,
  'icecream': Icons.icecream_outlined,
  'local_cafe': Icons.local_cafe_outlined,
  'local_pizza': Icons.local_pizza_outlined,
  'lunch_dining': Icons.lunch_dining_outlined,
  'liquor': Icons.liquor_outlined,
  'set_meal': Icons.set_meal_outlined,
  'spa': Icons.spa_outlined,
  'checkroom': Icons.checkroom_outlined,
  'devices': Icons.devices_outlined,
  'toys': Icons.toys_outlined,
  'pets': Icons.pets_outlined,
  'medication': Icons.medication_outlined,
  'shopping_basket': Icons.shopping_basket_outlined,
  'inventory_2': Icons.inventory_2_outlined,
};

/// أيقونة القسم من اسمها، وأيقونة عامة لو الاسم مش معروف.
IconData iconForName(String? name) =>
    _iconsByName[name] ?? Icons.inventory_2_outlined;

/// أسماء الأيقونات المتاحة — بتستخدمها شاشة إضافة قسم في قائمة الاختيار.
List<String> get availableIconNames => _iconsByName.keys.toList();
