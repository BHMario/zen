import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/utils/utils.dart';

class EditProjectDialog extends StatefulWidget {
  final Project project;

  const EditProjectDialog({super.key, required this.project});

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedColor;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  final List<String> _colors = [
    '#3B82F6', // Blue
    '#EF4444', // Red
    '#10B981', // Green
    '#F59E0B', // Amber
    '#6366F1', // Indigo
    '#8B5CF6', // Violet
    '#EC4899', // Pink
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(text: widget.project.description);
    _selectedColor = widget.project.color;
    _startDate = widget.project.startDate;
    _endDate = widget.project.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Proyecto'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Proyecto',
                  hintText: 'Ej: Aprender Flutter',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Color Selector
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Color del Proyecto'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final colorHex = _colors[index];
                    final color = ColorUtils.hexToColor(colorHex);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: _selectedColor == colorHex
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Date Pickers
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de Inicio'),
                subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                leading: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de Fin'),
                subtitle: Text(_endDate != null 
                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                    : 'No establecida'),
                leading: const Icon(Icons.event),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProject,
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _saveProject() async {
    if (_nameController.text.isEmpty) return;

    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de fin no puede ser anterior a la de inicio')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedProject = widget.project.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        color: _selectedColor,
        startDate: _startDate,
        endDate: _endDate,
      );

      debugPrint('🚀 Actualizando proyecto: ${updatedProject.name}');
      await context.read<ProjectProvider>().updateProject(updatedProject);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proyecto actualizado correctamente')),
        );
      }
    } catch (e) {
      debugPrint('❌ Error al actualizar proyecto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
