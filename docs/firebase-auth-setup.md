# Guia de Configuração do Firebase Auth

Este documento orienta a criação e configuração do Firebase para autenticação no projeto Dev Studio.

Escopo desta fase:

- Firebase Authentication
- Provedor Email/Senha
- Integração Android e iOS
- Validação local (simulador iOS e execução Flutter)

## Contexto do Projeto

Identificadores atuais usados pelo app:

- Android Application ID: `com.devstudio.dev_studio`
- iOS Bundle ID: `com.devstudio.devStudio`

Arquivo de inicialização atual:

- `lib/main.dart` chama `Firebase.initializeApp()`

## Pré-requisitos

- Conta Google com acesso ao Firebase Console.
- Permissão para criar projeto Firebase (Owner ou Editor).
- Flutter SDK instalado.
- Projeto local compilando.

Opcional (recomendado):

- Apple Developer para distribuição em device físico.

## 1) Criar Projeto no Firebase Console

1. Acessar https://console.firebase.google.com.
2. Clicar em **Add project**.
3. Nome sugerido: `dev-studio`.
4. Decidir sobre Google Analytics (pode desabilitar neste momento).
5. Finalizar criação.

## 2) Habilitar Authentication

1. No menu do projeto Firebase, abrir **Build > Authentication**.
2. Clicar em **Get started**.
3. Em **Sign-in method**, habilitar **Email/Password**.
4. Salvar.

## 3) Registrar o App Android no Firebase

1. Em **Project settings > General**, clicar em **Add app** e escolher Android.
2. Informar:
   - Android package name: `com.devstudio.dev_studio`
   - App nickname: opcional
   - SHA-1/SHA-256: opcional nesta fase (necessário para Google Sign-In e alguns fluxos avançados)
3. Registrar app.

## 4) Registrar o App iOS no Firebase

1. Em **Project settings > General**, clicar em **Add app** e escolher iOS.
2. Informar:
   - iOS bundle ID: `com.devstudio.devStudio`
   - App nickname: opcional
3. Registrar app.

## 5) Configurar Projeto Flutter (recomendado com FlutterFire CLI)

### 5.1 Instalar/atualizar CLI

```bash
dart pub global activate flutterfire_cli
```

### 5.2 Fazer login no Firebase (se necessário)

```bash
firebase login
```

### 5.3 Gerar configuração para Android e iOS

Na raiz do projeto:

```bash
flutterfire configure \
  --project=<FIREBASE_PROJECT_ID> \
  --platforms=android,ios \
  --android-package-name=com.devstudio.dev_studio \
  --ios-bundle-id=com.devstudio.devStudio
```

Resultado esperado:

- Criação/atualização de `lib/firebase_options.dart`.
- Criação dos arquivos nativos de configuração (Android/iOS) quando aplicável.

## 6) Ajuste de Inicialização no Flutter

Após gerar `firebase_options.dart`, alterar a inicialização para usar opções explícitas por plataforma.

Padrão recomendado:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Motivo: reduz problemas de ambiente e mantém configuração centralizada.

## 7) Dependências no Pubspec

Dependências já previstas no projeto:

- `firebase_core`
- `firebase_auth`

Executar:

```bash
flutter pub get
```

## 8) Validação Técnica

### 8.1 Análise estática

```bash
flutter analyze
```

### 8.2 Executar no iOS local (simulador)

```bash
make ios-local-run
```

ou

```bash
flutter run -d "iPhone 15"
```

### 8.3 Build local iOS simulador

```bash
make ios-local-build
```

## 9) Checklist de Entrega

- Projeto criado no Firebase.
- Email/Senha habilitado em Authentication.
- App Android registrado com `com.devstudio.dev_studio`.
- App iOS registrado com `com.devstudio.devStudio`.
- `flutterfire configure` executado com sucesso.
- `lib/firebase_options.dart` criado no projeto.
- Inicialização no `main.dart` usando `DefaultFirebaseOptions.currentPlatform`.
- App rodando localmente no simulador iOS com Firebase inicializado.

## 10) Erros Comuns e Como Resolver

### Erro de bundle/package não correspondente

- Sintoma: falha de inicialização Firebase em runtime.
- Ação: confirmar IDs no Firebase Console e no projeto:
  - Android: `android/app/build.gradle.kts`
  - iOS: `ios/Runner.xcodeproj/project.pbxproj`

### Erro no `Firebase.initializeApp()`

- Sintoma: exceção de app não configurado.
- Ação: confirmar que `flutterfire configure` gerou `lib/firebase_options.dart` e que o `main.dart` usa `DefaultFirebaseOptions.currentPlatform`.

### Build iOS em device físico falha por provisioning

- Sintoma: erro de signing/profile.
- Ação: para desenvolvimento local, usar simulador (`make ios-local-run`).

## 11) Responsabilidades Recomendadas

- Time de plataforma/infra:
  - criação do projeto no Firebase;
  - configuração dos apps Android/iOS;
  - gestão de permissões no console.
- Time de app:
  - integração FlutterFire;
  - adaptação do bootstrap de inicialização;
  - validação funcional de login/registro.
