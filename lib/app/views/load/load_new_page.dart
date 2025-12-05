import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oxdata/app/core/models/pallet_load_head_model.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class LoadNewPage extends StatefulWidget {
  const LoadNewPage({super.key});

  @override
  State<LoadNewPage> createState() => _LoadNewPageState();
}

class _LoadNewPageState extends State<LoadNewPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _description = '';
  String _status = '';
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  PalletLoadHeadModel? _initialLoad;
  String _initialStatus = 'Carregando';

  final List<String> _statusOptions = [
    'Carregando',
    'Carga Finalizada',
    'Recebido',
    'Finalizado',
  ];

  List<String> get _allowedStatusOptions {
    if (_status.isEmpty) return _statusOptions;
    final initialIndex = _statusOptions.indexOf(_status);
    if (initialIndex == -1) return _statusOptions;
    return _statusOptions.sublist(initialIndex);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final load = context.read<LoadService>().selectedLoadForEdit;
    if (load == _initialLoad) return;

    setState(() {
      _initialLoad = load;
      if (load != null) {
        _name = load.name;
        _description = load.description ?? '';
        _status = load.status;
        _initialStatus = load.status;
        _selectedDate = load.date;

        final timeParts = load.time.split(':');
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      } else {

        final now = DateTime.now();
        _name = '';
        _description = '';
        _status = 'Carregando';
        _initialStatus = 'Carregando';
        _selectedDate = now;
        _selectedTime = TimeOfDay.fromDateTime(now);
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final currentStatusIndex = _statusOptions.indexOf(_status);
      final initialStatusIndex = _statusOptions.indexOf(_initialStatus);

      if (currentStatusIndex < initialStatusIndex) {
        MessageService.showError('Não é permitido retroceder a situação da carga.');
        return;
      }

      final storage = StorageService();
      final creds = await storage.readCredentials();

      final int loadId = _initialLoad?.loadId ?? 0;
      final String action = loadId == 0 ? 'salva' : 'atualizada';

      final newLoad = PalletLoadHeadModel(
        loadId: loadId,
        name: _name,
        description: _description,
        status: _status,
        date: _selectedDate,
        time:
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00',
        createdUser: creds['username'],
      );

      try {
        await context.read<LoadService>().upsertLoadHeads([newLoad]);
        MessageService.showSuccess('Carga $action com sucesso!');

        if (loadId != 0) {
          context.read<LoadService>().setSelectedLoadForEdit(newLoad);
          setState(() => _initialStatus = newLoad.status);
        }
      } catch (e) {
        MessageService.showError('Falha ao $action a carga.');
        context.read<LoadService>().setSelectedLoadForEdit(null);
      }
    }
  }

  void _startNewLoad() {
    context.read<LoadService>().setSelectedLoadForEdit(null);
    final now = DateTime.now();

    setState(() {
      _initialLoad = null;
      _name = '';
      _description = '';
      _status = 'Carregando';
      _initialStatus = 'Carregando';
      _selectedDate = now;
      _selectedTime = TimeOfDay.fromDateTime(now);
    });

    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final loadService = context.watch<LoadService>();
    final isEditing = loadService.selectedLoadForEdit != null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.teal.shade50,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
          child: Column(
            children: [
              /// HEADER ----------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isEditing
                          ? Icons.drive_file_rename_outline
                          : Icons.library_add_rounded,
                      size: 34,
                      color: Colors.teal.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Editar Carga' : 'Cadastrar Nova Carga',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                    if (isEditing)
                      IconButton(
                        onPressed: _startNewLoad,
                        icon: Icon(
                          Icons.add_box_outlined,
                          color: Colors.teal.shade700,
                          size: 32,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// FORM CARD -------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Nome da Carga',
                        icon: Icons.label_outline,
                        initialValue: _name,
                        onSaved: (v) => _name = v!,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Por favor, insira o nome da carga.'
                            : null,
                      ),

                      const SizedBox(height: 18),

                      _buildTextField(
                        label: 'Descrição da Carga (Opcional)',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        initialValue: _description,
                        onSaved: (v) => _description = v ?? '',
                      ),

                      const SizedBox(height: 18),

                      DropdownButtonFormField<String>(
                        value: _status.isEmpty ? null : _status,
                        items: _allowedStatusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        decoration: _buildInputDecoration(
                          'Situação',
                          Icons.flag_outlined,
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Selecione a situação.' : null,
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: _buildInputDecoration(
                                  'Data *', Icons.calendar_today),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InputDecorator(
                              decoration: _buildInputDecoration(
                                  'Hora *', Icons.access_time),
                              child: Text(
                                _selectedTime.format(context),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),

      /// BOTÕES ---------------------------------------------------------
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        child: Row(
          children: [
            Expanded(
              child: _buildBottomButton(
                label: 'NOVO',
                color: Colors.blueGrey.shade600,
                onTap: _startNewLoad,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBottomButton(
                label: 'SALVAR',
                color: Colors.teal.shade600,
                onTap: () async {
                  final loadingService = context.read<LoadingService>();
                  try {
                    loadingService.show();
                    await _submitForm();
                  } finally {
                    loadingService.hide();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            if (isEditing)
              Expanded(
                child: _buildBottomButton(
                  label: 'EXCLUIR',
                  color: Colors.red.shade700,
                  onTap: () async {
                    final loadIdToDelete = _initialLoad?.loadId;

                    if (loadIdToDelete != null && loadIdToDelete > 0) {
                      final loadingService = context.read<LoadingService>();
                      try {
                        loadingService.show();
                        var sucesso =
                            await loadService.deleteLoadHead(loadIdToDelete);

                        if (sucesso) {
                          MessageService.showSuccess('Carga removida com sucesso!');
                          _startNewLoad();
                        } else {
                          MessageService.showError(
                              'Não foi possível excluir a carga. Verifique o status e as linhas.');
                        }
                      } finally {
                        loadingService.hide();
                      }
                    } else {
                      MessageService.showWarning(
                        'Impossível excluir. A carga não foi salva ou não foi identificada.',
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ---------------------------------- WIDGETS AUXILIARES ----------------------------------

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String initialValue,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: _buildInputDecoration(label, icon),
      validator: validator,
      onSaved: onSaved,
      maxLines: maxLines,
      inputFormatters: [
        TextInputFormatter.withFunction(
          (oldValue, newValue) => newValue.copyWith(
            text: newValue.text.toUpperCase(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 3,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.teal.shade600,
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: Icon(icon, color: Colors.teal.shade400),

      /// CONTRASTE DOS CAMPOS
      filled: true,
      fillColor: Colors.grey.shade100,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: Colors.teal.shade600,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 12,
      ),
    );
  }
}


/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oxdata/app/core/models/pallet_load_head_model.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class LoadNewPage extends StatefulWidget {
  const LoadNewPage({super.key});

  @override
  State<LoadNewPage> createState() => _LoadNewPageState();
}

class _LoadNewPageState extends State<LoadNewPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _description = '';
  String _status = '';
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  PalletLoadHeadModel? _initialLoad;

  final List<String> _statusOptions = [
    'Carregando',
    'Carga Finalizada',
    'Recebido',
    'Finalizado',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final load = context.read<LoadService>().selectedLoadForEdit;
    if (load == _initialLoad) return;

    setState(() {
      _initialLoad = load;
      if (load != null) {
        _name = load.name;
        _description = load.description ?? '';
        _status = load.status;
        _selectedDate = load.date;

        final timeParts = load.time.split(':');
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      } else {
        final now = DateTime.now();
        _name = '';
        _description = '';
        _status = 'Carregando';
        _selectedDate = now;
        _selectedTime = TimeOfDay.fromDateTime(now);
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final storage = StorageService();
      final creds = await storage.readCredentials();

      final int loadId = _initialLoad?.loadId ?? 0;
      final String action = loadId == 0 ? 'salva' : 'atualizada';

      final newLoad = PalletLoadHeadModel(
        loadId: loadId,
        name: _name,
        description: _description,
        status: _status,
        date: _selectedDate,
        time:
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00',
        createdUser: creds['username'],
      );

      try {
        await context.read<LoadService>().upsertLoadHeads([newLoad]);

        MessageService.showSuccess('Carga $action com sucesso!');

        if (loadId != 0)
        {
          context.read<LoadService>().setSelectedLoadForEdit(newLoad);
        }
        
      } catch (e) {
        MessageService.showError('Falha ao $action a carga.');
        context.read<LoadService>().setSelectedLoadForEdit(null);
      }
    }
  }

  void _startNewLoad() {
    context.read<LoadService>().setSelectedLoadForEdit(null);
    final now = DateTime.now();

    setState(() {
      _initialLoad = null;
      _name = '';
      _description = '';
      _selectedDate = now;
      _selectedTime = TimeOfDay.fromDateTime(now);
    });

    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final loadService = context.watch<LoadService>();
    final isEditing = loadService.selectedLoadForEdit != null;

    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ teclado não empurra o bottomNavigationBar
      backgroundColor: Colors.teal.shade50,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 10,
                right: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isEditing
                                    ? Icons.drive_file_rename_outline
                                    : Icons.library_add_rounded,
                                size: 32,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isEditing
                                    ? 'Editar Carga'
                                    : 'Cadastrar Nova Carga',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (isEditing)
                            IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: _startNewLoad,
                              icon: Icon(
                                Icons.add_box_outlined,
                                size: 32,
                                color: Colors.teal.shade700,
                              ),
                              tooltip: 'Cadastrar Nova Carga',
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        initialValue: _name,
                        decoration: _buildInputDecoration(
                            'Nome da Carga', Icons.label_outline),
                        maxLength: 100,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor, insira o nome da carga.'
                            : null,
                        onSaved: (value) => _name = value!,
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) => newValue.copyWith(
                                text: newValue.text.toUpperCase()),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        initialValue: _description,
                        decoration: _buildInputDecoration(
                          'Descrição da Carga (Opcional)',
                          Icons.description_outlined,
                        ),
                        maxLines: 3,
                        onSaved: (value) => _description = value ?? '',
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) => newValue.copyWith(
                                text: newValue.text.toUpperCase()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: _status.isEmpty ? null : _status,
                        items: _statusOptions
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        decoration: _buildInputDecoration(
                          'Situação',
                          Icons.flag_outlined,
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _status = value;
                            });
                          }
                        },
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Selecione a situação.' : null,
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: _buildInputDecoration(
                                  'Data *', Icons.calendar_today),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: InputDecorator(
                              decoration: _buildInputDecoration(
                                  'Hora *', Icons.access_time),
                              child: Text(
                                _selectedTime.format(context),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _startNewLoad,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'NOVO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final loadingService = context.read<LoadingService>();
                  try {
                    loadingService.show();
                    await _submitForm();
                  } finally {
                    loadingService.hide();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  'SALVAR',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            if (isEditing)
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final loadIdToDelete = _initialLoad?.loadId;

                    if (loadIdToDelete != null && loadIdToDelete > 0) {
                      final loadingService = context.read<LoadingService>();

                      try {
                        loadingService.show();
                        var sucesso =
                            await loadService.deleteLoadHead(loadIdToDelete);

                        if (sucesso) {
                          MessageService.showSuccess(
                              'Carga removida com sucesso!');
                          _startNewLoad();
                        } else {
                          MessageService.showError(
                              'Não foi possível excluir a carga. Verifique o status e as linhas.');
                        }
                      } catch (e) {
                        MessageService.showError(
                            'Erro de conexão ao tentar excluir a carga.');
                      } finally {
                        loadingService.hide();
                      }
                    } else {
                      MessageService.showWarning(
                          'Impossível excluir. A carga não foi salva ou não foi identificada.');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'EXCLUIR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.teal.shade600,
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: Icon(icon, color: Colors.teal.shade400),
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(
          color: Colors.teal.shade600,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18.0,
        horizontal: 10.0,
      ),
    );
  }
}
*/