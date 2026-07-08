# Changelog

## 2026/07/07 - project/adjustments-01

### Resumo
- Reestruturação ampla do projeto para arquitetura em camadas (core, data, domain, ui).
- Migração de autenticação para Firebase (fase inicial com login, cadastro e logout).
- Ajustes de build iOS para execução local em simulador e build de device sem bloqueio de provisioning.
- Atualização da documentação técnica e criação de guia operacional para setup do Firebase.

### Adicionado
- Estrutura iOS completa do app em ios/ (Runner, workspace, assets e configurações de build).
- Nova base arquitetural em lib/core, lib/data, lib/domain e lib/ui.
- Serviço e repositório de autenticação com Firebase em:
  - lib/data/services/auth/auth_service.dart
  - lib/data/repositories/auth/auth_repository.dart
  - lib/data/repositories/auth/auth_repository_impl.dart
- Modelo de usuário da autenticação em:
  - lib/domain/common/auth/models/app_user.dart
- Guia de configuração Firebase para repasse:
  - docs/firebase-auth-setup.md

### Alterado
- Inicialização do app para suportar Firebase em:
  - lib/main.dart
- Dependências do projeto em:
  - pubspec.yaml
  - pubspec.lock
- Fluxo de comandos para build iOS no Makefile com targets locais:
  - ios-local-build
  - ios-local-run
  - ios-sim
  - ios-device
  - ios-device-no-sign
- Documentação de arquitetura e roadmap em:
  - docs/estrutura-projeto/README.md
  - docs/estrutura-projeto/03-arquitetura-inicial.md
  - docs/estrutura-projeto/05-mvp.md
  - docs/estrutura-projeto/06-roadmap.md
  - docs/estrutura-projeto/07-adr-mvvm-command-result.md
  - docs/estrutura-projeto/08-programacao-visual.md

### Removido
- Implementação antiga de telas/componentes legados em lib/ (main_screen, project_editor, widgets legados).
- Modelos e serviços antigos não alinhados à nova estrutura:
  - lib/models/editor_project.dart
  - lib/models/project_item.dart
  - lib/services/sketchware_project_service.dart
- Testes antigos não compatíveis com a nova base:
  - test/main_screen_test.dart
  - test/widget_test.dart

### iOS
- Ajustado deployment target para iOS 15.0 (compatível com firebase_auth/firebase_core).
- Build validado para simulador e para device sem assinatura obrigatória.

### Observações
- Build para device físico com assinatura Apple ainda depende de provisioning profile quando houver necessidade de deploy em hardware real.
- O foco atual está em execução local e evolução funcional da base de autenticação.
