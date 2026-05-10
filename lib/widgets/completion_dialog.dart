import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:zen/services/services.dart';
import 'package:zen/theme/zen_theme.dart';

class CompletionDialog extends StatelessWidget {
  final String itemTypeLabel;
  final String title;
  final DateTime startedAt;
  final DateTime completedAt;
  final String? attachmentUrl;
  final String? attachmentType;

  const CompletionDialog({
    super.key,
    required this.itemTypeLabel,
    required this.title,
    required this.startedAt,
    required this.completedAt,
    this.attachmentUrl,
    this.attachmentType,
  });

  static String _formatDuration(DateTime start, DateTime end) {
    final diff = end.difference(start).abs();
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static Future<void> showSummary(
    BuildContext context, {
    required String itemTypeLabel,
    required String title,
    required DateTime startedAt,
    required DateTime completedAt,
    String? attachmentUrl,
    String? attachmentType,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => CompletionDialog(
        itemTypeLabel: itemTypeLabel,
        title: title,
        startedAt: startedAt,
        completedAt: completedAt,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
      ),
    );
  }

  static Future<Map<String, String?>?> showCelebrationAndAttach(
    BuildContext context, {
    required String itemTypeLabel,
    required String title,
    required DateTime startedAt,
    required DateTime completedAt,
  }) {
    return showDialog<Map<String, String?>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String? uploadedUrl;
        String? uploadedType;
        bool isUploading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickAndUpload() async {
              setState(() => isUploading = true);
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: const [
                    'jpg',
                    'jpeg',
                    'png',
                    'webp',
                    'gif',
                    'mp4',
                    'webm',
                    'mov',
                  ],
                  withData: true,
                );

                if (result == null || result.files.isEmpty) {
                  return;
                }

                final uploaded = await ApiService.uploadAttachment(result.files.first);
                if (uploaded['error'] != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error subiendo archivo: ${uploaded['error']}')),
                    );
                  }
                  return;
                }

                uploadedUrl = uploaded['url'] as String?;
                uploadedType = uploaded['kind'] as String?;
              } finally {
                if (context.mounted) {
                  setState(() => isUploading = false);
                }
              }
            }

            final elapsed = _formatDuration(startedAt, completedAt);

            return AlertDialog(
              title: Text('Enhorabuena: $itemTypeLabel completada'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text('Tiempo invertido: $elapsed'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: isUploading ? null : pickAndUpload,
                      icon: isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(isUploading
                          ? 'Subiendo...'
                          : (uploadedUrl == null
                              ? 'Adjuntar imagen/video (opcional)'
                              : 'Cambiar adjunto')),
                    ),
                    if (uploadedUrl != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        uploadedType == 'video'
                            ? 'Video adjuntado correctamente'
                            : 'Imagen adjuntada correctamente',
                        style: const TextStyle(
                          color: ZenTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Omitir'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'completionAttachmentUrl': uploadedUrl,
                      'completionAttachmentType': uploadedType,
                    });
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _formatDuration(startedAt, completedAt);

    return AlertDialog(
      title: Text('Resumen: $itemTypeLabel completada'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('Tiempo invertido: $elapsed'),
              const SizedBox(height: 8),
              Text('Completada el: ${completedAt.day.toString().padLeft(2, '0')}/${completedAt.month.toString().padLeft(2, '0')}/${completedAt.year}'),
              const SizedBox(height: 16),
              if (attachmentUrl != null) ...[
                Text(
                  attachmentType == 'video' ? 'Video adjunto' : 'Imagen adjunta',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (attachmentType == 'video')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ZenTheme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.videocam_outlined),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Video guardado para este resumen'),
                        ),
                      ],
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      attachmentUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ZenTheme.dividerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('No se pudo cargar la imagen adjunta'),
                      ),
                    ),
                  ),
              ] else
                const Text('No hay imagen/video adjunto para esta finalización.'),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
