// -----------------------------------------------------------
// app/views/login/registration_page.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/senior_employee_info.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/storage_service.dart';

/// Etapas do fluxo desta tela.
///
/// [badge]   -> usuário informa apenas o número do crachá.
/// [details] -> dados do colaborador já confirmados via API; usuário
///              revisa e-mail e define a senha.
enum _RegistrationStep { badge, details }

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // Chave global para o formulário de dados (etapa 2), usada para validação.
  final _formKey = GlobalKey<FormState>();
  // Chave global para o formulário do crachá (etapa 1).
  final _badgeFormKey = GlobalKey<FormState>();

  // Controladores para os campos de texto
  final _badgeController = TextEditingController();
  final _nameController = TextEditingController();
  final _nickNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final StorageService _storageService = StorageService();

  // Variáveis de estado para controlar a visibilidade das senhas
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool isFromLogin = false;
  String user = '';

  // Estado do fluxo em duas etapas
  _RegistrationStep _step = _RegistrationStep.badge;
  bool _isValidatingBadge = false;
  String? _badgeErrorText;
  SeniorEmployeeInfo? _employeeInfo;

  @override
  void initState() {
    super.initState();
    _storageService.clearAuthToken();
    _storageService.clearCredentials();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      isFromLogin = args['isFromLogin'] ?? false;
      user = args['user'] ?? '';
      _badgeController.text = user;
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _nameController.dispose();
    _nickNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _extractMessageFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return 'Ocorreu um erro desconhecido.';
    }

    const prefix = "Falha no registro: ";
    String jsonPart = jsonString;

    if (jsonString.startsWith(prefix)) {
      jsonPart = jsonString.substring(prefix.length);
    }

    try {
      final Map<String, dynamic> data = json.decode(jsonPart);
      return data['message'] ?? 'Ocorreu um erro desconhecido.';
    } on FormatException {
      return jsonString; // Retorna a string original se não for um JSON válido
    } catch (e) {
      return 'Ocorreu um erro desconhecido.';
    }
  }

  // -----------------------------------------------------------
  // Etapa 1: validação do crachá
  // -----------------------------------------------------------
  Future<void> _handleBadgeSubmit() async {
    FocusScope.of(context).unfocus();
    setState(() => _badgeErrorText = null);

    if (!_badgeFormKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final badgeCode = _badgeController.text.trim();

    setState(() => _isValidatingBadge = true);

    final result = await authService.loginWithBadge(badgeCode);

    if (!mounted) return;
    setState(() => _isValidatingBadge = false);

    if (result.success && result.data != null) {
      final info = result.data!;
      setState(() {
        _employeeInfo = info;
        _nameController.text = info.name;
        _emailController.text = info.email;
        _step = _RegistrationStep.details;
      });
    } else {
      setState(() {
        _badgeErrorText = result.errorMessage.isNotEmpty
            ? result.errorMessage
            : 'Não foi possível validar o crachá. Tente novamente.';
      });
    }
  }

  /// Permite ao usuário voltar e informar outro número de crachá.
  void _handleChangeBadge() {
    setState(() {
      _employeeInfo = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _badgeErrorText = null;
      _step = _RegistrationStep.badge;
    });
  }

  // -----------------------------------------------------------
  // Etapa 2: confirmação de dados + envio do cadastro
  // -----------------------------------------------------------
  Future<void> _handleRegisterSubmit() async {
    FocusScope.of(context).unfocus();

    final authService = context.read<AuthService>();
    final loadingService = context.read<LoadingService>();

    if (!_formKey.currentState!.validate()) return;

    loadingService.show();
    final name = _nickNameController.text;
    final password = _passwordController.text;
    final email = _emailController.text;

    final response = await authService.userRegister(name, password, email);

    if (!mounted) return;
    loadingService.hide();

    if (response.success) {
      // Se o registro for bem-sucedido, exibe o AlertDialog
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('${response.message}'),
            content: Text(
              'Bem-vindo, $name!',
              style: const TextStyle(fontSize: 16),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Erro'),
            content: Text(_extractMessageFromJson(response.message)),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  FocusScope.of(context).unfocus();
                },
              ),
            ],
          );
        },
      );
    }
  }

  // -----------------------------------------------------------
  // Estilos reutilizáveis
  // -----------------------------------------------------------
  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF333333), width: 1.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastre-se'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _step == _RegistrationStep.badge
              ? _buildBadgeStep(key: const ValueKey('badge_step'))
              : _buildDetailsStep(key: const ValueKey('details_step')),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // UI - Etapa 1: informar o crachá
  // -----------------------------------------------------------
  Widget _buildBadgeStep({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: _badgeFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            Center(
              child: Image.asset(
                'assets/images/oxford-logo-p.png',
                height: 100,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Identifique-se',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Informe o número do seu crachá para continuar',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _badgeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: _fieldDecoration(
                label: 'Crachá',
                icon: Icons.badge_outlined,
                errorText: _badgeErrorText,
              ),
              onFieldSubmitted: (_) =>
                  _isValidatingBadge ? null : _handleBadgeSubmit(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, informe o número do crachá';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isValidatingBadge ? null : _handleBadgeSubmit,
              child: _isValidatingBadge
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Continuar', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Já tem uma conta?'),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fazer Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // UI - Etapa 2: confirmação de dados + senha
  // -----------------------------------------------------------
  Widget _buildDetailsStep({Key? key}) {
    final info = _employeeInfo;

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 22),
            Center(
              child: Image.asset(
                'assets/images/oxford-logo-p.png',
                height: 80,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isFromLogin ? 'Crie sua conta' : 'Recuperação de Senha',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isFromLogin
                  ? 'Confira seus dados e defina uma senha'
                  : 'Confira seus dados e informe a nova senha',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),

            if (info != null) _buildEmployeeSummaryCard(info),

            const SizedBox(height: 22),

            // Campo de E-mail (pré-preenchido pela API, editável)
            TextFormField(
              controller: _emailController,
              readOnly: true,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration(
                label: 'E-mail',
                icon: Icons.email_outlined,
              ),
            ),
            
            const SizedBox(height: 12),

            // Campo de Nome
            TextFormField(
              controller: _nickNameController,
              inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return newValue.copyWith(
                      text: newValue.text.toLowerCase(),
                    );
                  }),
                ],
              decoration: InputDecoration(
                labelText: 'Usuário',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF333333),
                    width: 1.0,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira seu nome';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Campo de Senha
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: _fieldDecoration(
                label: isFromLogin ? 'Senha' : 'Nova Senha',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira uma senha';
                }
                if (value.length < 6) {
                  return 'A senha deve ter pelo menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Campo de Confirmar Senha
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: _fieldDecoration(
                label: 'Confirmar Senha',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, confirme sua senha';
                }
                if (value != _passwordController.text) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),

            Consumer<LoadingService>(
              builder: (context, loadingService, _) {
                return ElevatedButton(
                  onPressed:
                      loadingService.isLoading ? null : _handleRegisterSubmit,
                  child: const Text('Cadastrar', style: TextStyle(fontSize: 18)),
                );
              },
            ),
            const SizedBox(height: 16),

            Center(
              child: TextButton.icon(
                onPressed: _handleChangeBadge,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Usar outro crachá'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Cartão de confirmação com os dados retornados pela API a partir do
  /// crachá. São somente leitura: vêm do sistema Senior e não devem ser
  /// editados manualmente pelo usuário nesta tela.
  Widget _buildEmployeeSummaryCard(SeniorEmployeeInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(Icons.work_outline, info.position),
          if (info.department.isNotEmpty)
            _buildSummaryRow(Icons.apartment_outlined, info.department),
          if (info.companyName.isNotEmpty)
            _buildSummaryRow(Icons.domain_outlined, info.companyName),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


// -----------------------------------------------------------
// app/views/login/registration_page.dart
// -----------------------------------------------------------
/*
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/storage_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // Chave global para o formulário, usada para validação.
  final _formKey = GlobalKey<FormState>();

  // Controladores para os campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final StorageService _storageService = StorageService();

  // Variáveis de estado para controlar a visibilidade das senhas
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool isFromLogin = false;
  String user = '';

  @override
  void initState() {
    super.initState();
    _storageService.clearAuthToken();
    _storageService.clearCredentials();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      isFromLogin = args['isFromLogin'] ?? false;
      user = args['user'] ?? '';
      _nameController.text = user;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _extractMessageFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return 'Ocorreu um erro desconhecido.';
    }

    const prefix = "Falha no registro: ";
    String jsonPart = jsonString;

    if (jsonString.startsWith(prefix)) {
      jsonPart = jsonString.substring(prefix.length);
    }

    try {
      final Map<String, dynamic> data = json.decode(jsonPart);
      return data['message'] ?? 'Ocorreu um erro desconhecido.';
    } on FormatException {
      return jsonString; // Retorna a string original se não for um JSON válido
    } catch (e) {
      return 'Ocorreu um erro desconhecido.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final loadingService = context.read<LoadingService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastre-se'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // Logo da aplicação
                Center(
                  child: Image.asset(
                    'assets/images/oxford-logo-p.png',
                    height: 100,
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  isFromLogin 
                      ? 'Crie sua conta' 
                      : 'Recuperação de Senha',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isFromLogin
                  ? 'Preencha seus dados para começar'
                  : 'Informe seu E-Mail e a nova Senha',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),
                // Campo de Nome
                TextFormField(
                  controller: _nameController,
                  inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return newValue.copyWith(
                          text: newValue.text.toLowerCase(),
                        );
                      }),
                    ],
                  decoration: InputDecoration(
                    labelText: 'Usuário',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF333333),
                        width: 1.0,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo de E-mail
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF333333),
                        width: 1.0,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu e-mail';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Por favor, insira um e-mail válido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo de Senha
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: isFromLogin ? 'Senha' : 'Nova Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF333333),
                        width: 1.0,
                      ),
                    ),
                    // Adiciona o ícone de olho e a lógica de toggle
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo de Confirmar Senha
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF333333),
                        width: 1.0,
                      ),
                    ),
                    // Adiciona o ícone de olho e a lógica de toggle
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirme sua senha';
                    }
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Botão de Cadastrar
                ElevatedButton(
                  onPressed: loadingService.isLoading ? null : () async {
                  FocusScope.of(context).unfocus();
                  if (_formKey.currentState!.validate()) {
                    loadingService.show();
                    final name = _nameController.text;
                    final password = _passwordController.text;
                    final email = _emailController.text;

                    final response = await authService.userRegister(name, password, email);

                    if (mounted) {
                      loadingService.hide();
                      if (response.success) {
                        // Se o registro for bem-sucedido, exibe o AlertDialog
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title:  Text('${response.message}'), 
                              content:Text(
                                'Bem-vindo, $name!',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    // Fecha o diálogo
                                    Navigator.of(dialogContext).pop();
                                    // Volta para a tela anterior (login)
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        // Adicionado: Mostra um AlertDialog com a mensagem de erro
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: const Text('Erro'),
                              content: Text(_extractMessageFromJson(response.message)),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    }
                  }
                },
                  child: const Text(
                    'Cadastrar',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Já tem uma conta?"),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Fazer Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/