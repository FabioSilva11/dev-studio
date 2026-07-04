# Estruturação do Dev Studio

Este diretório define uma proposta inicial para recomeçar o Dev Studio como um projeto organizado, com escopo próprio e arquitetura clara.

A decisão central é abandonar a base atual como núcleo de desenvolvimento. Ela pode continuar servindo como referência visual e fonte de aprendizado, mas o novo projeto deve nascer com modelo próprio, persistência própria e uma separação explícita entre editor, projeto, importadores e exportadores.

## Documentos

- [01-visao.md](01-visao.md): objetivo do produto, público e princípios.
- [02-nao-objetivos.md](02-nao-objetivos.md): o que não será feito no início.
- [03-arquitetura-inicial.md](03-arquitetura-inicial.md): módulos e responsabilidades.
- [04-schema-do-projeto.md](04-schema-do-projeto.md): formato de armazenamento do projeto.
- [05-mvp.md](05-mvp.md): menor versão útil para validar a ideia.
- [06-roadmap.md](06-roadmap.md): fases sugeridas de evolução.
- [07-adr-mvvm-command-result.md](07-adr-mvvm-command-result.md): decisão arquitetural sobre MVVM, Command e Result.
- [08-programacao-visual.md](08-programacao-visual.md): modelo conceitual para lógica visual por blocos.
- [09-adr-nao-traduzir-sketchware.md](09-adr-nao-traduzir-sketchware.md): justificativa para não traduzir diretamente o Sketchware original.

## Decisão de Direção

Dev Studio será um editor visual mobile-first inspirado no Sketchware, feito em Flutter, com formato de projeto próprio.

Compatibilidade com Sketchware deve existir apenas como importação opcional e segura, nunca como edição direta dos arquivos originais.

A compatibilidade com Sketchware é uma feature de entrada, não uma fundação arquitetural.

O projeto será desenvolvido usando MVVM, com fluxo:

```txt
UI -> ViewModel -> UseCase -> Repository -> Service
```

A mesma base arquitetural deve orientar a geração futura de código para projetos criados no Dev Studio.
