# ADR: MVVM, Command e Result

## Status

Aceito com adoção incremental de UseCase.

## Contexto

O Dev Studio precisa de uma arquitetura previsível para suportar crescimento sem acoplamento entre UI, dados e infraestrutura.

Ao mesmo tempo, a implementação atual já possui um fluxo funcional em produção com foco em ViewModel, Repository e Services de dados/infraestrutura.

## Decisão

A base arquitetural oficial continua sendo MVVM com `Command` e `Result` como contratos padrão para operações assíncronas e tratamento de falha.

Fluxo implementado hoje:

```txt
UI -> ViewModel -> Repository -> API/Service -> RestClient -> Dio
```

Fluxo alvo para evolução completa:

```txt
UI -> ViewModel -> UseCase -> Repository -> Service
```

A camada de UseCase deve ser introduzida gradualmente em fluxos que exigem coordenação de regras de negócio, mantendo compatibilidade com o fluxo atual.

## Responsabilidades

### UI

- Renderiza estado.
- Encaminha intenções.
- Não acessa detalhes de transporte ou storage.

### ViewModel

- Expõe estado de tela e comandos.
- Coordena chamadas de caso de uso (quando existir) ou repositório.
- Converte `Result` em estado renderizável.

### UseCase

- Encapsula regra de negócio e orquestração de operações.
- Deve ser preferido em fluxos de negócio complexos.
- Não depende de Flutter.

### Repository

- Expõe operações de dados para a aplicação.
- Esconde APIs, cache e storage.

### Service/Infra

- Implementa transporte, serialização, cache e integrações técnicas.

## Command

`Command0` e `Command1` representam operações assíncronas iniciadas pela UI.

Estados esperados:

```txt
idle
running
success
failure
```

Commands devem ser pequenos, explícitos e testáveis.

## Result

Toda operação com falha previsível deve usar `Result<T>`:

```txt
Success<T>
Failure<T>
```

Falhas previsíveis devem ser mapeadas para `AppError` com `code` e `message` adequados.

## Consequências

### Benefícios

- Isolamento entre camadas.
- Contrato uniforme de sucesso/falha.
- Facilidade de testes unitários.
- Evolução segura da arquitetura para casos de uso explícitos.

### Custos

- Maior quantidade de abstrações em fluxos simples.
- Adoção gradual pode coexistir com dois estilos temporariamente.

## Regra de Ouro

Toda ação relevante de negócio deve passar por ViewModel e retornar `Result`.

Para fluxos simples, ViewModel pode chamar Repository diretamente.

Para fluxos complexos, a chamada deve passar por UseCase.
