import 'package:booking_system_flutter/model/pagination_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';

class CategoryResponse {
  List<CategoryData>? categoryList;
  Pagination? pagination;

  CategoryResponse({this.categoryList, this.pagination});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      categoryList: json['data'] != null
          ? (json['data'] as List).map((i) => CategoryData.fromJson(i)).toList()
          : null,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.categoryList != null) {
      data['data'] = this.categoryList!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class CategoryData {
  String? categoryImage;
  String? categoryExtension;
  String? color;
  String? description;
  int? id;
  int? isFeatured;
  String? name;
  int? priority;
  int? status;
  bool isSelected;
  dynamic services;
  List<ServiceData>? totalServices;
  String? deletedAt;

  CategoryData({
    this.categoryImage,
    this.categoryExtension,
    this.color,
    this.description,
    this.id,
    this.isFeatured,
    this.name,
    this.priority,
    this.status,
    this.isSelected = false,
    this.services,
    this.totalServices,
    this.deletedAt,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      categoryImage: json['category_image'],
      categoryExtension: json['category_extension'],
      color: json['color'],
      description: json['description'],
      id: json['id'],
      isFeatured: json['is_featured'],
      name: json['name'],
      priority: json['priority'],
      status: json['status'],
      services: json['services'],
      totalServices: json['total_services'] != null
          ? (json['total_services'] as List)
              .map((i) => ServiceData.fromJson(i))
              .toList()
          : null,
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['category_image'] = this.categoryImage;
    data['category_extension'] = this.categoryExtension;
    data['color'] = this.color;
    data['description'] = this.description;
    data['id'] = this.id;
    data['is_featured'] = this.isFeatured;
    data['name'] = this.name;
    data['priority'] = this.priority;
    data['status'] = this.status;
    data['services'] = this.services;
    if (this.totalServices != null) {
      data['total_services'] =
          this.totalServices!.map((v) => v.toJson()).toList();
    }
    data['deleted_at'] = this.deletedAt;
    return data;
  }
}
