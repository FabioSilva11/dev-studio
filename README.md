# Dev Studio

[![Build APK](https://github.com/FabioSilva11/dev-studio/actions/workflows/release-apk.yml/badge.svg)](https://github.com/FabioSilva11/dev-studio/actions/workflows/release-apk.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Platform](https://img.shields.io/badge/platform-Android-green.svg)]()
[![Made with Flutter](https://img.shields.io/badge/made%20with-Flutter-blue.svg)](https://flutter.dev)

> **Construtor visual de apps Android — direto no celular.**
> Inspirado no Sketchware, reescrito do zero com Flutter e uma nova visao de experiencia.

---

## Por que este projeto existe?

O Sketchware foi um divisor de aguas: permitiu que pessoas sem computador criassem apps Android reais usando apenas o celular. Mas a experiencia de uso ficou datada.

O **Dev Studio** nasce com a missao de recriar essa experiencia com uma interface moderna, modular e extensivel — mantendo total compatibilidade com os projetos do Sketchware original.

Se voce chegou aqui pelo LinkedIn, bem-vindo! Este e um projeto open source em crescimento ativo e **estamos buscando contribuidores** que queiram construir algo que pode impactar a vida de quem aprende a programar sem acesso a um computador.

---

## Interface

<table>
  <tr>
    <td align="center"><strong>Criar Novo Projeto</strong></td>
    <td align="center"><strong>Editor de Layout</strong></td>
    <td align="center"><strong>Editor de Eventos</strong></td>
  </tr>
  <tr>
    <td><img src="docs/images/create-new-screen.png" alt="Criar Novo" width="260"/></td>
    <td><img src="docs/images/layout-editor.png" alt="Editor de Layout" width="260"/></td>
    <td><img src="docs/images/events-editor.png" alt="Editor de Eventos" width="260"/></td>
  </tr>
</table>

---

## Objetivos Concretos

### Fase 1 — Base funcional ✅ (em andamento)
- [x] Listagem de projetos com busca, ordenacao e favoritos
- [x] Leitura de projetos existentes do Sketchware Pro
- [x] Criacao de novos projetos (nome, pacote, icone, tema, versao)
- [x] Editor visual com canvas, arrastar e soltar, arvore de hierarquia
- [x] Paleta de widgets modular (LinearLayout, Button, TextView, EditText, ImageView...)
- [x] Gerenciamento de Eventos, Componentes e Strings
- [x] Barra de selecao estilo Sketchware com atalhos rapidos de propriedades
- [x] Gerenciador de Views/Activities com preview ao vivo

### Fase 2 — Alinhamento total com o Sketchware ⚙️ (proximos passos)
- [ ] Compatibilidade 100% com o modelo de dados `ViewBean` / `LayoutBean` do Sketchware
- [ ] Editor de logica de blocos (eventos, variaveis, chamadas de funcao)
- [ ] Suporte completo a componentes (Firebase, SharedPreferences, SQLite...)
- [ ] Gerenciador de recursos (imagens, sons, fontes, arquivos raw)
- [ ] Editor de manifest e permissoes Android

### Fase 3 — Geracao de codigo real 🚀 (objetivo final)
- [ ] **Geracao de codigo Java** — etapa atual de implementacao; o compilador ja gera codigo Java compativel com o Sketchware
- [ ] **Migracao para Kotlin** — apos alinhar completamente o modelo de dados e a logica de compilacao ao Sketchware original, o gerador de codigo sera atualizado para Kotlin moderno
- [ ] Compilacao on-device via integracoes nativas
- [ ] Assinatura e publicacao de APK direto pelo app

> **Nota tecnica:** A geracao de codigo esta em Java neste momento por ser o formato que o Sketchware Pro utiliza nativamente. Quando o nucleo do editor estiver 100% alinhado ao Sketchware, faremos a transicao para Kotlin como linguagem padrao de saida.

---

## Tecnologias

| Camada | Tecnologia |
|---|---|
| UI / Framework | Flutter (Dart) + Material 3 |
| Native Bridge | MethodChannel (Kotlin) |
| Leitura de projetos | SketchwareProjectService via armazenamento Android |
| Compilacao | Geracao de codigo Java (Kotlin planejado) |
| CI/CD | GitHub Actions → APK release automatico |

---

## Como Executar Localmente

### Requisitos

- Flutter SDK `>= 3.x`
- Android Studio ou SDK Android configurado
- Dispositivo Android ou emulador (API 21+)

### Passos

```bash
git clone https://github.com/FabioSilva11/dev-studio.git
cd dev-studio
flutter pub get
flutter run
```

### Gerar APK

```bash
# Release (arm64)
flutter build apk --release --target-platform android-arm64

# Debug
flutter build apk --debug
```

Toda versao enviada para `main` gera automaticamente um APK publicado em [Releases](https://github.com/FabioSilva11/dev-studio/releases) via GitHub Actions.

---

## Estrutura do Projeto

```text
lib/
  main.dart                     # Entrada da aplicacao
  main_screen.dart              # Tela principal / listagem de projetos
  project_creation_screen.dart  # Criar novo projeto
  project_editor_screen.dart    # Editor principal (orquestrador)
  models/                       # EditorProject, ProjectItem, etc.
  services/                     # SketchwareProjectService
  widgets/
    editor_canvas.dart          # Canvas com arvore de hierarquia
    editor_list_tabs.dart       # Abas Eventos / Componentes / Strings
    editor_palette.dart         # Paleta lateral de widgets
    property_editor.dart        # Editor de propriedades (bottom sheet)
    sketchware_bottom_bar.dart  # Barra inferior estilo Sketchware
    view_manager.dart           # Gerenciador de Views/Activities
android/                        # Codigo nativo Kotlin + manifest
assets/                         # Recursos estaticos
test/                           # Testes automatizados
```

---

## Como Contribuir

Contribuicoes sao muito bem-vindas! Se voce chegou pelo LinkedIn e tem interesse em participar:

1. **Fork** este repositorio
2. Crie uma branch descritiva: `git checkout -b feat/nome-da-feature`
3. Faca suas alteracoes e commite: `git commit -m "feat: descricao clara"`
4. Abra um **Pull Request** descrevendo o que foi feito e por que

### Onde posso ajudar?

- 🎨 **UI/UX** — melhorar o canvas, animacoes, responsividade
- 🧩 **Novos widgets** — adicionar suporte a mais componentes do Sketchware
- ⚙️ **Geracao de codigo** — expandir o compilador Java/Kotlin
- 🧪 **Testes** — aumentar a cobertura de testes automatizados
- 📖 **Documentacao** — melhorar guias, wikis e comentarios no codigo

Para duvidas ou para se apresentar antes de contribuir, abra uma [Discussion](https://github.com/FabioSilva11/dev-studio/discussions) ou uma [Issue](https://github.com/FabioSilva11/dev-studio/issues).

---

## Estado Atual

O projeto ja possui base funcional solida. O editor visual esta operacional com suporte a hierarquia de widgets, propriedades de layout (margens, padding, gravity, peso), arrastar e soltar, undo/redo, e gerenciamento de Views.

A proxima grande etapa e completar o alinhamento do modelo de dados interno com o formato nativo do Sketchware Pro para garantir leitura e escrita perfeitas de projetos existentes.

---

## Licenca

MIT © [FabioSilva11](https://github.com/FabioSilva11)
