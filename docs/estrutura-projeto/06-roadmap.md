# Roadmap

## Marco Atual (já concluído)

- Estrutura de camadas criada em `lib/core`, `lib/data`, `lib/domain` e `lib/ui`.
- Bootstrap de dependências implementado (`core/config/dependencies.dart`).
- Infraestrutura HTTP estabelecida com `RestClient`, Dio e interceptadores.
- Secure storage e recursos globais estabelecidos.
- Módulos iniciais de autenticação e cache implementados.
- Rotas base e páginas iniciais (`splash` e `home`) estruturadas.
- Base de `Result`, `Command` e `AppError` ativa.

## Fase 1: Consolidação da Base

- Conectar UseCases no bootstrap de DI quando houver regra de negócio explícita.
- Expandir testes unitários de core/data.
- Padronizar mapeamento de erros de API para `AppError`.
- Documentar contratos de repositório por domínio funcional.

## Fase 2: Núcleo do Editor Visual

- Lista de projetos Dev Studio.
- Criação/abertura/salvamento de projeto.
- Modelo interno de tela e árvore de widgets.
- Editor de uma tela com paleta e preview.
- Inspetor de propriedades básicas.

## Fase 3: Editor Mais Usável

- Undo/redo.
- Duplicar e reordenar widgets.
- Árvore de widgets mais robusta.
- Assets locais e múltiplas telas.

## Fase 4: Lógica Visual

- Eventos simples e ações simples.
- Schema versionado para blocos.
- Variáveis locais e condições básicas.
- Navegação entre telas orientada por blocos.

## Fase 5: Exportação

- Gerar projeto Flutter.
- Exportar assets.
- Gerar instruções de build.
- Avaliar pipeline de build Android.

## Fase 6: Importação Sketchware

- Leitura não destrutiva do projeto original.
- Conversão parcial de layout/eventos suportados.
- Relatório de conversão.
- Persistência final no schema Dev Studio.

## Regra Para Avançar de Fase

Cada fase só avança quando a anterior estiver estável, testada e documentada.
