# MVP

## Status Atual da Base

A base técnica para o MVP já possui:

- camadas `core`, `data`, `domain` e `ui` organizadas;
- infraestrutura HTTP com `RestClient` e Dio;
- bootstrap de injeção de dependências;
- rotas e páginas iniciais (`splash` e `home`);
- contratos de `Result`, `Command` e `AppError`.

O escopo abaixo continua sendo o MVP funcional do editor visual.

## Objetivo do MVP

Validar que o Dev Studio consegue criar, editar, salvar e reabrir uma tela visual simples usando formato próprio.

O MVP não precisa ter editor completo de blocos, mas o schema deve conter a estrutura mínima para lógica visual.

## Fluxo Principal

1. Abrir o app.
2. Criar um novo projeto.
3. Abrir a tela principal do projeto.
4. Adicionar widgets pela paleta.
5. Selecionar um widget.
6. Editar propriedades básicas.
7. Salvar o projeto.
8. Fechar e reabrir.
9. Ver a mesma tela restaurada.

## Funcionalidades Obrigatórias

- Lista de projetos Dev Studio.
- Criação de projeto.
- Editor de uma tela.
- Paleta com widgets básicos.
- Canvas com preview.
- Inspetor de propriedades.
- Árvore de widgets.
- Salvamento em JSON.
- Reabertura sem perda de dados.
- Schema com espaço para `logic.events`.
- ViewModels para projetos e editor.
- UseCases para criar, abrir, salvar e editar projeto (adoção incremental).
- Result padronizado para sucesso e falha.

## Widgets do MVP

- Column
- Row
- Container
- Text
- Button
- Image
- TextField

## Funcionalidades Fora do MVP

- Importação Sketchware.
- Exportação para APK.
- Editor completo de blocos.
- Execução de blocos.
- Múltiplas telas com navegação real.
- Marketplace.
- Chat.
- Serviços web.
- Integração com arquivos `.sketchware`.

## Critério de Pronto

O MVP está pronto quando:

- `flutter analyze` não apresenta problemas relevantes;
- testes principais passam;
- um projeto salvo pode ser reaberto;
- a estrutura de JSON possui `schemaVersion`;
- a estrutura de JSON possui `logic.events`;
- o editor não depende de código Android nativo para funcionar.
- a UI não acessa Repository ou Service diretamente;
- actions principais passam por ViewModel e `Result`, usando UseCase quando houver regra de negócio relevante.
