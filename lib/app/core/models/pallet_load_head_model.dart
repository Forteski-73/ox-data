// app/core/models/pallet_load_head_model.dart

class PalletLoadHeadModel {
  int       loadId;
  String    name;
  String?   description;
  String    status;
  DateTime  date;
  String    time;
  String?   createdUser;

  PalletLoadHeadModel({
    required this.loadId,
    required this.name,
    this.description,
    required this.status,
    required this.date,
    required this.time,
    this.createdUser,
  });

  // Construtor a partir de Map (recebe dados da API)
  factory PalletLoadHeadModel.fromMap(Map<String, dynamic> map) {
    return PalletLoadHeadModel(
      loadId:       map['loadId'] as int,
      name:         map['name'] as String,
      description:  map['description'] as String?,
      status:       map['status'] as String,
      date:         DateTime.parse(map['date'] as String),
      time:         map['time'] as String,
      createdUser:  map['createdUser'] as String?,
    );
  }

  // Converte o objeto para Map (para envio à API)
  Map<String, dynamic> toMap() {
    return {
      'loadId':       loadId,
      'name':         name,
      'description':  description,
      'status':       status,
      'date':         "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'time':         time,
      'createdUser':  createdUser,
    };
  }

  PalletLoadHeadModel copyWith({
    int? loadId,
    String? name,
    String? description,
    String? status,
    DateTime? date,
    String? time,
    String? createdUser,
  }) {
    return PalletLoadHeadModel(
      loadId: loadId ?? this.loadId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      date: date ?? this.date,
      time: time ?? this.time,
      createdUser: createdUser ?? this.createdUser,
    );
  }

}