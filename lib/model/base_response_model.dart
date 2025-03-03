class BaseResponseModel {
  String? message;
  bool? status;
  Map<String, dynamic>? data;

  BaseResponseModel({this.message, this.status, this.data});

  factory BaseResponseModel.fromJson(Map<String, dynamic> json) {
    return BaseResponseModel(
      message: json['message'],
      status: json['status'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data;
    }
    return data;
  }
}