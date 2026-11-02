import 'dart:async';
import 'dart:convert';

import 'package:consulta_cnpj/screens/consulta_page.dart';
import 'package:consulta_cnpj/services/brasil_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'valida entrada, consulta com máscara e impede consultas duplicadas',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final resposta = Completer<http.Response>();
      var chamadas = 0;
      final servico = BrasilApiService(
        client: MockClient((request) {
          chamadas++;
          expect(request.url.path, '/api/cnpj/v1/00000000000191');
          return resposta.future;
        }),
      );
      addTearDown(servico.fechar);
      await tester.pumpWidget(
        MaterialApp(home: ConsultaPage(servico: servico)),
      );
      await tester.tap(find.text('Consultar CNPJ'));
      await tester.pumpAndSettle();
      expect(find.text('Informe um CNPJ com 14 números.'), findsOneWidget);
      expect(chamadas, 0);

      await tester.enterText(find.byType(TextFormField), '00.000.000/0001-91');
      await tester.tap(find.text('Consultar CNPJ'));
      await tester.pump();
      expect(find.text('Consultando...'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(chamadas, 1);

      resposta.complete(
        http.Response(
          jsonEncode({
            'cnpj': '00000000000191',
            'razao_social': 'BANCO DO BRASIL SA',
            'nome_fantasia': '',
            'descricao_situacao_cadastral': 'ATIVA',
            'data_inicio_atividade': '1966-08-01',
          }),
          200,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('BANCO DO BRASIL SA'), findsOneWidget);
      expect(find.text('ATIVA'), findsOneWidget);
      expect(find.text('01/08/1966'), findsOneWidget);
      expect(find.text('Não informado'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.pump();
      expect(find.text('BANCO DO BRASIL SA'), findsNothing);
    },
  );

  testWidgets('mostra erro da API e permite nova consulta', (tester) async {
    var chamadas = 0;
    final servico = BrasilApiService(
      client: MockClient((_) async {
        chamadas++;
        return http.Response('{}', 404);
      }),
    );
    addTearDown(servico.fechar);
    await tester.pumpWidget(MaterialApp(home: ConsultaPage(servico: servico)));
    await tester.enterText(find.byType(TextFormField), '11111111111111');
    await tester.tap(find.text('Consultar CNPJ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('CNPJ não encontrado'), findsOneWidget);
    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(chamadas, 2);
    expect(tester.takeException(), isNull);
  });
}
