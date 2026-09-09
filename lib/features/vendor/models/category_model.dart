/// CategoryModel
/// Reusable data model for brand and part-type option items.
class CategoryModel {
  final int id;
  final String name;

  CategoryModel({
    required this.id,
    required this.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 933e2ef9672b79d50dcca3f1bc1666d87b0e4a02
