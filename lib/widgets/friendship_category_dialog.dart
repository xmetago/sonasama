import 'package:flutter/material.dart';

import '../models/registration_model.dart';
import '../utils/app_theme.dart';
import 'shared/app_snack.dart';

/// Kategori seçme diyaloğu. Limit, mevcut kategori ve kayıt sayfa durumundan gelir.
class FriendshipCategoryDialog extends StatelessWidget {
  const FriendshipCategoryDialog({
    super.key,
    required this.targetUser,
    required this.currentCategory,
    required this.canMoveTo,
    required this.categoryCount,
    required this.categoryLimit,
    required this.onApply,
  });

  final RegistrationModel targetUser;
  final String? Function() currentCategory;
  final bool Function(String categoryName) canMoveTo;
  final int Function(String categoryName) categoryCount;
  final int Function(String categoryName) categoryLimit;
  final void Function(String categoryName) onApply;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bölümü
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.successColor, AppTheme.successDarkColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            targetUser.judgeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Açıklama metni
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.calmGreenUltraLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.successColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kategori seçin',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildModernCategoryGrid(),

              const SizedBox(height: 16),

              // İptal butonu
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: AppTheme.textButtonStyle.copyWith(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  child: Text(
                    'İptal',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern kategori grid widget'ı
  Widget _buildModernCategoryGrid() {
    final categories = <Map<String, dynamic>>[
      {
        'title': 'Grup-19',
        'color': AppTheme.warningColor,
        'icon': Icons.group,
        'description': 'Sırdaşlar',
        'category': 'Grup-19',
      },
      {
        'title': 'Arkadaş',
        'color': AppTheme.successColor,
        'icon': Icons.favorite,
        'description': 'Güvenilir',
        'category': 'Arkadaş',
      },
      {
        'title': 'Takipçi',
        'color': AppTheme.infoColor,
        'icon': Icons.visibility,
        'description': 'Değer verdiğim',
        'category': 'Takipçi',
      },
      {
        'title': 'Herkes',
        'color': AppTheme.primaryColor,
        'icon': Icons.public,
        'description': 'Samimiyete Değer',
        'category': 'Herkes',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryName = category['category'] as String;
        final categoryColor = category['color'] as Color;
        final isCurrentCategory = currentCategory() == categoryName;
        final canSelect = canMoveTo(categoryName);
        final currentCount = categoryCount(categoryName);
        final limit = categoryLimit(categoryName);
        final limitText = limit == -1 ? '∞' : '$currentCount/$limit';
        
        return GestureDetector(
          onTap: () {
            if (!canSelect) {
              showAppSnack(context, '$categoryName kategorisi dolu! Limit: $limit', backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating);
              return;
            }
            Navigator.of(context).pop();
            onApply(categoryName);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: canSelect 
                ? LinearGradient(
                    colors: [
                      categoryColor,
                      categoryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
              color: canSelect ? null : AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(16),
              border: isCurrentCategory
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: canSelect ? [
                BoxShadow(
                  color: categoryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Stack(
              children: [
                 if (canSelect)
                   Positioned(
                     right: -8,
                     bottom: -8,
                     child: Icon(
                       category['icon'] as IconData,
                       size: 40,
                       color: Colors.white.withOpacity(0.1),
                     ),
                   ),
                 if (isCurrentCategory)
                   Positioned(
                     top: 8,
                     right: 8,
                     child: Icon(Icons.check_circle, color: Colors.white, size: 18),
                   ),

                                 // İçerik
                 Padding(
                   padding: const EdgeInsets.all(12),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // İkon ve limit
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Container(
                             padding: const EdgeInsets.all(6),
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(6),
                             ),
                             child: Icon(
                               category['icon'] as IconData,
                               color: Colors.white,
                               size: 16,
                             ),
                           ),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Text(
                               limitText,
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 10,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ),
                         ],
                       ),

                       const Spacer(),

                       // Başlık
                       Text(
                         category['title'] as String,
                         style: const TextStyle(
                           color: Colors.white,
                           fontSize: 14,
                           fontWeight: FontWeight.bold,
                         ),
                       ),

                       const SizedBox(height: 2),

                       // Açıklama
                       Text(
                         category['description'] as String,
                         style: TextStyle(
                           color: Colors.white.withOpacity(0.8),
                           fontSize: 10,
                         ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ],
                   ),
                 ),

                // Dolu kategori overlay'i
                if (!canSelect)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
