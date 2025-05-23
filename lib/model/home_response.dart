import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/category_model.dart';

class HomeResponse {
  bool? status;
  List<SliderItem>? slider;
  List<CategoryData>? category;
  List<ServiceData>? service;

  HomeResponse({
    this.status,
    this.slider,
    this.category,
    this.service,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      status: json['status'],
      slider: json['slider'] != null
          ? (json['slider'] as List).map((i) => SliderItem.fromJson(i)).toList()
          : null,
      category: json['category'] != null
          ? (json['category'] as List)
              .map((i) => CategoryData.fromJson(i))
              .toList()
          : null,
      service: json['service'] != null
          ? (json['service'] as List)
              .map((i) => ServiceData.fromJson(i))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.slider != null) {
      data['slider'] = this.slider!.map((v) => v.toJson()).toList();
    }
    if (this.category != null) {
      data['category'] = this.category!.map((v) => v.toJson()).toList();
    }
    if (this.service != null) {
      data['service'] = this.service!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SliderItem {
  int? id;
  String? title;
  String? type;
  int? typeId;
  int? status;
  String? description;
  String? direction;
  String? mediaType;
  String? serviceName;
  String? sliderImage;

  bool get isDirectionUp => (direction ?? '').toLowerCase() == 'up';
  bool get isVideo => (mediaType ?? '').toLowerCase() == 'video';

  SliderItem({
    this.id,
    this.title,
    this.type,
    this.typeId,
    this.status,
    this.description,
    this.direction,
    this.mediaType,
    this.serviceName,
    this.sliderImage,
  });

  factory SliderItem.fromJson(Map<String, dynamic> json) {
    return SliderItem(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      typeId: json['type_id'],
      status: json['status'],
      description: json['description'],
      direction: json['direction'],
      mediaType: json['media_type'],
      serviceName: json['service_name'],
      sliderImage: json['slider_image'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['type'] = this.type;
    data['type_id'] = this.typeId;
    data['status'] = this.status;
    data['description'] = this.description;
    data['direction'] = this.direction;
    data['media_type'] = this.mediaType;
    data['service_name'] = this.serviceName;
    data['slider_image'] = this.sliderImage;
    return data;
  }
}
