# Roadmap

## Fase 0: Fundação

- Documentar visão e não objetivos.
- Registrar a decisão arquitetural MVVM.
- Criar tipos base de Command, Result e Error.
- Criar modelo interno.
- Definir schema inicial de lógica visual.
- Criar persistência local.
- Criar testes do modelo.
- Definir estrutura de pastas.

## Fase 1: Editor Visual Básico

- Lista de projetos.
- Criação de projeto.
- ViewModels de projetos e editor.
- UseCases de criação, abertura, salvamento e edição.
- Editor com uma tela.
- Paleta de widgets básicos.
- Canvas com árvore de widgets.
- Inspetor de propriedades.
- Salvar e reabrir.

## Fase 2: Editor Mais Usável

- Undo/redo.
- Duplicar widget.
- Reordenar widgets.
- Painel de árvore.
- Edição de tema.
- Assets locais.
- Múltiplas telas.

## Fase 3: Lógica Visual

- Eventos simples.
- Ações simples.
- Editor visual de blocos inicial.
- Schema de blocos versionado.
- Validação de blocos.
- Navegação entre telas.
- Variáveis locais.
- Condições básicas.

## Fase 4: Programação Visual Avançada

- Expressões.
- Comparações.
- Repetições.
- Listas simples.
- Chamadas de serviço/API.
- Estado de tela.
- Depuração visual básica.

## Fase 5: Exportação

- Gerar projeto Flutter.
- Gerar código organizado em MVVM.
- Gerar ViewModel, State, Command, UseCase, Repository e Service quando aplicável.
- Exportar assets.
- Criar instruções de build.
- Avaliar build APK.

## Fase 6: Importação Sketchware

- Ler projeto Sketchware sem modificar origem.
- Converter layouts simples.
- Converter eventos simples quando possível.
- Converter textos e cores.
- Gerar relatório de conversão.
- Salvar como projeto Dev Studio.

## Regra Para Avançar de Fase

Uma fase só deve avançar quando a anterior estiver estável, testada e documentada.

O projeto deve resistir à vontade de implementar muitas possibilidades antes de firmar o núcleo.
