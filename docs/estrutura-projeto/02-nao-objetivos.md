# Não Objetivos

Este documento existe para proteger o projeto de crescer torto.

## Fora do Escopo Inicial

- Editar projetos Sketchware diretamente.
- Sobrescrever arquivos dentro de `.sketchware/data`.
- Prometer compatibilidade total com Sketchware.
- Traduzir diretamente o modelo interno do Sketchware para Flutter.
- Gerar APK na primeira versão.
- Suportar todos os widgets do Android ou do Sketchware.
- Criar um sistema completo de blocos no começo.
- Criar loja, chat, serviços web ou recursos paralelos antes do editor estar estável.
- Misturar regras de produto com código nativo Android sem camada de domínio.

## Decisão Sobre Sketchware

Sketchware deve ser tratado como fonte de inspiração e, futuramente, como origem de importação.

Fluxo aceitável no futuro:

1. Usuário escolhe importar um projeto Sketchware.
2. Dev Studio lê o projeto original.
3. Dev Studio cria uma cópia em formato próprio.
4. O projeto original permanece intacto.
5. O app informa quais partes foram ou não convertidas.

Fluxo não aceitável:

1. Abrir um projeto Sketchware real.
2. Editar parcialmente no Dev Studio.
3. Salvar por cima do projeto original.

Esse fluxo é perigoso porque pode destruir dados que o Dev Studio ainda não entende.

## Por Que Não Traduzir Diretamente

O Sketchware original é orientado a Android nativo, Java e XML. Flutter usa outro modelo: árvore de widgets, estado declarativo e código Dart.

Traduzir diretamente o modelo antigo manteria as limitações do Sketchware e ainda adicionaria a complexidade de converter conceitos Android para Flutter.

O Dev Studio deve preservar a experiência de criação visual, mas reconstruir o modelo interno de forma nativa para Flutter.

Mais detalhes estão em [09-adr-nao-traduzir-sketchware.md](09-adr-nao-traduzir-sketchware.md).
