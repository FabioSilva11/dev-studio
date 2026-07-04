# ADR: MVVM, Command e Result

## Status

Aceito.

## Contexto

O Dev Studio será um editor visual com muitas operações pequenas e recorrentes: criar projeto, abrir projeto, adicionar widget, mover widget, editar propriedades, salvar, desfazer, refazer e futuramente gerar código.

Sem uma arquitetura clara, esse tipo de aplicação tende a misturar UI, regras de edição, persistência e detalhes técnicos. A base anterior mostrou esse risco: muitas possibilidades no mesmo lugar, pouco isolamento e pouca documentação de intenção.

Também existe uma preferência técnica importante: o desenvolvimento deve aproveitar experiência prévia com MVVM.

## Decisão

O Dev Studio será desenvolvido usando MVVM com o fluxo:

```txt
UI -> ViewModel -> UseCase -> Repository -> Service
```

A mesma arquitetura deve ser usada como base para o código gerado futuramente pelo Dev Studio.

A estrutura de pastas deve ser organizada por camadas principais: `ui`, `domain`, `data` e `core`.

## Responsabilidades

### UI

- Renderiza o estado.
- Encaminha intenções do usuário.
- Não contém regra de negócio.
- Não acessa Repository ou Service diretamente.

### ViewModel

- Mantém estado de tela.
- Recebe commands.
- Chama UseCases.
- Converte resultados em estado renderizável.
- Expõe loading, erro, mensagens e dados de tela.

### UseCase

- Executa uma ação de aplicação.
- Coordena repositories.
- Valida regras do domínio.
- Retorna `Result`.
- Não depende de Flutter.

### Repository

- Define contrato de acesso a dados.
- Pertence ao domínio.
- Esconde detalhes de storage, JSON, importadores e exportadores.

### Service

- Implementa detalhes técnicos.
- Pode lidar com arquivo local, platform APIs, importação, exportação, serialização e integrações.

## Command

Commands representam operações assíncronas executadas pela UI por meio dos ViewModels.

O Dev Studio deve usar commands tipados por quantidade de entrada:

Exemplos:

```txt
Command0<Output>
Command1<Output, Input>

CommandState
  idle
  running
  success
  failure
```

Commands devem ser pequenos, explícitos e testáveis. Cada command executa uma action que retorna `Future<Result<T>>`.

## Result

Operações que podem falhar devem retornar um resultado padronizado.

```txt
Result<T>
  Success<T>
  Failure<T>

AppError
  code
  message
  cause
```

Falhas previsíveis devem usar `Failure`, não exceções propagadas até a UI.

Exceções continuam existindo para erros inesperados, mas devem ser capturadas nas bordas técnicas e convertidas em `AppError` quando fizer sentido.

## Geração de Código

Projetos gerados pelo Dev Studio devem seguir a mesma base:

```txt
lib/
  core/
    result/
      command.dart
      result.dart
      unit.dart
      errors/
    routing/
    services/
    config/
    extensions/

  domain/
    common/
    usecases/

  data/
    repositories/
    services/

  ui/
    app_widget.dart
    components/
    pages/
      feature_name/
        feature_page.dart
        viewmodel/
          feature_viewmodel.dart
        widgets/
    viewmodels.dart
```

Para apps muito simples, o gerador pode omitir camadas vazias. Mesmo assim, a organização padrão deve continuar sendo MVVM.

## Consequências

### Benefícios

- Facilita testes.
- Reduz mistura entre UI e persistência.
- Cria um padrão mental consistente.
- Permite que o Dev Studio ensine e gere uma arquitetura previsível.
- Ajuda a manter o editor visual sob controle conforme crescer.

### Custos

- Mais arquivos no início.
- Mais disciplina para não furar camadas.
- Pode parecer pesado para exemplos muito simples.

## Regra de Ouro

Se uma ação altera projeto, editor, tela ou widget, ela deve passar por ViewModel e UseCase.
