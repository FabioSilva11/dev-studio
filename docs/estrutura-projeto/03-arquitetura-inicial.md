# Arquitetura Inicial

## Camadas

O Dev Studio deve usar MVVM como arquitetura principal.

Fluxo padrão:

```txt
UI -> ViewModel -> UseCase -> Repository -> Service
```

Cada camada tem uma responsabilidade clara:

- UI: renderiza estado e encaminha intenções do usuário.
- ViewModel: mantém estado de tela, recebe comandos e chama casos de uso.
- UseCase: executa regras de aplicação e coordena operações.
- Repository: define contratos de acesso a dados do domínio.
- Service: implementa detalhes técnicos, como arquivo local, JSON, importadores, exportadores e platform APIs.

## Organização de Pastas

A organização deve ser baseada em camadas principais, com ViewModels próximos das páginas que os consomem.

O projeto fica organizado por camadas principais (`ui`, `domain`, `data`, `core`) e a UI mantém suas páginas e ViewModels próximas. Isso combina melhor com MVVM do que dividir cada feature em `presentation/domain/data`.

```txt
core/
  result/
    command.dart
    result.dart
    unit.dart
    errors/
      app_error.dart
      app_error_code.dart
  config/
    dependencies.dart
  routing/
    router.dart
    routes.dart
  resources/
    storage_keys.dart
  extensions/
  services/
    logging/
    local_storage/

domain/
  common/
    project/
      dev_studio_project.dart
      project_summary.dart
    editor/
      editor_screen.dart
      widget_node.dart
      widget_props.dart
      widget_type.dart
  usecases/
    projects/
      create_project_usecase.dart
      list_projects_usecase.dart
      open_project_usecase.dart
      save_project_usecase.dart
    editor/
      add_widget_usecase.dart
      move_widget_usecase.dart
      remove_widget_usecase.dart
      update_widget_props_usecase.dart
      undo_editor_usecase.dart
      redo_editor_usecase.dart
    export/
      export_flutter_project_usecase.dart
    import/
      import_sketchware_project_usecase.dart

data/
  repositories/
    project/
      project_repository.dart
      project_repository_impl.dart
    editor/
      editor_project_repository.dart
      editor_project_repository_impl.dart
  services/
    storage/
      project_storage_service.dart
      project_storage_service_impl.dart
    serialization/
      project_json_service.dart
    rendering/
      widget_render_service.dart
    importers/
      sketchware/
    exporters/
      flutter/
      android/

ui/
  app_widget.dart
  components/
    buttons/
    input_text/
    messages/
    themes/
  pages/
    splash/
      splash_page.dart
      viewmodel/
        splash_viewmodel.dart
    projects/
      project_list_page.dart
      project_create_page.dart
      viewmodel/
        project_list_viewmodel.dart
        project_create_viewmodel.dart
      widgets/
    editor/
      editor_page.dart
      viewmodel/
        editor_viewmodel.dart
      canvas/
      palette/
      inspector/
      widget_tree/
    export/
      export_page.dart
      viewmodel/
        export_viewmodel.dart
  viewmodels.dart
```

## Estrutura Resumida

```txt
core/
  result/
  routing/
  services/
  config/

data/
  repositories/
  services/

domain/
  common/
  usecases/

ui/
  app_widget.dart
  components/
  pages/
    feature/
      feature_page.dart
      viewmodel/
      widgets/
  viewmodels.dart
```

## Convenções de Pasta

- `ui/`: telas, componentes, temas e ViewModels.
- `ui/pages/*/viewmodel/`: ViewModels ligados a uma página ou fluxo.
- `domain/common/`: modelos e conceitos compartilhados do domínio.
- `domain/usecases/`: ações de aplicação chamadas pelos ViewModels.
- `data/repositories/`: contratos e implementações de repositories.
- `data/services/`: detalhes técnicos usados pelos repositories e usecases.
- `core/result/`: `Command`, `Result`, `Unit`, `AppError` e códigos de erro.
- `core/routing/`: rotas e navegação.
- `core/config/`: composição de dependências.

## Command e Result

O Dev Studio deve usar `Command` para representar operações assíncronas expostas pelos ViewModels e `Result` para representar sucesso ou falha previsível.

```txt
Command0<Output>
Command1<Output, Input>
CommandState
  idle
  running
  success
  failure

Result<T>
  Success<T>
  Failure<T>

Unit
AppError
```

O ViewModel expõe commands para a UI. Cada command executa uma action que retorna `Future<Result<T>>`.

Exemplo conceitual:

```txt
EditorViewModel
  addWidgetCommand
  moveWidgetCommand
  saveProjectCommand
```

## Regra Sobre Repository e Service

Repository representa uma capacidade de dados da aplicação.

Service representa detalhe técnico.

Exemplo:

```txt
ProjectRepository
  lista e salva projetos em termos do Dev Studio.

ProjectStorageService
  lê e escreve arquivos no disco.

ProjectJsonService
  serializa e desserializa JSON.
```

Um ViewModel não acessa `ProjectStorageService`. Ele executa um Command. O Command chama um UseCase. O UseCase chama `ProjectRepository`. O Repository usa Services.

## Alternativa Rejeitada

A estrutura abaixo foi considerada e rejeitada para este projeto:

```txt
features/
  feature_name/
    presentation/
    domain/
    data/
```

Motivos:

- divide cada funcionalidade cedo demais;
- cria uma separação por feature antes de o domínio do Dev Studio estar maduro;
- deixa o MVVM menos evidente;
- pode duplicar conceitos compartilhados do editor visual.

## Regra Principal

A UI não deve conhecer detalhes de arquivos Sketchware, criptografia, XML Android ou estrutura de storage externa.

A UI conversa com modelos e serviços do Dev Studio:

```txt
Tela Flutter -> ViewModel -> UseCase -> Repository -> Service
```

ViewModels não devem acessar Services diretamente. UseCases não devem depender de Flutter. Repositories representam capacidades de dados da aplicação. Services são detalhes técnicos.

## Módulos Iniciais

### Project Repository

Responsável por:

- criar projeto;
- listar projetos;
- carregar projeto;
- salvar projeto;
- duplicar projeto;
- excluir projeto.

### Editor ViewModel

Responsável por:

- expor o estado renderizável do editor;
- receber comandos da UI;
- chamar UseCases;
- publicar erros e mensagens de tela.

### Editor UseCases

Responsáveis por:

- adicionar widget;
- mover widget;
- remover widget;
- selecionar widget;
- atualizar propriedades;
- controlar undo/redo.

### Project Model

Responsável por representar:

- projeto;
- tela;
- árvore de widgets;
- propriedades;
- tema;
- assets.

### Renderer

Responsável por transformar o modelo em preview Flutter.

No início, o renderer pode ser simples e interno ao editor. Depois, pode virar um módulo próprio.

## Command e Result

Interações assíncronas importantes da UI devem ser representadas como commands.

Exemplos:

- `Command0<Unit>` para salvar projeto sem input.
- `Command1<WidgetNode, AddWidgetInput>` para adicionar widget.
- `Command1<Unit, MoveWidgetInput>` para mover widget.

Operações que podem falhar devem retornar `Result`.

```txt
Result<T>
  Success<T>
  Failure<T>
```

Falhas previsíveis devem ser representadas como `AppError`, em vez de exceções soltas atravessando as camadas.

## Dependências Permitidas no MVP

Preferir Flutter SDK puro no começo.

Adicionar dependências apenas quando houver necessidade clara, por exemplo:

- armazenamento local;
- seleção de imagens;
- geração/exportação futura.
