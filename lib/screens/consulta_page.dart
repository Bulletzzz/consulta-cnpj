import 'package:flutter/material.dart';

import '../services/brasil_api_service.dart';

class ConsultaPage extends StatefulWidget {
  const ConsultaPage({super.key, this.servico});
  final BrasilApiService? servico;

  @override
  State<ConsultaPage> createState() => _ConsultaPageState();
}

class _ConsultaPageState extends State<ConsultaPage> {
  final _formulario = GlobalKey<FormState>();
  final _cnpjController = TextEditingController();
  late final BrasilApiService _servico;
  Map<String, dynamic>? _empresa;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _servico = widget.servico ?? BrasilApiService();
  }

  @override
  void dispose() {
    _cnpjController.dispose();
    if (widget.servico == null) _servico.fechar();
    super.dispose();
  }

  String _normalizar(String valor) => valor.replaceAll(RegExp(r'[.\-/\s]'), '');

  Future<void> _consultar() async {
    if (_carregando) return;
    FocusScope.of(context).unfocus();
    if (!_formulario.currentState!.validate()) {
      setState(() {
        _empresa = null;
        _erro = null;
      });
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
      _empresa = null;
    });
    try {
      final dados = await _servico.consultarCnpj(
        _normalizar(_cnpjController.text),
      );
      if (!mounted) return;
      setState(() => _empresa = dados);
    } on ConsultaException catch (erro) {
      if (!mounted) return;
      setState(() => _erro = erro.mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _erro = 'Não foi possível concluir a consulta. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _texto(String campo) {
    final valor = _empresa?[campo]?.toString().trim();
    return valor == null || valor.isEmpty ? 'Não informado' : valor;
  }

  String _data(String campo) {
    final valor = _texto(campo);
    final partes = valor.split('-');
    return partes.length == 3
        ? '${partes[2]}/${partes[1]}/${partes[0]}'
        : valor;
  }

  String _cnpjFormatado() {
    final valor = _texto('cnpj');
    if (valor.length != 14) return valor;
    return '${valor.substring(0, 2)}.${valor.substring(2, 5)}.'
        '${valor.substring(5, 8)}/${valor.substring(8, 12)}-${valor.substring(12)}';
  }

  String _logradouro() {
    final partes = ['descricao_tipo_de_logradouro', 'logradouro', 'numero']
        .map((campo) => _empresa?[campo]?.toString().trim() ?? '')
        .where((valor) => valor.isNotEmpty)
        .toList();
    return partes.isEmpty ? 'Não informado' : partes.join(' ');
  }

  Widget _cartao(Widget conteudo) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE1E8E3)),
    ),
    child: conteudo,
  );

  Widget _campo(String rotulo, String valor) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(color: Color(0xFF64736B), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );

  Widget _tituloCartao(IconData icone, String titulo) => Row(
    children: [
      Icon(icone, size: 21, color: const Color(0xFF176B50)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          titulo,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );

  List<Widget> _resultado() {
    final ativa =
        _texto('descricao_situacao_cadastral').toUpperCase() == 'ATIVA';
    return [
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Empresa encontrada',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ativa ? const Color(0xFFE2F3E9) : const Color(0xFFFFF0D7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _texto('descricao_situacao_cadastral'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ativa
                    ? const Color(0xFF176B50)
                    : const Color(0xFF805511),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _cartao(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloCartao(Icons.business_outlined, 'Dados cadastrais'),
            _campo('Razão social', _texto('razao_social')),
            _campo('Nome fantasia', _texto('nome_fantasia')),
            _campo('CNPJ', _cnpjFormatado()),
            _campo('Data de abertura', _data('data_inicio_atividade')),
            _campo('Porte', _texto('porte')),
            _campo('Atividade principal', _texto('cnae_fiscal_descricao')),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _cartao(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloCartao(Icons.location_on_outlined, 'Endereço'),
            _campo('Logradouro', _logradouro()),
            _campo('Complemento', _texto('complemento')),
            _campo('Bairro', _texto('bairro')),
            _campo('Cidade / UF', '${_texto('municipio')} / ${_texto('uf')}'),
            _campo('CEP', _texto('cep')),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFFF3F6F4),
      surfaceTintColor: Colors.transparent,
      title: const Row(
        children: [
          Icon(Icons.business_outlined, color: Color(0xFF176B50)),
          SizedBox(width: 10),
          Text(
            'Consulta CNPJ',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INFORMAÇÕES DE EMPRESAS',
                    style: TextStyle(
                      color: Color(0xFF176B50),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Uma consulta.\nConheça a empresa.',
                    style: TextStyle(
                      color: Color(0xFF173A2D),
                      fontSize: 30,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Digite o CNPJ para buscar os dados básicos da empresa na BrasilAPI.',
                    style: TextStyle(
                      color: Color(0xFF64736B),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _cartao(
                    Form(
                      key: _formulario,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Qual CNPJ você quer consultar?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _cnpjController,
                            enabled: !_carregando,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.search,
                            autocorrect: false,
                            maxLength: 18,
                            decoration: const InputDecoration(
                              labelText: 'CNPJ',
                              hintText: '00.000.000/0001-91',
                              helperText: '14 números, com ou sem pontuação',
                              helperMaxLines: 2,
                              errorMaxLines: 2,
                              counterText: '',
                              prefixIcon: Icon(Icons.search),
                            ),
                            validator: (valor) =>
                                RegExp(r'^\d{14}$')
                                    .hasMatch(_normalizar(valor ?? ''))
                                ? null
                                : 'Informe um CNPJ com 14 números.',
                            onFieldSubmitted: (_) => _consultar(),
                            onChanged: (_) {
                              if (_empresa != null || _erro != null) {
                                setState(() {
                                  _empresa = null;
                                  _erro = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: _carregando ? null : _consultar,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF176B50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _carregando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.search, size: 21),
                              label: Text(
                                _carregando
                                    ? 'Consultando...'
                                    : 'Consultar CNPJ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_erro != null)
                    Semantics(
                      liveRegion: true,
                      child: _cartao(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF805511),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Não foi possível consultar',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_erro!, style: const TextStyle(height: 1.5)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _consultar,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_empresa != null) ..._resultado(),
                  if (_empresa == null && _erro == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _carregando
                                ? Icons.hourglass_empty
                                : Icons.manage_search,
                            size: 42,
                            color: const Color(0xFF779587),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _carregando
                                ? 'Buscando na BrasilAPI'
                                : 'Os dados aparecem aqui',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _carregando ? 'Aguarde a conclusão da consulta.' : 'Razão social, situação cadastral, atividade principal e endereço em um só lugar.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF64736B),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  const Divider(color: Color(0xFFDCE5DF)),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Fonte: BrasilAPI • brasilapi.com.br',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF64736B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
