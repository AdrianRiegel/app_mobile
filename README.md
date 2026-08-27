# app_mobile

## Configuração do Firebase

### 1. Criar o projeto no Firebase Console

1. Acesse o [Firebase Console](https://console.firebase.google.com) e clique em **Adicionar projeto**.
2. Ative o **Firebase Authentication** → método de login **E-mail/senha**.
3. Ative o **Cloud Firestore** → modo de produção (ajuste as regras conforme necessário).

Após criar o projeto e adicionar os dois aplicativos (Android e iOS), a seção **Seus aplicativos** no Firebase Console deve estar assim:

<img width="606" height="444" alt="image" src="https://github.com/user-attachments/assets/d37df53d-4f17-418c-8d6e-3f2085394873" />
[Aplicativos configurados no Firebase Console]

### 2. Gerar o arquivo de configuração para Android

1. No console do Firebase, acesse **Configurações do projeto → Seus aplicativos → Adicionar aplicativo → Android**.
2. Informe o nome do pacote (encontrado em `android/app/build.gradle`, campo `applicationId`).
3. Faça o download do arquivo `google-services.json`.
4. Coloque-o em `android/app/google-services.json`.
5. Verifique se `android/build.gradle` contém o plugin:
   ```groovy
   classpath 'com.google.gms:google-services:4.x.x'
   ```
6. Verifique se `android/app/build.gradle` aplica o plugin no final:
   ```groovy
   apply plugin: 'com.google.gms.google-services'
   ```

### 3. Gerar o arquivo de configuração para iOS

1. No console do Firebase, acesse **Configurações do projeto → Seus aplicativos → Adicionar aplicativo → iOS**.
2. Informe o Bundle ID (encontrado em Xcode → pasta `Runner` → campo `Bundle Identifier`).
3. Faça o download do arquivo `GoogleService-Info.plist`.
4. Abra o projeto iOS no Xcode (`ios/Runner.xcworkspace`) e arraste o arquivo `GoogleService-Info.plist` para dentro da pasta `Runner` (marque a opção **Copy items if needed**).
5. Execute `cd ios && pod install` para atualizar os pods do Firebase.

> **Atenção:** nunca commite `google-services.json` ou `GoogleService-Info.plist` em repositórios públicos — eles contêm chaves de API.

---
