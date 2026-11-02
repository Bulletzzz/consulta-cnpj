import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class BrasilApiService {
  BrasilApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const endereco = 'https://brasilapi.com.br/api/cnpj/v1';

  Future<Map<String, dynamic>> consultarCnpj(String cnpj) async {
    if (!RegExp(r'^\d{14}$').hasMatch(cnpj)) {
      throw const ConsultaException('Informe um CNPJ com 14 números.');
    }
    try {
      final resposta = await _client
          .get(Uri.parse('$endereco/$cnpj'))
          .timeout(const Duration(seconds: 20));

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
        if (dados is! Map<String, dynamic> ||
            dados['cnpj']?.toString() != cnpj ||
            dados['razao_social'] is! String ||
            (dados['razao_social'] as String).trim().isEmpty) {
          throw const ConsultaException(
            'A API retornou dados inesperados. Tente novamente mais tarde.',
          );
        }
        return dados;
      }
      if (resposta.statusCode == 400) {
        throw const ConsultaException(
          'CNPJ inválido. Confira o número digitado.',
        );
      }
      if (resposta.statusCode == 404) {
        throw const ConsultaException(
          'CNPJ não encontrado na base da BrasilAPI. Confira o número informado.',
        );
      }
      if (resposta.statusCode == 429) {
        throw const ConsultaException(
          'Muitas consultas em pouco tempo. Aguarde e tente novamente.',
        );
      }
      throw const ConsultaException(
        'A BrasilAPI está indisponível no momento. Tente novamente mais tarde.',
      );
    } on TimeoutException {
      throw const ConsultaException(
        'A consulta demorou mais que o esperado. Tente novamente.',
      );
    } on http.ClientException {
      throw const ConsultaException(
        'Não foi possível conectar à BrasilAPI. Verifique sua conexão e tente novamente.',
      );
    } on FormatException {
      throw const ConsultaException(
        'A resposta da API não pôde ser lida. Tente novamente mais tarde.',
      );
    }
  }

  void fechar() => _client.close();
}

class ConsultaException implements Exception {
  const ConsultaException(this.mensagem);
  final String mensagem;
}
