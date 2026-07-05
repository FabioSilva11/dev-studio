
# Dev Studio

Editor visual mobile-first inspirado no Sketchware, feito em Flutter, com formato de projeto próprio.

## Objetivo

Validar que o Dev Studio consegue criar, editar, salvar e reabrir uma tela visual simples usando formato próprio.

## Arquitetura

O projeto usa **Clean Architecture** com **MVVM**:
- **UI**: Páginas e componentes visuais
- **Domain**: Modelos e use cases
- **Data**: Repositórios e serviços (armazenamento, serialização)

Fluxo típico:
```txt
UI → ViewModel → UseCase → Repository → Service
```

## Funcionalidades (MVP)

- Lista de projetos Dev Studio
- Criação de projeto
- Editor de uma tela com:
  - Paleta com widgets básicos
  - Canvas com preview
  - Inspetor de propriedades
  - Árvore de widgets
- Salvamento em JSON
- Reabertura sem perda de dados
- Schema com espaço para lógica visual (events)

## Documentação

Toda a documentação da estrutura do projeto está em [docs/estrutura-projeto/](docs/estrutura-projeto/):

- [Visão geral](docs/estrutura-projeto/01-visao.md): objetivo do produto, público e princípios.
- [Não-objetivos](docs/estrutura-projeto/02-nao-objetivos.md): o que não será feito no início.
- [Arquitetura inicial](docs/estrutura-projeto/03-arquitetura-inicial.md): módulos e responsabilidades.
- [Schema do projeto](docs/estrutura-projeto/04-schema-do-projeto.md): formato de armazenamento do projeto.
- [MVP](docs/estrutura-projeto/05-mvp.md): menor versão útil para validar a ideia.
- [Roadmap](docs/estrutura-projeto/06-roadmap.md): fases sugeridas de evolução.
- [ADR: MVVM + Command + Result](docs/estrutura-projeto/07-adr-mvvm-command-result.md): decisão arquitetural.
- [Programação visual](docs/estrutura-projeto/08-programacao-visual.md): modelo conceitual para lógica visual por blocos.
- [ADR: Não traduzir diretamente Sketchware](docs/estrutura-projeto/09-adr-nao-traduzir-sketchware.md): justificativa importante.

## Decisão de Direção

Compatibilidade com Sketchware deve existir apenas como importação opcional e segura, nunca como edição direta dos arquivos originais. A compatibilidade com Sketchware é uma feature de entrada, não uma fundação arquitetural.
