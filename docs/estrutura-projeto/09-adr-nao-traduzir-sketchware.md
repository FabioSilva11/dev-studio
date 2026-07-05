# ADR (Architecture Decision Record): Não Traduzir Diretamente o Sketchware

## Status

Aceito.

## Contexto

O repositório [FabioSilva11/Sketchware-IA](https://github.com/FabioSilva11/Sketchware-IA) descreve o projeto como uma continuação moderna do Sketchware para Android, com editor visual, blocos, desenvolvimento Android no celular, suporte a Java/Kotlin e compilação de APK no próprio dispositivo.

O próprio README também apresenta o Sketchware IA como uma IDE Android com blocos visuais, Java/Kotlin e inteligência artificial, e afirma que a base atual em Java/Kotlin continua ativa.

Isso confirma que o ecossistema Sketchware está ancorado em Android nativo e geração/edição de projetos Android, não em Flutter como modelo interno principal.

Flutter usa outro modelo de construção:

```txt
Widget Tree -> State -> Build -> composição declarativa -> Dart
```

Já o Sketchware tradicional tende a seguir algo mais próximo de:

```txt
View Android -> XML -> Activity Java -> eventos -> componentes Android
```

Embora os dois possam representar telas, eventos e componentes, eles não compartilham a mesma arquitetura mental.

## Decisão

Não traduziremos diretamente o modelo interno do Sketchware para Flutter.

O Dev Studio terá schema próprio, arquitetura própria e modelo de programação visual próprio.

Projetos Sketchware poderão ser importados futuramente como entrada parcial, segura e não destrutiva.

## Justificativa

### O Sketchware é orientado a Android nativo

Mesmo que a interface visual pareça genérica, a proposta pública do Sketchware-IA é desenvolvimento Android com blocos e Java/Kotlin.

Na prática, esse contexto carrega conceitos como:

- `Activity`;
- `Intent`;
- `View`;
- `LinearLayout`;
- `RelativeLayout`;
- XML;
- eventos Java;
- permissões Android;
- componentes específicos de Android;
- ciclo de vida Android.

Flutter não é uma camada sobre esses conceitos. Flutter tem outra árvore visual, outro ciclo de vida, outro modelo de estado e outra forma de composição.

### Tradução direta cria compatibilidade falsa

Converter `LinearLayout` para `Column` ou `Button` Android para `ElevatedButton` parece simples em exemplos pequenos.

Projetos reais tendem a quebrar em pontos como:

- ciclo de vida;
- navegação;
- permissões;
- armazenamento;
- callbacks;
- operações assíncronas;
- componentes sem equivalente direto;
- bibliotecas externas;
- blocos que geram Java;
- diferenças entre XML imperativo e UI declarativa.

A tradução direta funcionaria nos casos simples e ficaria frágil nos casos importantes.

### O objetivo não é preservar o passado

O objetivo do Dev Studio não é ser uma cópia técnica do Sketchware.

O objetivo é preservar a experiência de criação visual e reconstruir o núcleo de forma nativa para Flutter.

Frase guia:

```txt
O Dev Studio não deve ser uma tradução do Sketchware original.
Ele deve preservar a experiência de criação visual, mas reconstruir o modelo interno de forma nativa para Flutter.
```

### Traduzir herdaria decisões antigas

Uma tradução direta herdaria:

- limitações do modelo antigo;
- nomes e conceitos acoplados ao Android;
- bugs ou decisões históricas;
- dificuldade de evoluir para Flutter;
- complexidade permanente de compatibilidade.

Isso faria o projeto novo nascer preso à arquitetura do projeto antigo.

## Importar Não é Traduzir

Importação é aceitável porque cria uma fronteira:

```txt
Sketchware antigo -> Importador -> Modelo Dev Studio
```

Tradução direta é perigosa porque cria dependência:

```txt
Modelo Sketchware -> Editor Dev Studio -> Gerador Flutter
```

No primeiro caso, o Dev Studio recebe dados de entrada e os converte para seu próprio formato.

No segundo caso, o Dev Studio passa a depender do modelo antigo como fundação.

## Regra

A compatibilidade com Sketchware é uma feature de entrada, não uma fundação arquitetural.

## Consequências

### Benefícios

- O Dev Studio pode evoluir como produto Flutter nativo.
- O schema fica independente de Java, XML e detalhes Android.
- A programação visual pode gerar código MVVM em Dart sem carregar conceitos antigos.
- A importação pode ser parcial, segura e honesta.
- O projeto fica mais simples de explicar e manter.

### Custos

- Não haverá compatibilidade total no início.
- Alguns projetos Sketchware não serão importáveis por completo.
- Será necessário criar um importador dedicado no futuro.
- Usuários precisarão entender que Dev Studio é inspirado no Sketchware, não um substituto binário imediato.

## Decisão de Produto

O Dev Studio deve comunicar:

```txt
Inspirado no Sketchware.
Construído nativamente para Flutter.
Compatibilidade por importação parcial e segura.
```
