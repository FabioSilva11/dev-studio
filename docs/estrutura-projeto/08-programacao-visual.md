# Programação Visual

Programação visual é um dos pilares do Dev Studio.

Ela permite construir comportamento com blocos gráficos conectáveis, em vez de exigir que o usuário escreva código manualmente.

## Objetivo

Permitir que o usuário descreva ações, condições, navegação e manipulação de dados por meio de elementos visuais.

O sistema deve ser simples no começo, mas precisa nascer com um modelo capaz de crescer.

## Conceitos Principais

### Evento

Um evento liga um alvo a um gatilho.

Exemplos:

- tela abriu;
- botão foi tocado;
- texto mudou;
- item de lista foi selecionado.

Estrutura conceitual:

```txt
Event
  id
  target
  trigger
  blocks[]
```

### Bloco

Um bloco representa uma ação, expressão ou controle de fluxo.

Estrutura conceitual:

```txt
Block
  id
  type
  props
  inputs
  children[]
```

### Ação

Uma ação executa algo.

Exemplos:

- mostrar mensagem;
- navegar para tela;
- alterar texto de um widget;
- alterar visibilidade de um widget;
- salvar valor local;
- chamar serviço/API.

### Controle de Fluxo

Controle de fluxo organiza a execução.

Exemplos:

- se;
- se/senão;
- repetir;
- parar execução.

### Dados

Dados representam valores manipulados pelos blocos.

Exemplos:

- variável local;
- parâmetro de evento;
- texto;
- número;
- booleano;
- resultado de chamada externa;
- estado de tela.

### Expressão

Expressões produzem valores.

Exemplos:

- concatenar texto;
- comparar valores;
- somar números;
- verificar vazio;
- negar booleano.

## Categorias Iniciais de Blocos

### Eventos

- `onScreenStart`
- `onTap`
- `onTextChanged`

### UI

- `showMessage`
- `setWidgetText`
- `setWidgetVisible`
- `setWidgetEnabled`

### Navegação

- `navigateToScreen`
- `goBack`

### Controle

- `if`
- `ifElse`

### Dados

- `setVariable`
- `getVariable`

### Expressões

- `textValue`
- `numberValue`
- `booleanValue`
- `equals`
- `not`

## Exemplo no Schema

```json
{
  "logic": {
    "events": [
      {
        "id": "event_button_start_tap",
        "target": "button_start",
        "trigger": "onTap",
        "blocks": [
          {
            "id": "block_if_1",
            "type": "if",
            "props": {},
            "inputs": {
              "condition": {
                "type": "equals",
                "left": {
                  "type": "getVariable",
                  "name": "acceptedTerms"
                },
                "right": {
                  "type": "booleanValue",
                  "value": true
                }
              }
            },
            "children": [
              {
                "id": "block_navigate_1",
                "type": "navigateToScreen",
                "props": {
                  "screenId": "screen_home"
                },
                "inputs": {},
                "children": []
              }
            ]
          }
        ]
      }
    ]
  }
}
```

## Relação Com MVVM

A programação visual não deve gerar código solto diretamente a partir da UI.

O fluxo desejado é:

```txt
Blocos visuais -> Modelo de lógica -> UseCases/gerador -> Código MVVM
```

Quando o Dev Studio gerar um projeto Flutter, os blocos devem ser convertidos para código compatível com a arquitetura gerada:

```txt
UI -> ViewModel -> UseCase -> Repository -> Service
```

Exemplo:

- bloco `showMessage`: pode virar evento de UI ou efeito de ViewModel;
- bloco `navigateToScreen`: pode virar comando de navegação;
- bloco `callApi`: deve passar por UseCase, Repository e Service;
- bloco `setVariable`: pode atualizar estado no ViewModel.

## Fora do MVP

O MVP não precisa ter editor completo de blocos nem execução real.

O que precisa existir desde o início:

- schema preparado para `logic.events`;
- tipos conceituais documentados;
- decisão de não salvar lógica como código textual solto;
- caminho claro para geração futura.

