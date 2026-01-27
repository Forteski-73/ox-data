// -----------------------------------------------------------
// app/views/login/login_page.dart (Tela de Login)
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';
import 'package:oxdata/app/core/widgets/app_footer.dart';
import 'package:oxdata/app/core/utils/network_status.dart';
import 'package:oxdata/app/core/services/message_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores para os campos de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Estado para o checkbox "Lembrar-me"
  bool _rememberMe = false;

  // Variável para controlar a visibilidade da senha
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtém as instâncias dos serviços
    final authService = context.read<AuthService>();
    final loadingService = context.read<LoadingService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Logo da aplicação
              Center(
                child: Image.asset(
                  'assets/images/oxford-logo-p.png',
                  height: 120,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Bem-vindo!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Acesse sua conta para continuar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Usuário',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.grey[100],
                  // Borda para o estado padrão
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  // Borda para o estado habilitado
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  // Borda para o estado focado
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF333333),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
                                
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: Colors.grey[100],
                  // Borda para o estado padrão
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  // Borda para o estado habilitado
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  // Borda para o estado focado
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF333333), // Cor da borda quando focado
                      width: 1.0,
                    ),
                  ),
                  // Adiciona o ícone de olho no canto direito
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
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      const Text('Lembrar-me'),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // Implementar navegação para a tela de recuperação de senha
                    },
                    child: const Text('Esqueceu a senha?'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Botão de Entrar
              ElevatedButton(
                onPressed: loadingService.isLoading ? null : () async {

                  final hasInternet = await NetworkUtils.hasInternetConnection();
                  if (hasInternet) { 
                    FocusScope.of(context).unfocus();
                    loadingService.show();
                    final email = _emailController.text;
                    final password = _passwordController.text;

                    await authService.login(email, password, _rememberMe);

                    if (mounted) {
                      loadingService.hide();
                      if (authService.isAuthenticated) {
                        Navigator.of(context).pushReplacementNamed(RouteGenerator.homePage);
                      }
                      else
                      {
                        MessageService.showInfo("Ops! Usuário ou Senha não encontrado!");
                      }
                    }
                  }
                  else
                  {
                    MessageService.showWarning("Ops! Parece que você está sem internet. Conecte-se para que possamos validar seu acesso.");
                  }

                },
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 24),

              // Link para "Cadastre-se"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Não tem uma conta?"),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(RouteGenerator.loginReg);
                    },
                    child: const Text('Cadastre-se'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}