// app/core/widgets/update_dialog.dart

/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, _) {
        final update = updateService.remoteUpdate;
        if (update == null) return const SizedBox.shrink();

        final isDownloading = updateService.status == UpdateStatus.downloading;
        final isDownloaded = updateService.status == UpdateStatus.downloaded;

        return AlertDialog(
          title: const Text('Atualização disponível'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nova versão: ${update.versionName}'),
              const SizedBox(height: 8),
              if (update.releaseNotes.isNotEmpty) Text(update.releaseNotes),
              const SizedBox(height: 16),
              if (isDownloading) ...[
                LinearProgressIndicator(value: updateService.progress),
                const SizedBox(height: 8),
                Text('${(updateService.progress * 100).toInt()}%'),
              ],
              if (updateService.status == UpdateStatus.error &&
                  updateService.errorMessage != null)
                Text(
                  updateService.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
          actions: [
            if (!isDownloading && !isDownloaded)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Depois'),
              ),
            if (!isDownloading && !isDownloaded)
              ElevatedButton(
                onPressed: () => updateService.downloadUpdate(),
                child: const Text('Atualizar'),
              ),
            if (isDownloaded)
              ElevatedButton(
                onPressed: () => updateService.installUpdate(),
                child: const Text('Instalar'),
              ),
          ],
        );
      },
    );
  }
}
*/

// app/core/widgets/update_dialog.dart
 
// app/core/widgets/update_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, _) {
        final update = updateService.remoteUpdate;
        if (update == null) return const SizedBox.shrink();

        final isDownloading = updateService.status == UpdateStatus.downloading;
        final isDownloaded = updateService.status == UpdateStatus.downloaded;
        final hasError = updateService.status == UpdateStatus.error &&
            updateService.errorMessage != null;

        return AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.cyanAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Colors.cyanAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ATUALIZAÇÃO DISPONÍVEL',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'NOVA VERSÃO',
                value: update.versionName,
                icon: Icons.new_releases_outlined,
              ),
              if (update.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 14),
                _InfoRow(
                  label: 'NOTAS DA VERSÃO',
                  value: update.releaseNotes,
                  icon: Icons.article_outlined,
                  maxLines: 4,
                ),
              ],
              if (isDownloading) ...[
                const SizedBox(height: 18),
                _DownloadProgress(progress: updateService.progress),
              ],
              if (hasError) ...[
                const SizedBox(height: 14),
                _ErrorRow(message: updateService.errorMessage!),
              ],
            ],
          ),
          actions: <Widget>[
            if (!isDownloading && !isDownloaded)
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'DEPOIS',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            if (!isDownloading && !isDownloaded)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.12),
                  foregroundColor: Colors.cyanAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Colors.cyanAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () => updateService.downloadUpdate(),
                child: const Text(
                  'ATUALIZAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            if (isDownloaded)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.withValues(alpha: 0.12),
                  foregroundColor: Colors.greenAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Colors.greenAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () => updateService.installUpdate(),
                child: const Text(
                  'INSTALAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// LINHA DE INFORMAÇÃO (uso interno deste arquivo)
// ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final int maxLines;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PROGRESSO DE DOWNLOAD (uso interno deste arquivo)
// ─────────────────────────────────────────────────────────────────

class _DownloadProgress extends StatelessWidget {
  final double progress;

  const _DownloadProgress({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.downloading_rounded,
                color: Colors.cyanAccent,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Text(
                'BAIXANDO ATUALIZAÇÃO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Colors.white38,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// LINHA DE ERRO (uso interno deste arquivo)
// ─────────────────────────────────────────────────────────────────

class _ErrorRow extends StatelessWidget {
  final String message;

  const _ErrorRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}