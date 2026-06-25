# Análise Comparativa entre Sketchware Original e Projeto Flutter

Data: 2026-06-25  
Projeto Flutter analisado: `Dev Studio`  
Referência oficial: Sketchware original localizado no workspace local  
Escopo: análise estática de código e comportamento esperado, sem build, sem compilação e sem alteração de código-fonte.

## Resumo executivo

O editor Flutter atual possui uma estrutura visual parecida em alto nível com o Sketchware: abas do projeto, paleta de widgets, canvas, seleção, drag-and-drop e lixeira. Porém a equivalência funcional ainda é parcial.

Compatibilidade estimada com Sketchware: **35% a 40%**.

O principal problema técnico é que o Flutter usa um modelo de canvas absoluto, baseado em `x`, `y`, `width` e `height`, enquanto o Sketchware trabalha com uma árvore Android real composta por `ViewBean`, `LayoutBean`, `ViewGroup`, `parent`, `index`, margens, padding, gravity, weight e regras específicas de layout.

Enquanto o Flutter continuar tratando o editor como um `Stack` absoluto, o comportamento nunca será idêntico ao Sketchware em pontos críticos como:

- soltar widget dentro de containers;
- reordenar widgets;
- mover componentes existentes;
- respeitar `LinearLayout`, `RelativeLayout`, `ScrollView`, `FrameLayout` e derivados;
- preservar corretamente projetos salvos no formato Sketchware;
- mostrar o indicador real de inserção durante o drag.

## Arquivos analisados

### Projeto Flutter

| Arquivo | Responsabilidade | Problemas encontrados |
| --- | --- | --- |
| `Dev Studio/lib/project_editor_screen.dart` | Tela principal do editor Flutter, canvas, paleta, drag-and-drop, lixeira e propriedades | Responsabilidade concentrada demais; canvas fixo; drop simplificado; lixeira e feedback visual diferentes do Sketchware |
| `Dev Studio/lib/models/editor_project.dart` | Modelo dos projetos e widgets do editor Flutter | Modelo simplificado baseado em coordenadas absolutas; não representa completamente `LayoutBean`, `parentAttributes`, gravity, margins e regras de layout |
| `Dev Studio/android/app/src/main/kotlin/com/devstudio/dev_studio/MainActivity.kt` | Ponte Android para ler/salvar dados do projeto Sketchware | Conversão de `marginLeft`/`marginTop` para `x`/`y`, causando perda semântica da estrutura original |
| `Dev Studio/lib/services/sketchware_project_service.dart` | Serviço Flutter para comunicação com Android nativo | Apenas transporta JSON simplificado; depende do modelo incompleto do editor |

### Sketchware original

| Arquivo | Responsabilidade no Sketchware | Observação |
| --- | --- | --- |
| `ViewEditorFragment.java` | Coordena a aba View, paleta, histórico e integração com propriedades | Referência oficial do fluxo da aba de edição visual |
| `ViewEditor.java` | Implementa drag-and-drop, toque longo, dummy view, lixeira e seleção | Referência oficial do comportamento de arraste |
| `ViewPane.java` | Calcula canvas, zonas de drop, placeholder, parent/index e renderização da hierarquia | Referência principal para reproduzir o comportamento real |
| `ViewDummy.java` | Representa o componente fantasma durante o drag | O Flutter ainda não replica esse feedback |
| `view_editor.xml` | Layout oficial do editor, paleta, preview e lixeira | Define medidas e posição visual da interface |
| `palette_widget.xml` e `widget_layout.xml` | Layout oficial dos itens da paleta | Define altura, ícones, texto, padding e espaçamento |

## 1. Sistema de Drag and Drop

### Estado atual

O Flutter usa `LongPressDraggable` para arrastar widgets da paleta e widgets já existentes no canvas. O Sketchware também usa toque longo, mas o controle é manual e mais preciso.

No Sketchware:

- o drag inicia após delay controlado;
- o movimento antes do tempo mínimo cancela o drag;
- a paleta tem scroll bloqueado durante o arraste;
- o componente original pode ficar invisível durante o movimento;
- é criada uma imagem fantasma do widget;
- o sistema vibra se a preferência estiver ativa;
- o `ViewPane` recalcula continuamente onde o item pode ser inserido;
- a lixeira aparece e muda de estado conforme hover;
- o placeholder aparece exatamente no ponto de inserção.

No Flutter:

- o drag depende do comportamento padrão do Flutter;
- o feedback é um widget com `Material` e elevação;
- a movimentação calcula posição absoluta;
- o alvo é detectado por retângulo;
- não existe placeholder estrutural igual ao `highlightedTextView`;
- a reordenação é simplificada;
- a árvore real de layout não é usada como fonte principal do comportamento.

### Diferenças

| Item | Sketchware original | Flutter atual | Resultado |
| --- | --- | --- | --- |
| Início do arraste | Touch manual com delay, limite de movimento e cancelamento | `LongPressDraggable` padrão | Parcial |
| Feedback visual | Dummy bitmap translúcido com estado permitido/proibido | Widget elevado/translúcido | Incompatível |
| Sombra | Controlada pela dummy view e estado visual original | `Material` com elevação | Parcial |
| Área de soltura | Calculada por `ViewPane` com profundidade e hierarquia | Detectada por retângulo de layout | Incompatível |
| Posição após soltar | Definida por `parent`, `index` e `LayoutParams` | Definida por `x/y` absoluto | Incompatível |
| Mover componente existente | Atualiza parent/index e histórico | Atualiza coordenadas e parent simplificado | Parcial |
| Reordenação | Placeholder real no layout | Índice simples, sem placeholder equivalente | Incompatível |
| Indicações visuais | Highlight inserido no container alvo | Feedback genérico | Incompatível |

## 2. Fragment View / Canvas

### Estado atual

O canvas Flutter usa tamanho lógico fixo de aproximadamente `360x640`, escala por `Transform.scale` e renderiza widgets dentro de um `Stack`.

O Sketchware calcula a área de preview de forma dinâmica, considerando:

- largura da paleta;
- altura disponível;
- status bar;
- toolbar;
- orientação;
- barra inferior;
- proporção real do preview;
- root layout do projeto;
- containers filhos;
- propriedades reais dos layouts.

### Problemas

| Problema | Impacto | Arquivo Flutter |
| --- | --- | --- |
| Canvas fixo | O preview não acompanha o cálculo visual do Sketchware | `project_editor_screen.dart` |
| Grid artificial | O Sketchware não usa esse grid como base do editor original | `project_editor_screen.dart` |
| Renderização absoluta | Containers não se comportam como Android real | `project_editor_screen.dart` |
| Inserção sem placeholder real | Usuário não vê o ponto exato de inserção | `project_editor_screen.dart` |
| Seleção simplificada | Propriedades e destaque não seguem completamente o Sketchware | `project_editor_screen.dart` |

### Conclusão

O canvas precisa ser refeito para renderizar uma árvore de layout equivalente ao Sketchware. O uso atual de `Stack` absoluto deve deixar de ser a fonte principal da verdade.

## 3. Menu de Widgets

### Referência do Sketchware

O Sketchware usa uma paleta lateral compacta, com largura aproximada de `120dp`, itens densos, ícones pequenos e texto reduzido. Os itens são organizados em grupos como Layouts, AndroidX, Widgets, List, Library, Google e Date & Time.

### Flutter atual

O Flutter possui uma paleta funcional e organizada por categorias, mas visualmente mais espaçada e menos fiel.

| Item | Sketchware | Flutter | Compatibilidade |
| --- | --- | --- | --- |
| Largura da paleta | Aproximadamente 120dp | Mais larga | Parcial |
| Altura dos itens | Compacta | Maior | Parcial |
| Ícones | Pequenos, próximos de 14dp nos itens | Maiores/modernizados | Parcial |
| Tipografia | Pequena e densa | Mais espaçada | Parcial |
| Padding | Baixo | Mais confortável | Parcial |
| Organização | Baseada na lista original do Sketchware | Parecida, mas não idêntica | Parcial |

## 4. Lixeira

### Comportamento esperado

No Sketchware, a lixeira aparece apenas quando um item está sendo arrastado. Ela fica na parte inferior central, entra com animação, muda visualmente quando o item está sobre ela e pode executar animação de shake.

### Flutter atual

O Flutter mostra uma área inferior de exclusão durante o drag de widgets existentes. Porém o comportamento é mais simples e não cobre todos os estados do Sketchware.

| Item | Sketchware | Flutter | Compatibilidade |
| --- | --- | --- | --- |
| Aparece durante drag | Sim | Parcialmente | Parcial |
| Some ao terminar drag | Sim | Sim | Compatível parcial |
| Posição | Inferior central, card animado | Barra/container inferior | Incompatível visual |
| Animação | `translationY`, overshoot, shake | `AnimatedContainer` simples | Incompatível |
| Hover | Muda cor/texto e estado | Muda estado simples | Parcial |

## 5. Feedback visual

O Flutter possui sombras, bordas e seleção, mas a experiência ainda não é equivalente.

### Diferenças principais

- O Sketchware usa dummy bitmap translúcido; Flutter usa widget reconstruído.
- O Sketchware mostra ícone de proibido quando o drop não é permitido; Flutter não replica completamente.
- O Sketchware insere placeholder real no container; Flutter não.
- O Sketchware altera a lixeira com animação e shake; Flutter usa feedback simplificado.
- O Sketchware trabalha com destaque do item selecionado integrado ao painel de propriedades; Flutter usa painel próprio.

## 6. Hierarquia de Layout

### Sketchware

O Sketchware trabalha com uma árvore real:

- root layout;
- `LinearLayout`;
- `RelativeLayout`;
- `ScrollView`;
- `HorizontalScrollView`;
- `FrameLayout`;
- `CardView`;
- containers filhos;
- widgets;
- `ViewBean`;
- `LayoutBean`;
- `parent`;
- `index`;
- `preParent`;
- `preIndex`;
- margins;
- padding;
- gravity;
- layoutGravity;
- weight;
- regras relativas.

### Flutter

O Flutter usa um modelo simplificado:

- lista de nós;
- `id`;
- `type`;
- `parentId`;
- `parentType`;
- `index`;
- `x`;
- `y`;
- `width`;
- `height`;
- algumas propriedades visuais.

### Problema central

O modelo Flutter não possui informações suficientes para reproduzir fielmente o comportamento estrutural do Sketchware.

## 7. Sistema de Coordenadas

Este é o problema mais crítico.

No Sketchware, `marginLeft` e `marginTop` não significam coordenada absoluta no canvas. Eles fazem parte do `LayoutParams` do widget dentro de um container específico.

No Flutter, esses valores estão sendo usados como se fossem `x` e `y`. Isso gera diferença em:

- containers aninhados;
- layouts horizontais;
- layouts verticais;
- `RelativeLayout`;
- scrolls;
- widgets com gravity;
- widgets com margins;
- reordenação;
- salvamento e reabertura do projeto.

### Exemplo conceitual

Em um `LinearLayout` vertical, a posição real de um filho depende da ordem dos filhos anteriores, altura, margins e padding do parent. No Flutter atual, o filho é simplesmente colocado em uma posição absoluta. Isso muda completamente o comportamento.

## Problemas detalhados

| Gravidade | Título | Descrição | Impacto | Arquivos envolvidos | Solução recomendada |
| --- | --- | --- | --- | --- | --- |
| Alta | Modelo de coordenadas incompatível | Uso de `x/y` absoluto no Flutter | Layout salvo pode não bater com Sketchware | `project_editor_screen.dart`, `editor_project.dart`, `MainActivity.kt` | Usar árvore `ViewBean/LayoutBean` como fonte da verdade |
| Alta | Drop simplificado | Detecção por retângulo não replica `ViewPane` | Drop em containers fica incorreto | `project_editor_screen.dart` | Implementar zonas de drop por hierarquia |
| Alta | Reordenação incompleta | Índice não é calculado como no Sketchware | Ordem dos widgets pode ficar errada | `project_editor_screen.dart` | Criar placeholder estrutural e cálculo de índice real |
| Alta | Canvas fixo | Preview usa `360x640` | Escala e alinhamento diferentes | `project_editor_screen.dart` | Recriar cálculo dinâmico do preview |
| Alta | `RelativeLayout` incompleto | Regras relativas não são aplicadas | Layouts complexos ficam errados | `editor_project.dart`, `project_editor_screen.dart` | Implementar `parentAttributes` e regras relativas |
| Alta | Serialização com perda de dados | Ponte converte margins em coordenadas | Projeto salvo perde fidelidade | `MainActivity.kt` | Preservar `LayoutBean` completo |
| Média/Alta | Feedback de drag diferente | Não usa dummy bitmap igual ao Sketchware | UX diferente | `project_editor_screen.dart` | Criar feedback próprio inspirado em `ViewDummy` |
| Média/Alta | Lixeira incompleta | Visual e animação diferentes | UX diferente | `project_editor_screen.dart` | Recriar card inferior animado |
| Média | Paleta com dimensões diferentes | Largura, ícones, padding e fonte divergentes | Visual menos fiel | `project_editor_screen.dart` | Ajustar medidas conforme XML original |
| Média | Propriedades simplificadas | Painel não reproduz `ViewProperty` | Edição visual incompleta | `project_editor_screen.dart` | Recriar painel e animações |
| Média | Scroll containers incompletos | Scroll não é controlado como no drag original | Drop em scrolls pode falhar | `project_editor_screen.dart` | Bloquear scroll durante drag e recalcular zonas |
| Baixa | Grid artificial | Visual não existe como base no Sketchware | Diferença estética | `project_editor_screen.dart` | Remover ou tornar opcional |

## Checklist final

| Item | Compatível | Parcial | Incompatível |
| --- | --- | --- | --- |
| Início do arraste |  | X |  |
| Feedback visual durante arraste |  |  | X |
| Sombra do componente |  | X |  |
| Área de soltura |  |  | X |
| Posicionamento após soltura |  |  | X |
| Mover componentes existentes |  | X |  |
| Reordenação de componentes |  |  | X |
| Indicações visuais durante drag |  |  | X |
| Estrutura visual do canvas |  |  | X |
| Espaçamentos do canvas |  | X |  |
| Margens e alinhamentos |  |  | X |
| Grid interno |  |  | X |
| Inserção de widgets |  |  | X |
| Seleção de widgets |  | X |  |
| Destaques visuais |  | X |  |
| Menu de widgets |  | X |  |
| Lixeira aparece durante drag |  | X |  |
| Lixeira some ao finalizar drag | X |  |  |
| Animação da lixeira |  |  | X |
| Hierarquia de layout |  |  | X |
| Sistema de coordenadas |  |  | X |
| View/Event/Component/Strings |  | X |  |

## Plano de correção

### Prioridade alta

1. Trocar o modelo interno do editor para árvore compatível com `ViewBean` e `LayoutBean`.
2. Parar de usar `x/y` como fonte principal da verdade.
3. Implementar algoritmo de drop equivalente ao `ViewPane`.
4. Criar placeholder real durante drag.
5. Implementar reordenação por `parent/index/preParent/preIndex`.
6. Recriar o canvas com preview responsivo semelhante ao Sketchware.
7. Preservar `LayoutBean`, margins, gravity, weight e regras relativas na ponte Android.

### Prioridade média

1. Recriar visual e animação da lixeira.
2. Recriar feedback de drag semelhante ao `ViewDummy`.
3. Ajustar paleta para largura e medidas originais.
4. Implementar renderizadores específicos para `LinearLayout`, `RelativeLayout`, `ScrollView`, `FrameLayout` e `CardView`.
5. Recriar painel de propriedades com comportamento próximo do Sketchware.

### Prioridade baixa

1. Ajustar cores, fontes, bordas e sombras.
2. Remover ou tornar opcional o grid.
3. Refinar microespaçamentos da toolbar, abas e barra inferior.
4. Ajustar animações pequenas e transições.

## Conclusão técnica

O editor Flutter está funcional como uma primeira versão visual, mas ainda não é uma reprodução fiel do Sketchware. A diferença não é apenas estética. O problema principal está no modelo estrutural.

Para alcançar fidelidade real, o próximo passo deve ser reconstruir o núcleo do editor em Flutter com base no mesmo conceito do Sketchware:

- árvore de componentes;
- layout params;
- parent/index;
- zonas de drop calculadas;
- placeholder real;
- renderização por tipo de container;
- serialização sem perda para o formato original.

Somente depois disso faz sentido ajustar pixels, cores, sombras e animações finas.
