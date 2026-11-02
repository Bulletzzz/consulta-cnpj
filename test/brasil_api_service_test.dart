import 'dart:convert';

import 'package:consulta_cnpj/services/brasil_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const cnpj = '00000000000191';

  test('envia GET ao CNPJ solicitado e preserva acentos do JSON', () async {
    final servico = BrasilApiService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), '${BrasilApiService.endereco}/$cnpj');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({'cnpj': cnpj, 'razao_social': 'Empresa de São Paulo'}),
          ),
          200,
        );
      }),
    );
    addTearDown(servico.fechar);
    final dados = await servico.consultarCnpj(cnpj);
    expect(dados['razao_social'], 'Empresa de São Paulo');
  });

  test('entrada inválida não gera requisição', () async {
    var chamadas = 0;
    final servico = BrasilApiService(
      client: MockClient((_) async {
        chamadas++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(servico.fechar);
    await expectLater(
      servico.consultarCnpj('123'),
      throwsA(isA<ConsultaException>()),
    );
    expect(chamadas, 0);
  });

  for (final caso in {
    400: 'inválido',
    404: 'não encontrado',
    429: 'Muitas consultas',
    503: 'indisponível',
  }.entries) {
    test('status ${caso.key} produz mensagem compreensível', () async {
      final servico = BrasilApiService(
        client: MockClient((_) async => http.Response('{}', caso.key)),
      );
      addTearDown(servico.fechar);
      await expectLater(
        servico.consultarCnpj(cnpj),
        throwsA(
          isA<ConsultaException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains(caso.value),
          ),
        ),
      );
    });
  }

  for (final corpo in [
    '<html>erro</html>',
    '[]',
    '{}',
    '{"cnpj":"11111111111111","razao_social":"Outra empresa"}',
  ]) {
    test('rejeita resposta inesperada: $corpo', () async {
      final servico = BrasilApiService(
        client: MockClient((_) async => http.Response(corpo, 200)),
      );
      addTearDown(servico.fechar);
      await expectLater(
        servico.consultarCnpj(cnpj),
        throwsA(isA<ConsultaException>()),
      );
    });
  }

  test('falha de conexão produz mensagem para o usuário', () async {
    final servico = BrasilApiService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    addTearDown(servico.fechar);
    await expectLater(
      servico.consultarCnpj(cnpj),
      throwsA(
        isA<ConsultaException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('conexão'),
        ),
      ),
    );
  });
}
