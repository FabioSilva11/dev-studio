# Schema do Projeto

Este documento descreve o formato persistido de um projeto Dev Studio.

Ele responde à pergunta:

```txt
O que precisa existir dentro de um project.json?
```

O objetivo é ter um schema simples, versionado e independente do formato Sketchware.

Este documento não descreve necessariamente as classes internas em Dart. As classes do domínio devem ser compatíveis com este schema, mas podem evoluir com mais liberdade desde que a camada de serialização preserve compatibilidade.

## Regras do Schema

- Todo projeto salvo deve possuir `schemaVersion`.
- O arquivo salvo deve ser independente de estado de UI.
- O formato deve favorecer leitura, migração e depuração manual.
- Mudanças incompatíveis devem gerar nova versão de schema.
- Dados importados de outros formatos devem ser convertidos para este schema antes de edição.
- O projeto original importado não deve ser usado como fonte persistida principal.

## Estrutura Persistida

```txt
DevStudioProject
  id
  name
  packageName
  version
  theme
  screens[]
  logic
  assets[]
  createdAt
  updatedAt

DevStudioScreen
  id
  name
  root

DevStudioWidgetNode
  id
  type
  props
  children[]

DevStudioLogic
  events[]

DevStudioEvent
  id
  target
  trigger
  blocks[]

DevStudioBlock
  id
  type
  props
  inputs
  children[]
```

## Arquivo Principal

No MVP, o projeto pode ser armazenado em um único arquivo:

```txt
project.json
```

No futuro, o projeto pode evoluir para uma pasta com múltiplos arquivos:

```txt
project.json
screens/
assets/
generated/
```

Essa divisão futura não deve alterar o contrato lógico do schema. Ela apenas distribui os dados fisicamente.

## Exemplo JSON

```json
{
  "schemaVersion": 1,
  "id": "project_001",
  "name": "Meu App",
  "packageName": "com.example.meuapp",
  "version": {
    "name": "1.0.0",
    "code": 1
  },
  "theme": {
    "primaryColor": "#6750A4",
    "backgroundColor": "#FFFFFF"
  },
  "screens": [
    {
      "id": "screen_home",
      "name": "Home",
      "root": {
        "id": "root",
        "type": "column",
        "props": {
          "padding": 16,
          "backgroundColor": "#FFFFFF"
        },
        "children": [
          {
            "id": "title",
            "type": "text",
            "props": {
              "text": "Olá, Dev Studio",
              "fontSize": 22,
              "color": "#111111"
            },
            "children": []
          },
          {
            "id": "button_start",
            "type": "button",
            "props": {
              "text": "Começar"
            },
            "children": []
          }
        ]
      }
    }
  ],
  "logic": {
    "events": [
      {
        "id": "event_button_start_tap",
        "target": "button_start",
        "trigger": "onTap",
        "blocks": [
          {
            "id": "block_show_message_1",
            "type": "showMessage",
            "props": {
              "message": "Olá!"
            },
            "inputs": {},
            "children": []
          }
        ]
      }
    ]
  },
  "assets": [],
  "createdAt": "2026-07-03T00:00:00Z",
  "updatedAt": "2026-07-03T00:00:00Z"
}
```

## Lógica Visual

O campo `logic` reserva espaço para programação visual por blocos.

No MVP, o editor não precisa executar ou editar blocos completos. Ainda assim, o schema deve nascer preparado para armazenar:

- eventos;
- ações;
- controle de fluxo;
- variáveis;
- expressões;
- chamadas externas.

Eventos ligam um alvo a um gatilho:

```txt
target: button_start
trigger: onTap
```

Blocos descrevem o que acontece quando o evento é executado:

```txt
showMessage
navigateToScreen
setWidgetText
setWidgetVisible
callApi
```

Mais detalhes estão em [08-programacao-visual.md](08-programacao-visual.md).

## Widgets Iniciais

- `column`
- `row`
- `container`
- `text`
- `button`
- `image`
- `textField`

## Propriedades Iniciais

### Layout

- width
- height
- padding
- margin
- alignment
- spacing

### Aparência

- backgroundColor
- borderRadius
- borderColor
- borderWidth

### Texto

- text
- fontSize
- color
- fontWeight

## Observação

O schema deve favorecer árvore de widgets, não coordenadas absolutas.

Coordenadas podem existir no futuro para modos específicos, como layout livre, mas não devem ser a base do editor.

A lógica visual também deve favorecer árvore/lista de blocos estruturados, não código textual salvo como string principal.

## Relação Com o Domínio

O domínio pode ter classes como `DevStudioProject`, `EditorScreen` e `WidgetNode`, mas a persistência não deve depender diretamente de detalhes internos dessas classes.

A conversão deve passar por serviços de serialização, por exemplo:

```txt
ProjectJsonService
  fromJson(Map<String, Object?> json)
  toJson(DevStudioProject project)
```

Isso permite migrar schemas antigos sem contaminar a UI ou os ViewModels.
