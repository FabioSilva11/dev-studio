# Arquitetura Inicial

## Estado Atual (Implementado)

A estrutura de camadas já está estabelecida em `lib/core`, `lib/data`, `lib/domain` e `lib/ui`.

Fluxo arquitetural em produção:

```txt
UI -> ViewModel -> Repository -> Service
Auth: UI -> ViewModel -> AuthRepository -> FirebaseAuth
```

Esse fluxo já está coerente com os módulos existentes de autenticação, cache, roteamento e secure storage.

## Fluxo Alvo (Evolução)

Para os próximos ciclos do Dev Studio, o fluxo evolui para incluir casos de uso explícitos:

```txt
UI -> ViewModel -> UseCase -> Repository -> Service
```

A pasta `domain/usecases` já existe e está preparada para essa adoção gradual.

## Organização de Pastas (Atual)

```txt
lib/
  main.dart

  core/
    config/
      dependencies.dart
    extensions/
    resources/
      app_env.dart
      app_http_headers.dart
      storage_keys.dart
    result/
      command.dart
      result.dart
      unit.dart
      errors/
    routing/
      router.dart
      routes.dart
      routes/
      extensions/
      animations_page/
      models/
    services/
      core_services.dart
      secure_storage/
      installation_identity/
      logging/

  data/
    repositories.dart
    repositories/
      auth/
    services/
      services.dart
      auth/
        dtos/
      cache/
        last_login/

  domain/
    common/
    usecases/
      usecases.dart

  ui/
    app_widget.dart
    components/
      themes/
    pages/
      splash/
      home/
```

## Topologia do Repositório (Resumo)

```txt
.
  android/
  assets/
    images/
  docs/
    estrutura-projeto/
  lib/
  test/
```

## Responsabilidade por Camada

### UI

- Renderiza estado e recebe intenção do usuário.
- Contém páginas e viewmodels por fluxo.
- Não deve acessar SDKs externos diretamente.

### Domain

- Mantém tipos de domínio compartilhados e usecases.
- `domain/usecases` está disponível para evolução de regras mais complexas.

### Data

- Implementa repositórios e integrações externas.
- Orquestra API, cache e contratos para consumo da UI.

### Core

- Mantém infraestrutura transversal: Result, Command, roteamento, ambiente e secure storage.

## Injeção de Dependências

Bootstrap atual em `core/config/dependencies.dart`:

1. CoreServices
2. Services
3. Repositories

`Usecases` e `Viewmodels` já possuem ponto de extensão e podem ser ligados no bootstrap conforme a evolução dos fluxos de negócio.

## Convenções Atuais

- Operações assíncronas usam `Result` e `Command`.
- Falhas previsíveis devem ser mapeadas para `AppError`.
- Integrações externas devem ficar encapsuladas em `data/services`.
- Persistência segura deve passar por `core/services/secure_storage`.

## Regra Principal

A UI não deve conhecer detalhes de transporte, interceptadores, serialização de API ou armazenamento seguro. Esses detalhes ficam em `core` e `data`, preservando o isolamento de camadas.
