// -----------------------------------------------------------
// app/core/models/senior_employee_info.dart
// -----------------------------------------------------------
//
// Representa os dados de um colaborador retornados pela API
// `POST /API/v1/AuthSenior/Login`, consultada a partir do
// número do crachá.

class SeniorEmployeeInfo {
  final String token;
  final String name;
  final String registration;
  final String position;
  final String companyName;
  final String department;
  final String email;
  final String workShift;
  final String phoneContact;

  const SeniorEmployeeInfo({
    required this.token,
    required this.name,
    required this.registration,
    required this.position,
    required this.companyName,
    required this.department,
    required this.email,
    required this.workShift,
    required this.phoneContact,
  });

  factory SeniorEmployeeInfo.fromJson(Map<String, dynamic> json) {
    return SeniorEmployeeInfo(
      token: json['token'] as String? ?? '',
      name: (json['name'] as String? ?? '').trim(),
      registration: json['registration'] as String? ?? '',
      position: (json['position'] as String? ?? '').trim(),
      companyName: (json['companyName'] as String? ?? '').trim(),
      department: (json['department'] as String? ?? '').trim(),
      email: (json['email'] as String? ?? '').trim(),
      workShift: (json['workShift'] as String? ?? '').trim(),
      phoneContact: json['phoneContact'] as String? ?? '',
    );
  }

  SeniorEmployeeInfo copyWith({
    String? token,
    String? name,
    String? registration,
    String? position,
    String? companyName,
    String? department,
    String? email,
    String? workShift,
    String? phoneContact,
  }) {
    return SeniorEmployeeInfo(
      token: token ?? this.token,
      name: name ?? this.name,
      registration: registration ?? this.registration,
      position: position ?? this.position,
      companyName: companyName ?? this.companyName,
      department: department ?? this.department,
      email: email ?? this.email,
      workShift: workShift ?? this.workShift,
      phoneContact: phoneContact ?? this.phoneContact,
    );
  }
  
}

/// Wrapper genérico para resultados de chamadas de autenticação/consulta,
/// evitando o uso de exceptions para controle de fluxo esperado
/// (crachá inválido, sem conexão, etc.) e deixando o call site explícito
/// sobre sucesso/falha sem precisar de try/catch espalhado pela UI.
class AuthResult<T> {
  final bool success;
  final T? data;
  final String errorMessage;

  const AuthResult.success(this.data)
      : success = true,
        errorMessage = '';

  const AuthResult.failure(this.errorMessage)
      : success = false,
        data = null;
}