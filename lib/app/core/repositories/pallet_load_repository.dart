// app/core/repositories/load_head_repository.dart

import 'dart:convert';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/pallet_load_head_model.dart';
import 'package:oxdata/app/core/models/pallet_load_line_model.dart';
import 'package:oxdata/app/core/models/pallet_load_item_model.dart';
//import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

/// Repositório responsável pela comunicação com a API de Cabeçalhos de Carga (LoadHeadController).
class LoadRepository {
  final ApiClient apiClient;

  LoadRepository({required this.apiClient});

  // =================================== GET ===================================

  /// Busca todos os cabeçalhos de carga na API.
  /// Rota: GET v1/PalletLoadHead
  Future<ApiResponse<List<PalletLoadHeadModel>>> getAllLoadHeads() async {
    try {
      // Usamos getAuth pois a rota está protegida
      final response = await apiClient.getAuth(ApiRoutes.palletLoad);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        
        // Mapeia a lista de JSON para a lista de PalletLoadHeadModel
        final List<PalletLoadHeadModel> loadHeads = jsonList
            .map((json) => PalletLoadHeadModel.fromMap(json as Map<String, dynamic>))
            .toList();
            
        return ApiResponse(success: true, data: loadHeads);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar cargas: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de cargas: $e',
      );
    }
  }

// =================================== GET PALLETS POR LOADID ===================================

  /// Busca todos os pallets de uma carga específica.
  /// Rota: GET v1/PalletLoad/Pallets/{loadId}
  Future<ApiResponse<List<PalletLoadLineModel>>> getPalletsByLoadId(int loadId) async {
    try {
      // Monta a URL com o loadId
      final String url = '${ApiRoutes.palletLoad}/Pallets/$loadId';

      // Faz a requisição autenticada
      final response = await apiClient.getAuth(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);

        // Mapeia para lista de PalletLoadLineModel
        final List<PalletLoadLineModel> pallets = jsonList
            .map((json) => PalletLoadLineModel.fromMap(json as Map<String, dynamic>))
            .toList();

        return ApiResponse(success: true, data: pallets);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar pallets: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de pallets: $e',
      );
    }
  }


  // ================================== POST (UPSERT) ==================================

  /// Insere ou atualiza uma lista de cabeçalhos de carga na API.
  /// Rota: POST v1/PalletLoadHead
  Future<ApiResponse<List<int>>> upsertLoadHeads(List<PalletLoadHeadModel> loadHeads) async {
    if (loadHeads.isEmpty) {
      return ApiResponse(success: false, message: 'Nenhuma carga fornecida para salvar.', data: []);
    }

    try {
      final List<Map<String, dynamic>> requestBody = loadHeads.map((head) => head.toMap()).toList();

      final response = await apiClient.postAuth1(
        ApiRoutes.palletLoad,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseBody = json.decode(response.body);

          final List<int> loadIds = (responseBody['loadIds'] as List<dynamic>?)
              ?.cast<int>() // Garante que a lista seja de inteiros
              ?? [];

          return ApiResponse(
            success: true,
            data: loadIds,
            message: responseBody['message'] ?? 'Cargas salvas com sucesso.',
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            data: [],
            message: 'Cargas salvas, mas falha ao processar a resposta do servidor: $e',
          );
        }
      } else {
        String errorMessage = 'Erro ao salvar cargas: ${response.statusCode}';
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['title'] ?? errorBody['message'] ?? errorMessage;
        } catch (e) {
          // Ignora erro de parsing
        }
        
        return ApiResponse(
          success: false,
          data: [], 
          message: errorMessage,
        );
      }
    } on Exception catch (e) {
      // FALHA DE CONEXÃO
      return ApiResponse(
        success: false,
        data: [], 
        message: 'Falha na conexão ao salvar cargas: $e',
      );
    }
  }

  // ================================== POST PALLET LINE ==================================

  /// Adiciona um único pallet (linha de carga) a uma carga existente na API.
  Future<ApiResponse<int>> addPalletToLoad(PalletLoadLineModel pallet) async {
    try {
      final requestBody = pallet.toApiMap();

      final response = await apiClient.postAuth(
        ApiRoutes.palletLoadLine,
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {};

        final bool allPalletsLoaded = data['allPalletsLoaded'] ?? false;

        return ApiResponse(
          success: true,
          message: allPalletsLoaded
              ? 'Pallet adicionado e todos os pallets da carga estão carregados.'
              : 'Pallet adicionado ou já existente na carga.',
          data: allPalletsLoaded ? 2 : 1, // 2 = todos carregados, 1 = só sucesso
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Carga ou pallet não encontrados.',
          data: 0,
        );
      } else if (response.statusCode == 400) {
        return ApiResponse(
          success: false,
          message: 'Requisição inválida (verifique os dados enviados).',
          data: 0,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao adicionar pallet: ${response.statusCode}',
          data: 0,
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na conexão ao adicionar pallet: $e',
        data: 0,
      );
    }
  }

    /// Atualiza o status de uma carga na API.
  Future<bool> updateLoadStatus(int loadId, String status) async {
    try {
      final url = '${ApiRoutes.palletLoadUp}?loadId=$loadId&status=$status';

      final response = await apiClient.putAuth(url);

      // Se statusCode 200 → sucesso, qualquer outro → erro
      return response.statusCode == 200;
    } catch (_) {
      // Qualquer exceção é considerada erro
      return false;
    }
  }

  // =================================== GET RECEBER===================================

  /// 🆕 Busca um cabeçalho de carga específico pelo ID.
  /// Rota: GET v1/PalletLoadHead/{loadId}
  Future<ApiResponse<PalletLoadHeadModel?>> getLoadHeadById(int loadId) async {
    try {
      final String url = '${ApiRoutes.palletLoad}/$loadId';
      final response = await apiClient.getAuth(url);

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final Map<String, dynamic> jsonMap = json.decode(response.body);
          final PalletLoadHeadModel loadHead = PalletLoadHeadModel.fromMap(jsonMap);
          return ApiResponse(success: true, data: loadHead);
        }
        return ApiResponse(success: true, data: null, message: 'Carga não encontrada.');
      } else if (response.statusCode == 404) {
        return ApiResponse(success: true, data: null, message: 'Carga não encontrada (404).');
      } else {
        return ApiResponse(
          success: false,
          data: null,
          message: 'Erro ao buscar carga $loadId: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição da carga: $e',
      );
    }
  }

  /// 🆕 Busca os detalhes e itens de um palete específico em uma carga.
  /// Assumindo Rota: GET v1/PalletLoad/PalletItems/{loadId}/{palletId}
  Future<ApiResponse<PalletDetailsModel>> getPalletItemsByPalletId(
      int loadId, int palletId) async { // palletId alterado para int
    try {
      // Ajuste a URL para o seu endpoint real.
      // Usando a rota original que você forneceu:
      final String url = '${ApiRoutes.palletLoad}/PalletItems/$loadId/$palletId';

      final response = await apiClient.getAuth(url);

      if (response.statusCode == 200) {
        // O body é um ÚNICO objeto (PalletDetailsModel), não uma lista.
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        // Mapeia o objeto JSON principal para o PalletDetailsModel.
        final PalletDetailsModel details = PalletDetailsModel.fromMap(jsonMap);

        // Retorna o objeto completo, que já contém a lista de itens.
        return ApiResponse(success: true, data: details);
      } else {
        String errorMessage = 'Erro ao buscar itens do palete $palletId: ${response.statusCode}';
        
        // Tenta decodificar a mensagem de erro se houver
        try {
          errorMessage = json.decode(response.body)['message'] ?? errorMessage;
        } catch (_) {} 

        return ApiResponse(
          success: false,
          data: null, // Retornamos null para o dado em caso de falha
          message: errorMessage,
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        data: null,
        message: 'Falha na requisição dos itens do palete: $e',
      );
    }
  }

  /// Envia os itens do palete e suas quantidades recebidas para a API.
  /// Rota assumida: POST v1/PalletLoad/ReceiveItems
  Future<ApiResponse<bool>> savePalletReception({
    required int loadId,
    required int palletId,
    required List<PalletItemModel> items,
  }) async {
    try {
      // 1. Mapeia a lista de PalletItemModel para um formato simplificado de envio.
      // Assumindo que a API só precisa dos campos de identificação e a quantidade recebida.
      final List<Map<String, dynamic>> requestBody = items.map((item) => {
        'LoadId': loadId, // Inclui o LoadId em cada item para redundância/segurança
        'PalletId': palletId, // Inclui o PalletId
        'ProductId': item.productId, // O ID do produto/peça
        'QuantityReceived': item.quantityReceived, // A quantidade preenchida
      }).toList();

      // 2. Define a rota para o recebimento.
      // Sugestão de rota: '${ApiRoutes.palletLoad}/ReceiveItems'
      final String url = ApiRoutes.palletLoadReceiveLine;

      // 3. Envia a requisição POST com autenticação (postAuth é o mais adequado)
      final response = await apiClient.putAuth(
        url,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        // Sucesso na operação
        return ApiResponse(success: true, data: true, message: 'Recebimento salvo com sucesso.');
      } else {
        // Falha na API
        String errorMessage = 'Erro ao salvar recebimento do Palete $palletId: ${response.statusCode}';
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {} 

        return ApiResponse(
          success: false,
          data: false,
          message: errorMessage,
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        data: false,
        message: 'Falha na conexão ao salvar recebimento: $e',
      );
    }
  }

  // =================================== DELETE ===================================

  /// Exclui um pallet (PalletLoadLine) de uma carga específica.
  /// Rota: DELETE v1/PalletLoad/Pallet/{loadId}/{palletId}
  Future<ApiResponse<bool>> deletePalletFromLoad(int loadId, int palletId) async {
    try {
      // Monta a URL para o endpoint DELETE
      // Assumindo que ApiRoutes.palletLoad corresponde a 'v1/PalletLoad'
      final String url = '${ApiRoutes.palletLoad}/Pallet/$loadId/$palletId';

      // Faz a requisição DELETE autenticada (presumindo que apiClient tem deleteAuth)
      final response = await apiClient.deleteAuth(url);

      if (response.statusCode == 200) {
        // Sucesso na exclusão
        return ApiResponse(
          success: true,
          data: true,
          message: 'Palete excluído da carga com sucesso.',
        );
      } else if (response.statusCode == 404) {
        // Pallet ou Carga não encontrados
        return ApiResponse(
          success: false,
          data: false,
          message: 'Pallet ou Carga não encontrados (404).',
        );
      } else {
        // Outros erros
        String errorMessage = 'Erro ao excluir palete: ${response.statusCode}';
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {
          // Ignora erro de parsing
        }

        return ApiResponse(
          success: false,
          data: false,
          message: errorMessage,
        );
      }
    } on Exception catch (e) {
      // Falha de conexão
      return ApiResponse(
        success: false,
        data: false,
        message: 'Falha na conexão ao excluir palete: $e',
      );
    }
  }

  // =================================== NOTAS FISCAIS (NF) ===================================

  /// 🆕 Busca todas as Notas Fiscais associadas a um Palete.
  /// Rota assumida: GET v1/PalletLoad/Invoices/{palletId}
  /*Future<ApiResponse<List<String>>> getPalletInvoices(int palletId) async {
    try {
      final String url = '${ApiRoutes.palletLoadInvoices}/$palletId';
      final response = await apiClient.getAuth(url);

      if (response.statusCode == 200) {
        // O JSON decode já retorna List<String> ou List<dynamic>
        // Como a API retorna List<string>, o `json.decode` resultará em List<String>
        final List<dynamic> jsonList = json.decode(response.body);
        
        // A API já está retornando Strings, não precisa de mapeamento ou toString() complexo.
        // Apenas forçamos a tipagem para List<String>.
        final List<String> invoices = jsonList.cast<String>();
        
        return ApiResponse(success: true, data: invoices);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar NFs do palete: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de NFs: $e',
      );
    }
  }*/

  Future<ApiResponse<List<String>>> getLoadInvoices(int loadId) async {
    try {
      // Assumindo a rota 'v1/PalletLoad/LoadInvoices/{loadId}'
      final String url = '${ApiRoutes.palletLoadInvoices}/$loadId'; 
      final response = await apiClient.getAuth(url);

      if (response.statusCode == 200) {
        // A API deve retornar uma lista de strings (números de NF).
        final List<dynamic> jsonList = json.decode(response.body);
        
        // Força a tipagem para List<String>.
        final List<String> invoices = jsonList.cast<String>();
        
        return ApiResponse(success: true, data: invoices);
      } else {
        return ApiResponse(
          success: false,
          data: [],
          message: 'Erro ao buscar NFs da carga: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message: 'Falha na requisição de NFs: $e',
      );
    }
  }

  /// 🆕 Adiciona uma Nota Fiscal a um Palete.
  /// Rota assumida: POST v1/PalletLoad/AddInvoice
  Future<ApiResponse<bool>> addInvoiceToPallet(
      int loadId, 
      String invoiceNumber, 
      String invoiceKey) async {
    try {
      final requestBody = {
        'loadId': loadId, 
        'invoice': invoiceNumber,
        'invoiceKey': invoiceKey,
      };

      final response = await apiClient.postAuth(
        ApiRoutes.palletLoadInvoice,
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(success: true, data: true);
      }
      else {
        String errorMessage = 'Erro ao adicionar NF: ${response.statusCode}';
        try {
          errorMessage = json.decode(response.body)['message'] ?? errorMessage;
        } 
        catch (_) {}

        return ApiResponse(success: false, data: false, message: errorMessage);
      }
    } on Exception catch (e) {
      return ApiResponse(success: false, data: false, message: 'Falha na conexão: $e');
    }
  }

  /// 🆕 Remove uma Nota Fiscal de um Palete.
  /// Rota assumida: DELETE v1/PalletLoad/RemoveInvoice/{palletId}/{invoiceNumber}
  Future<ApiResponse<bool>> removeInvoiceFromPallet(int loadId, String invoiceNumber) async {
    try {
      // Deve-se URL-encode o número da NF
      final encodedInvoice = Uri.encodeComponent(invoiceNumber);
      final String url = '${ApiRoutes.palletLoadInvoice}/$loadId/$encodedInvoice';
      
      final response = await apiClient.deleteAuth(url);

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: true);
      } else {
        String errorMessage = 'Erro ao remover NF: ${response.statusCode}';
        try {
          errorMessage = json.decode(response.body)['message'] ?? errorMessage;
        } catch (_) {}
        return ApiResponse(success: false, data: false, message: errorMessage);
      }
    } on Exception catch (e) {
      return ApiResponse(success: false, data: false, message: 'Falha na conexão: $e');
    }
  }

  /// Exclui o cabeçalho da carga (PalletLoadHead) pelo ID.
  /// Rota assumida: DELETE v1/PalletLoadHead/{loadId}
  Future<ApiResponse<bool>> deleteLoadHead(int loadId) async {
    try {
      // Monta a URL para o endpoint DELETE: v1/PalletLoadHead/{loadId}
      final String url = '${ApiRoutes.palletLoad}/$loadId';

      // Faz a requisição DELETE autenticada
      final response = await apiClient.deleteAuth(url);

      if (response.statusCode == 200) {
        // Sucesso na exclusão (Geralmente 200 ou 204 No Content)
        return ApiResponse(
          success: true,
          data: true,
          message: 'Carga $loadId excluída com sucesso.',
        );
      } else if (response.statusCode == 404) {
        // Carga não encontrada
        return ApiResponse(
          success: false,
          data: false,
          message: 'Carga $loadId não encontrada para exclusão',
        );
      } else {
        // Outros erros
        String errorMessage = 'Erro ao excluir carga $loadId: ${response.statusCode}';
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {
          // Ignora erro de parsing
        }

        return ApiResponse(
          success: false,
          data: false,
          message: errorMessage,
        );
      }
    } on Exception catch (e) {
      // Falha de conexão
      return ApiResponse(
        success: false,
        data: false,
        message: 'Falha na conexão ao excluir a carga: $e',
      );
    }
  }

}