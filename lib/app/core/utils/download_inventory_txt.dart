import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/views/inventory/down_inventory_dialog.dart';

class DownloadInventoryUtility {
  
  static Future<bool> exportToTxt(BuildContext context, InventoryModel inventory) async {
    try {
      // 1. Abre o diálogo para perguntar quais colunas exportar
      final selectedColumns = await showDialog<List<String>>(
        context: context,
        builder: (_) => DownloadInventoryDialog(
          inventoryCode: inventory.inventCode ?? '',
        ),
      );

      // Se o usuário cancelou ou desmarcou tudo, interrompe sem abrir o loading
      if (selectedColumns == null || selectedColumns.isEmpty) {
        MessageService.showError("Selecione pelo menos uma coluna.");
        return false;
      }

      final inventoryService = context.read<InventoryService>();
      final loadingService = context.read<LoadingService>();

      // Ativa o indicador de progresso após a confirmação das colunas
      loadingService.show();

      try {
        // 2. Busca os registros diretamente da tabela local via Drift database
        final localRecords = await inventoryService.database.getRecordsByInventory(inventory.inventCode ?? '');
        
        if (localRecords.isEmpty) {
          if (context.mounted) {
            MessageService.showError("Este inventário não possui registros locais para exportar.");
          }
          return false;
        }

        final StringBuffer buffer = StringBuffer();

        // 3. Itera sobre os registros locais montando dinamicamente apenas as colunas escolhidas
        for (var record in localRecords) {
          // Só busca a descrição no banco se a coluna "Nome do Produto" foi solicitada
          String productName = 'PRODUTO NAO ENCONTRADO';
          if (selectedColumns.contains('productDescription')) {
            final product = await inventoryService.searchProductLocallyByCode(record.inventProduct);
            productName = product?.productName ?? 'PRODUTO NAO ENCONTRADO';
          }

          // Mapeia dinamicamente as propriedades do registro local com as chaves do Dialog
          final Map<String, dynamic> jsonMap = {
            "inventUnitizer": record.inventUnitizer,
            "inventLocation": record.inventLocation,
            "inventBarcode": record.inventBarcode,
            "inventProduct": record.inventProduct,
            "productDescription": productName,
            "inventStandardStack": record.inventStandardStack,
            "inventQtdStack": record.inventQtdStack,
            "inventQtdIndividual": record.inventQtdIndividual,
            "inventTotal": record.inventTotal,
            "inventUser": record.inventUser,
          };

          final line = selectedColumns.map((col) {
            final value = jsonMap[col];
            if (value == null) return "";
            
            String strValue = value.toString();
            
            // Remove o zero à esquerda apenas na penúltima coluna da seleção atual
            final colIndex = selectedColumns.indexOf(col);
            if (colIndex == selectedColumns.length - 2) {
              strValue = strValue.replaceFirst(RegExp(r'^0+'), '');
            }
            
            return strValue;
          }).join(";");

          // Escreve a linha e injeta explicitamente o sufixo Windows CRLF (\r\n)
          buffer.write(line);
          buffer.write('\r\n');
        }

        // 4. Cria o arquivo temporário físico no dispositivo
        final directory = await getTemporaryDirectory();
        final fileName = '${inventory.inventCode}.txt';
        final file = File('${directory.path}/$fileName');

        // 5. Grava em Latin1 (ISO-8859-1) para evitar quebras de acentuação no Windows
        await file.writeAsString(buffer.toString(), encoding: latin1);

        // 6. Abre o menu nativo de compartilhamento/salvamento do arquivo
        final xFile = XFile(file.path, mimeType: 'text/plain');
        await Share.shareXFiles(
          [xFile],
          subject: 'Exportação Local do Inventário ${inventory.inventCode}',
          text: 'Segue em anexo o arquivo TXT da contagem: ${inventory.inventCode}.',
        );

        MessageService.showSuccess(
          "Download do inventário ${inventory.inventCode} concluído!",
        );
        return true;

      } catch (e) {
        if (context.mounted) {
          MessageService.showError("Falha ao gerar arquivo de exportação: $e");
        }
        return false;
      } finally {
        // Garante que o loading feche independentemente de sucesso ou erro
        loadingService.hide();
      }

    } catch (outerError) {
      MessageService.showError("Falha ao processar o diálogo de download.");
      return false;
    }
  }
}