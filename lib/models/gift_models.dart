class Category {
  final int id;
  final String name;
  final String icon;
  final List<String> subs;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.subs,
  });
}

class Gift {
  final String id;
  final String name;
  final String shortName;
  final int price;
  final String emoji;
  final String catIcon;
  final String catName;
  final String subName;

  const Gift({
    required this.id,
    required this.name,
    required this.shortName,
    required this.price,
    required this.emoji,
    required this.catIcon,
    required this.catName,
    required this.subName,
  });

  int get catId => int.tryParse(id.split('_').first) ?? -1;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'price': price,
    'emoji': emoji,
    'catIcon': catIcon,
    'catName': catName,
    'subName': subName,
  };

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      price: (json['price'] as num).toInt(),
      emoji: json['emoji'] as String,
      catIcon: json['catIcon'] as String,
      catName: json['catName'] as String,
      subName: json['subName'] as String,
    );
  }
}
