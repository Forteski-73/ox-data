// -----------------------------------------------------------
// app/views/login/login_page.dart (Tela de Login)
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';

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
                'Bem-vindo de volta!',
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

              // Campo de e-mail
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Usuário',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 16),

              // Campo de senha
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 8),

              // Checkbox e link para "Esqueceu a senha?"
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
                      // TODO: Implementar navegação para a tela de recuperação de senha
                      print('Esqueceu a senha?');
                    },
                    child: const Text('Esqueceu a senha?'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Botão de Entrar
              ElevatedButton(
                // O botão agora só precisa ser desabilitado se estiver carregando
                onPressed: loadingService.isLoading ? null : () async {
                  loadingService.show(); // Mostra o overlay de carregamento
                  final email = _emailController.text;
                  final password = _passwordController.text;

                  await authService.login(email, password, _rememberMe);

                  if (mounted) {
                    loadingService.hide(); // Esconde o overlay após a operação
                    if (authService.isAuthenticated) {
                      Navigator.of(context).pushReplacementNamed(RouteGenerator.homePage);
                    }
                  }
                },
                // O child do botão agora é fixo
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
                      // Navegação para a tela de cadastro
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
    );
  }
}
