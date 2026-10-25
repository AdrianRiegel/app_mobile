# EduTurmas

Aplicativo mobile em Flutter para gestão de turmas, avaliações e correção de
provas. Os dados ficam no Firebase (Authentication e Cloud Firestore), isolados
por professor.

## Fluxos disponíveis

- Login, cadastro e recuperação de senha com Firebase Authentication; a
  sessão fica salva no aparelho.
- Painel inicial com o nome do professor e os totais de turmas e avaliações.
- Cadastro e listagem de turmas, alunos e provas salvos no Firestore.
- Avaliações recentes com filtros por status.
- Criação de uma nova avaliação como rascunho.
- Detalhes da avaliação e configuração do gabarito.
- Correção em etapas com leitura da folha simulada; a nota é calculada a
  partir do gabarito e salva no banco.
- Estatísticas gerais por turma e estatísticas detalhadas de cada prova
  (acerto médio, questão mais errada e acertos por questão), calculadas a
  partir das correções salvas.
- Geração de relatório de desempenho com prévia simulada em PDF.
- Estados de carregamento, vazio e erro nas telas que buscam dados.

## Prints das telas

Capturas reais do app rodando, uma por fluxo principal:

|                                                                      |                                                           |                                                                    |
| -------------------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------ |
| **Login**                                                            | **Cadastro**                                              | **Redefinir senha**                                                |
| ![Login](docs/screenshots/01_login.png)                              | ![Cadastro](docs/screenshots/02_cadastro.png)             | ![Redefinir senha](docs/screenshots/03_redefinir_senha.png)        |
| **Painel inicial**                                                   | **Turmas**                                                | **Detalhe da turma**                                               |
| ![Dashboard](docs/screenshots/04_dashboard.png)                      | ![Turmas](docs/screenshots/05_turmas.png)                 | ![Detalhe da turma](docs/screenshots/06_detalhe_turma.png)         |
| **Avaliações**                                                       | **Nova avaliação**                                        | **Detalhe da avaliação**                                           |
| ![Avaliações](docs/screenshots/07_avaliacoes.png)                    | ![Nova avaliação](docs/screenshots/08_nova_avaliacao.png) | ![Detalhe da avaliação](docs/screenshots/09_detalhe_avaliacao.png) |
| **Configurar gabarito**                                              | **Iniciar correção**                                      | **Estatísticas gerais**                                            |
| ![Gabarito](docs/screenshots/10_gabarito.png)                        | ![Correção](docs/screenshots/11_correcao.png)             | ![Estatísticas](docs/screenshots/12_estatisticas.png)              |
| **Estatísticas da prova**                                            | **Relatório (PDF)**                                       |                                                                    |
| ![Estatísticas da prova](docs/screenshots/13_estatisticas_prova.png) | ![Relatório](docs/screenshots/14_relatorio.png)           |                                                                    |

## Requisitos funcionais explícitos

- **Autenticação**: o sistema deve permitir login com e-mail e senha,
  cadastro de nova conta e recuperação de senha via envio de link para o
  e-mail informado.
- **Logout**: o usuário deve poder encerrar a sessão a partir do painel
  inicial, retornando à tela de login.
- **Painel inicial (dashboard)**: deve exibir atalhos para Turmas,
  Relatórios, Estatísticas e Avaliações, além de um atalho para leitura de
  QR Code.
- **Gestão de turmas**: o sistema deve permitir listar turmas cadastradas,
  buscar turma por nome, criar uma nova turma (descrição, semestre e ano) e
  navegar entre páginas da listagem.
- **Gestão de alunos**: dentro de uma turma, deve ser possível listar os
  alunos matriculados e adicionar um novo aluno, sem repetir matrícula na
  mesma turma.
- **Gestão de avaliações**: o sistema deve permitir listar avaliações,
  filtrar por status (rascunho, agendada, concluída), criar uma nova
  avaliação (vinculada a uma turma, salva como rascunho) e visualizar seus
  detalhes.
- **Gabarito**: deve ser possível configurar/visualizar o gabarito de uma
  avaliação, com uma alternativa marcada como correta por questão, e salvar
  as alterações.
- **Correção de provas**: o sistema deve guiar o usuário por um fluxo em
  etapas (avaliação → aluno → leitura da folha → resultado), simulando a
  leitura via QR Code/câmera, calculando acertos e nota (0 a 10, ponderada
  pelo peso das questões) e salvando o resultado do aluno.
- **Estatísticas**: o sistema deve exibir estatísticas gerais por turma
  (lista de provas com acerto médio) e estatísticas detalhadas de uma prova
  específica (acerto médio geral, questão com menor índice de acerto e
  percentual de acerto por questão).
- **Relatórios**: deve ser possível selecionar turma e, opcionalmente, uma
  prova específica, visualizar uma prévia e gerar um relatório em PDF.
- **Estados de carregamento, vazio e erro**: as telas que buscam dados no
  banco devem exibir um indicador de carregamento, um estado vazio (sem
  itens) e um estado de erro com opção de tentar novamente.

## Requisitos não funcionais explícitos

- **Plataforma**: aplicativo mobile multiplataforma construído com Flutter
  (SDK Dart `^3.13.1`), com suporte de build para Android, iOS, web, Linux,
  macOS e Windows conforme os diretórios de plataforma do projeto.
- **Persistência**: turmas, alunos, avaliações e resultados são salvos no
  Cloud Firestore, e a autenticação usa o Firebase Authentication. O acesso
  passa pelos repositórios em `lib/services/database/` (ver
  [Banco de dados](#banco-de-dados)).
- **Segurança dos dados**: cada professor só lê e altera os próprios
  documentos, garantido pelas regras do Firestore através do campo
  `professorId`.
- **Consistência visual**: a interface segue uma paleta e um conjunto de
  componentes padronizados (`lib/theme/app_colors.dart`), reaproveitados em
  todas as telas para manter identidade visual única.
- **Responsividade de interação**: as listas (turmas, alunos, avaliações,
  questões) devem rolar corretamente e os formulários devem tratar o
  teclado virtual sem cobrir os campos em edição.
- **Qualidade de código**: o projeto deve manter zero problemas relatados
  por `flutter analyze`, seguindo as regras de `package:flutter_lints`
  definidas em `analysis_options.yaml`.
- **Testabilidade**: o projeto deve possuir testes automatizados
  (`flutter test`) cobrindo ao menos os modelos/telas críticos (ver
  `test/`).
- **Idioma**: toda a interface é em português do Brasil (pt-BR).
- **Dependências externas**: além dos pacotes padrão do Flutter, o projeto
  usa `firebase_core`, `firebase_auth` e `cloud_firestore` (banco e
  autenticação), `mailer` e `flutter_dotenv` (envio de e-mail). Não há
  bibliotecas para câmera, OCR, geração real de PDF ou leitura de QR Code —
  esses comportamentos são simulados na própria UI.

## Escopo delimitado

Fazem parte desta entrega:

- Interface completa e navegação entre as telas de autenticação, painel,
  turmas, alunos, avaliações, gabarito, correção, estatísticas e relatório.
- Autenticação real e persistência no Firebase.
- Estados de carregamento, conteúdo, vazio, erro e feedbacks de ação (via
  `SnackBar`) para as principais interações.

Não fazem parte desta entrega (fora de escopo):

- Uso real de câmera, OCR ou leitura de QR Code — a leitura da folha de
  respostas na correção é simulada (as respostas do aluno são geradas
  aleatoriamente, não lidas de uma imagem); a correção e a nota, porém, são
  calculadas e salvas de fato.
- Enunciados das questões — apenas o gabarito de cada avaliação é salvo.
- Geração real de arquivo PDF ou download de arquivos — a tela de
  relatório apresenta apenas uma prévia simulada.
- Tela de Perfil do usuário — o atalho existe na navegação, mas exibe apenas
  um aviso de "disponível em uma próxima entrega".
- Edição/exclusão de turmas, alunos, avaliações e questões após criadas, e
  qualquer regra de permissão/perfil de usuário (ex.: professor x
  coordenador).
- Testes end-to-end, empacotamento para lojas (Play Store/App Store) e
  pipeline de CI/CD.

## Como executar

Antes da primeira execução, gere os arquivos de configuração do Firebase
(veja a seção abaixo) — sem eles o projeto não compila.

```bash
flutter pub get
flutter run
```

## Configuração do Firebase

O app usa Firebase Auth e Cloud Firestore (projeto `app-mobile-a16f3`). Os
arquivos de configuração são gerados localmente e não são commitados (estão
no `.gitignore`):

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `firebase.json`

Para gerá-los:

1. Peça a um dos donos para adicionar sua conta Google ao projeto no
   [Console do Firebase](https://console.firebase.google.com/) (Configurações
   do projeto → Usuários e permissões).
2. Instale as ferramentas de linha de comando (requer Node.js):
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```
   Garanta que `~/.pub-cache/bin` está no `PATH` para o comando
   `flutterfire` ser encontrado.
3. Faça login com a conta que tem acesso ao projeto:
   ```bash
   firebase login
   ```
4. Na raiz do projeto, gere os arquivos:
   ```bash
   flutterfire configure \
     --project=app-mobile-a16f3 \
     --platforms=android,ios,web \
     --android-package-name=com.example.app_mobile \
     --ios-bundle-id=com.example.appMobile
   ```
   Os apps já estão registrados no Firebase, então o comando apenas baixa as
   configurações existentes. Se ele perguntar se deve sobrescrever arquivos ou
   alterar os arquivos de build do Android/iOS, confirme.
5. Rode `flutter pub get` e `flutter run`.

## Banco de dados

Todo acesso ao Firebase fica em `lib/services/database/`: um repositório por
coleção (`TurmaRepository`, `AlunoRepository`, `AvaliacaoRepository`,
`ResultadoRepository`), o `EstatisticasRepository` (cálculos a partir dos
resultados) e o `AuthRepository` (login, cadastro e sessão). As telas não usam
o Firestore diretamente.

Coleções do Firestore (todas têm `professorId` com o UID do dono):

| Coleção      | Conteúdo                                                                                 |
| ------------ | ---------------------------------------------------------------------------------------- |
| `usuarios`   | Perfil do professor; o ID do documento é o UID do Firebase Auth                          |
| `turmas`     | `descricao`, `semestre`, `ano` e `totalAlunos` (atualizado ao cadastrar alunos)          |
| `alunos`     | `turmaId`, `nome` e `matricula`                                                          |
| `avaliacoes` | `turmaId`, `titulo`, `disciplina`, `status`, `dataAplicacao` e `gabarito`                |
| `resultados` | `avaliacaoId`, `alunoId`, respostas do aluno, `totalAcertos` e `notaCalculada` (0 a 10)  |

- **Status da avaliação**: `rascunho` ao criar → `agendada` ao salvar o
  gabarito → `concluida` quando todos os alunos da turma foram corrigidos.
- **Resultados**: o ID é `{avaliacaoId}_{alunoId}`, então corrigir o mesmo
  aluno de novo substitui o resultado anterior.
- **Consultas**: usam apenas filtros de igualdade (a ordenação é feita no
  app), então não é preciso criar índices compostos no Firestore. Como as
  regras de segurança não filtram resultados, toda consulta inclui
  `professorId`.
- **Testes**: `test/helpers/fake_database.dart` troca o Firebase por um
  Firestore em memória (`fake_cloud_firestore`) e uma autenticação falsa, via
  `Database.configure`.

## Configuração do envio de e-mail (SMTP do Gmail)

O envio de e-mail (`lib/services/email_service.dart`) usa o SMTP do Gmail e lê
as credenciais de um arquivo `.env` local, que nunca é commitado (já está no
`.gitignore`).

1. Ative a verificação em duas etapas na conta Google que vai enviar os
   e-mails, em <https://myaccount.google.com/security> (é obrigatória para
   gerar uma senha de app).
2. Gere uma senha de app em
   <https://myaccount.google.com/apppasswords>: dê um nome (ex.: "EduTurmas")
   e copie a senha de 16 letras gerada — essa senha substitui a senha normal
   da conta para o envio via SMTP.
3. Copie `.env.example` para `.env` na raiz do projeto:
   ```bash
   cp .env.example .env
   ```
4. Edite o `.env` com o e-mail da conta e a senha de app gerada:
   ```
   GMAIL_USER=seu-email@gmail.com
   GMAIL_APP_PASSWORD=sua-senha-de-app-de-16-letras
   ```
5. Rode `flutter pub get` para instalar as dependências `mailer` e
   `flutter_dotenv` usadas pelo serviço.

Nunca use a senha normal da conta Google nem comite o `.env` — apenas
`.env.example` (com valores de exemplo) faz parte do repositório.

## Validação

```bash
flutter analyze
flutter test
```

Os testes não acessam o Firebase real: usam um banco em memória. Câmera, OCR
e leitura de QR Code continuam simulados.

## Link do Video do aplicativo
(https://youtu.be/a2FAxay55is?si=P0_BHCM4h-RBPjNK)
