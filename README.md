# EduTurmas

Aplicativo mobile em Flutter para gestão de turmas, elaboração de avaliações, captura por câmera e correção inteligente de provas via leitura de cartões de resposta (OMR). Os dados e a autenticação são gerenciados pelo Firebase (Authentication e Cloud Firestore), com isolamento estrito de dados por professor.

---

## 🚀 Funcionalidades Implementadas

### 1. Autenticação e Perfil do Usuário
- **Login, cadastro e recuperação de senha**: Autenticação segura via Firebase Authentication, com persistência da sessão no dispositivo.
- **Página de Perfil e Configurações (`ProfileSettingsScreen`)**:
  - Visualização de avatar com iniciais do professor.
  - Edição de nome completo, instituição/escola e disciplina principal com persistência na collection `usuarios/{uid}` e atualização no Firebase Auth.
  - Exibição protegida (somente leitura) do e-mail de login.
  - Configuração de preferências (notificações por e-mail).
  - Encerramento de sessão (Logout) com diálogo de confirmação.

### 2. Gestão de Turmas e Alunos
- **Cadastro e listagem de turmas**: Controle de descrição, semestre e ano letivo.
- **Gestão de alunos**: Cadastro individual e importação em massa via arquivos CSV (detecção automática de delimitadores vírgula ou ponto-e-vírgula e codificações UTF-8/Latin-1).

### 3. Criação e Edição de Provas e Questões
- **Nova Avaliação (`NewProofScreen`)**:
  - Criação de provas vinculadas à turma, com definição de título, disciplina e data de aplicação.
  - **Adicionar Questão (`#19`)**: Criação dinâmica de questões com enunciado, 4 alternativas (A, B, C, D), definição da alternativa correta e peso.
  - **Editar Questão (`#20`)**: Edição in-place de questões já adicionadas, carregando os dados prévios e preservando o gabarito.
- **Configuração de Gabarito (`AnswerKeyScreen`)**: Visualização e ajuste rápido das respostas oficiais da avaliação.

### 4. Módulo de Câmera (`CameraService` & `CameraCaptureScreen`)
- Integração modular de câmera (`lib/services/camera_service.dart`) com suporte ao ciclo de vida da aplicação.
- Gerenciamento de permissões via `permission_handler` com tratamento amigável de recusa.
- Interface de captura com guia de enquadramento do cartão de resposta, flash/tocha e fallback gracioso para ambientes de teste e desktop.

### 5. Motor de Leitura de Cartão de Respostas (OMR) e Revisão Humana
- **Pesquisa Técnica (`docs/pesquisa_cartao_respostas.md`)**: Estudo detalhado sobre formatos de gabarito, correção de perspectiva, binarização e algoritmos de detecção de bolhas.
- **Motor OMR (`OmrProcessor`)**:
  - Processamento de densidade de marcação com limiares calibrados (`fillThreshold = 0.45`, `blankThreshold = 0.20`).
  - Cálculo do índice de confiança para cada questão e para a folha completa.
  - Detecção automática de ambiguidade (múltiplas marcações na mesma linha) e questões em branco.
- **Tela de Revisão Manual (`OmrReviewScreen`)**:
  - Quando a confiança for insuficiente (< 0.70) ou houver marcações ambíguas, o app apresenta a tela de conferência para o professor confirmar ou corrigir as alternativas antes de gravar a nota.

### 6. Encerramento de Correção com Nota Zero para Ausentes
- **Encerramento Automatizado (`ResultadoRepository.encerrarCorrecao`)**:
  - Identifica automaticamente os alunos da turma que não realizaram a prova.
  - Atribui nota `0.0`, total de acertos `0`, marcação `ausente: true` e preserva integralmente as notas dos alunos que compareceram.
  - Atualiza o status da avaliação para concluída (`AssessmentStatus.completed`).
  - Confirmação modal com aviso detalhado na tela de detalhes da avaliação (`AssessmentDetailScreen`).

### 7. Estatísticas e Relatórios de Desempenho
- **Estatísticas gerais**: Média de acertos por turma e visão consolidada das avaliações.
- **Estatísticas detalhadas da prova**: Taxa média de acerto, identificação da questão com maior índice de erro e gráficos de acertos por questão.
- **Relatório em PDF**: Visualização e geração de relatório de desempenho.

---

## 📱 Telas do Aplicativo

| | | |
|---|---|---|
| **Login** | **Cadastro** | **Redefinir Senha** |
| ![Login](docs/screenshots/01_login.png) | ![Cadastro](docs/screenshots/02_cadastro.png) | ![Redefinir senha](docs/screenshots/03_redefinir_senha.png) |
| **Painel Inicial** | **Turmas** | **Detalhe da Turma** |
| ![Dashboard](docs/screenshots/04_dashboard.png) | ![Turmas](docs/screenshots/05_turmas.png) | ![Detalhe da turma](docs/screenshots/06_detalhe_turma.png) |
| **Avaliações** | **Nova Avaliação / Questões** | **Detalhe da Avaliação** |
| ![Avaliações](docs/screenshots/07_avaliacoes.png) | ![Nova avaliação](docs/screenshots/08_nova_avaliacao.png) | ![Detalhe da avaliação](docs/screenshots/09_detalhe_avaliacao.png) |
| **Configurar Gabarito** | **Correção OMR / Câmera** | **Estatísticas Gerais** |
| ![Gabarito](docs/screenshots/10_gabarito.png) | ![Correção](docs/screenshots/11_correcao.png) | ![Estatísticas](docs/screenshots/12_estatisticas.png) |
| **Estatísticas da Prova** | **Relatório** | |
| ![Estatísticas da prova](docs/screenshots/13_estatisticas_prova.png) | ![Relatório](docs/screenshots/14_relatorio.png) | |

---

## 🗄️ Estrutura do Banco de Dados e Segurança

O banco de dados oficial é o **Cloud Firestore**, documentado detalhadamente em [`docs/database_schema.md`](docs/database_schema.md).

### Coleções:
1. `usuarios`: Perfil do professor (`nome`, `email`, `escola`, `disciplinaPrincipal`, `notificacoesEmail`, `criadoEm`, `ativo`). O ID do documento é o `uid` do Firebase Auth.
2. `turmas`: `professorId`, `descricao`, `semestre`, `ano`, `totalAlunos`, `criadoEm`.
3. `alunos`: `professorId`, `turmaId`, `nome`, `matricula`, `criadoEm`.
4. `avaliacoes`: `professorId`, `turmaId`, `titulo`, `disciplina`, `status`, `dataAplicacao`, `gabarito`, `criadoEm`.
5. `resultados`: `professorId`, `turmaId`, `avaliacaoId`, `alunoId`, `respostasAluno`, `totalAcertos`, `notaCalculada`, `ausente`, `corrigidoEm`.

### Regras de Segurança e Índices:
- **`firestore.rules`**: Políticas de controle de acesso baseadas em `request.auth.uid == resource.data.professorId`, impedindo acessos indevidos entre contas diferentes.
- **`firestore.indexes.json`**: Índices compostos pré-configurados para consultas eficientes no Firestore.
- **`SchemaValidator`**: Validador de integridade e schema relacional em `lib/services/database/schema_validator.dart`.

---

## 🛠️ Tecnologias e Dependências

- **Flutter SDK**: 3.47+ / Dart SDK: 3.13+
- **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`
- **Câmera & Permissões**: `camera`, `permission_handler`
- **Utilitários**: `file_picker`, `flutter_dotenv`, `mailer`
- **Testes & Fakes**: `flutter_test`, `fake_cloud_firestore`

---

## 💻 Como Executar

### Pré-requisitos
1. Flutter SDK instalado e configurado no PATH.
2. Dispositivo físico com depuração USB ou emulador Android/iOS iniciado.

### 1. Clonar e Instalar Dependências
```bash
git clone https://github.com/AdrianRiegel/app_mobile.git
cd app_mobile
flutter pub get
```

### 2. Configurar Variáveis de Ambiente e Firebase
Copie o arquivo de exemplo de ambiente:
```bash
cp .env.example .env
```
Gere os arquivos do Firebase para o projeto (caso ainda não possua o `firebase_options.dart` local):
```bash
flutterfire configure --project=app-mobile-a16f3
```

### 3. Executar o Aplicativo
```bash
flutter run
```

---

## 🧪 Testes e Validação de Código

Para executar os testes unitários e de widgets automatizados:
```bash
flutter test
```

Para validar a integridade estática do código e regras do linter:
```bash
flutter analyze
```

---

## 🎥 Demonstração em Vídeo
Confira a demonstração do aplicativo em funcionamento: [YouTube - Demonstração EduTurmas](https://youtu.be/a2FAxay55is?si=P0_BHCM4h-RBPjNK)
