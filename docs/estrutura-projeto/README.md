# Estruturação do Dev Studio

Este diretório reúne duas visões complementares:

- direção de produto e arquitetura alvo;
- fotografia técnica do que já está implementado.

A proposta continua sendo o Dev Studio como editor visual mobile-first em Flutter, com formato de projeto próprio. Ao mesmo tempo, a base atual já possui uma fundação arquitetural real (core, data, domain, ui) com autenticação em Firebase, roteamento e injeção de dependências.

## Documentos

- [01-visao.md](01-visao.md): objetivo do produto, público e princípios.
- [02-nao-objetivos.md](02-nao-objetivos.md): o que não será feito no início.
- [03-arquitetura-inicial.md](03-arquitetura-inicial.md): arquitetura atual implementada e arquitetura alvo.
- [04-schema-do-projeto.md](04-schema-do-projeto.md): formato de armazenamento do projeto.
- [05-mvp.md](05-mvp.md): MVP do produto e status de base já concluída.
- [06-roadmap.md](06-roadmap.md): fases sugeridas de evolução e marco técnico atual.
- [07-adr-mvvm-command-result.md](07-adr-mvvm-command-result.md): decisão arquitetural sobre MVVM, Command e Result.
- [08-programacao-visual.md](08-programacao-visual.md): modelo conceitual para lógica visual por blocos.
- [09-adr-nao-traduzir-sketchware.md](09-adr-nao-traduzir-sketchware.md): justificativa para não traduzir diretamente o Sketchware original.

## Fluxo Arquitetural

Fluxo em produção hoje:

```txt
UI -> ViewModel -> Repository -> Service
Auth: UI -> ViewModel -> AuthRepository -> FirebaseAuth
```

Fluxo alvo para evolução do produto (com casos de uso explícitos):

```txt
UI -> ViewModel -> UseCase -> Repository -> Service
```

A camada de UseCases já existe em `lib/domain/usecases`, mas sua adoção está gradual e deve ser feita conforme os fluxos de negócio do editor visual forem sendo incorporados.

## Decisão de Direção

- Compatibilidade com Sketchware deve existir como importação opcional e segura, nunca como edição direta de arquivos originais.
- A compatibilidade com Sketchware é uma feature de entrada, não a fundação arquitetural.
- A base técnica atual deve continuar evoluindo com separação clara de responsabilidades entre UI, domínio, dados e infraestrutura.
