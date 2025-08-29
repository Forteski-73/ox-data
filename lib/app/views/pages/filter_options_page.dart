import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:oxdata/app/views/pages/filter_attribute_oxford.dart';

class FilterOptionsPage extends StatefulWidget {
  final Map<String, String> filterDisplayNames;
  final String currentFilterType;
  final Function(String) onFilterSelected;

  const FilterOptionsPage({
    Key? key,
    required this.filterDisplayNames,
    required this.currentFilterType,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  State<FilterOptionsPage> createState() => _FilterOptionsPageState();
}

class _FilterOptionsPageState extends State<FilterOptionsPage>
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _controllers = {};
  final Map<String, Animation<double>> _animations = {};

  @override
  void initState() {
    super.initState();
    final keys = widget.filterDisplayNames.keys.toList();
    final ignoredKeys = ['brandId', 'lineId', 'decorationId'];
    final filteredKeys = keys.where((key) => !ignoredKeys.contains(key)).toList();

    // Inicializa controllers e animações individuais para cada item
    for (var key in filteredKeys) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
      );
      final animation = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
      _controllers[key] = controller;
      _animations[key] = animation;
    }
  }

  Future<void> _triggerPulse(String key) async {
    final controller = _controllers[key];
    if (controller != null) {
      await controller.forward();
      await controller.reverse();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.filterDisplayNames.keys.toList();
    final ignoredKeys = ['brandId', 'lineId', 'decorationId'];
    final filteredKeys = keys.where((key) => !ignoredKeys.contains(key)).toList();

    return Scaffold(
      appBar: const AppBarCustom(title: 'Filtrar Por'),
      body: ListView.builder(
        itemCount: filteredKeys.length,
        itemBuilder: (context, index) {
          final key = filteredKeys[index];
          final isSelected = key == widget.currentFilterType;
          final animation = _animations[key]!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: ScaleTransition(
                  scale: animation,
                  child: Container(
                    clipBehavior: Clip.antiAlias, // <-- garante o recorte pelos cantos
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green.withOpacity(0.2)
                          : const Color(0xFFE8ECEF),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material( // <-- material para o ripple respeitar o raio
                      type: MaterialType.transparency,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        title: Text(
                          widget.filterDisplayNames[key] ?? key,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        trailing: (key == "oxfordAtt")
                            ? Icon(
                                Icons.arrow_forward_ios,
                                color: isSelected ? Colors.green : Colors.indigo,
                                size: 22,
                              )
                            : null,
                        onTap: () async {
                          await _triggerPulse(key); // efeito de pulsar

                          if (key == "oxfordAtt") {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FilterAttributeOxford(),
                              ),
                            );
                            if (result != null) {
                              Navigator.of(context).pop(result);
                            }
                          } else {
                            widget.onFilterSelected(key);
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(
                height: 1,
                color: Colors.transparent,
              ),
            ],
          );
        },
      ),
    );
  }
}


/*
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:oxdata/app/views/pages/filter_attribute_oxford.dart';

class FilterOptionsPage extends StatefulWidget {
  final Map<String, String> filterDisplayNames;
  final String currentFilterType;
  final Function(String) onFilterSelected;

  const FilterOptionsPage({
    Key? key,
    required this.filterDisplayNames,
    required this.currentFilterType,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  State<FilterOptionsPage> createState() => _FilterOptionsPageState();
}

class _FilterOptionsPageState extends State<FilterOptionsPage>
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _controllers = {};
  final Map<String, Animation<double>> _animations = {};

  @override
  void initState() {
    super.initState();
    final keys = widget.filterDisplayNames.keys.toList();
    final ignoredKeys = ['brandId', 'lineId', 'decorationId'];
    final filteredKeys = keys.where((key) => !ignoredKeys.contains(key)).toList();

    // Inicializa controllers e animações individuais para cada item
    for (var key in filteredKeys) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
      );
      final animation = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
      _controllers[key] = controller;
      _animations[key] = animation;
    }
  }

  Future<void> _triggerPulse(String key) async {
    final controller = _controllers[key];
    if (controller != null) {
      await controller.forward();
      await controller.reverse();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.filterDisplayNames.keys.toList();
    final ignoredKeys = ['brandId', 'lineId', 'decorationId'];
    final filteredKeys = keys.where((key) => !ignoredKeys.contains(key)).toList();

    return Scaffold(
      appBar: const AppBarCustom(title: 'Filtrar Por'),
      body: ListView.builder(
        itemCount: filteredKeys.length,
        itemBuilder: (context, index) {
          final key = filteredKeys[index];
          final isSelected = key == widget.currentFilterType;
          final animation = _animations[key]!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: ScaleTransition(
                  scale: animation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green.withOpacity(0.2)
                          : const Color(0xFFE8ECEF),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      title: Text(
                        widget.filterDisplayNames[key] ?? key,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      trailing: (key == "oxfordAtt")
                          ? Icon(
                              Icons.arrow_forward_ios,
                              color: isSelected ? Colors.green : Colors.indigo,
                              size: 22,
                            )
                          : null,
                      onTap: () async {
                        await _triggerPulse(key); // efeito de pulsar

                        if (key == "oxfordAtt") {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const FilterAttributeOxford(),
                            ),
                          );
                          if (result != null) {
                            Navigator.of(context).pop(result);
                          }
                        } else {
                          widget.onFilterSelected(key);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const Divider(
                height: 1,
                color: Colors.transparent,
              ),
            ],
          );
        },
      ),
    );
  }
}
*/