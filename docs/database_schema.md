# Definição de Estrutura do Banco de Dados e Collections — EduTurmas

## 1. Visão Geral Tecnológica

- **Banco de Dados**: Google Cloud Firestore (Modo Nativo).
- **Modelo de Dados**: Orientado a Documentos (NoSQL Document Store).
- **SDK Mobile**: `cloud_firestore: ^7.0.0` (Firebase Flutter SDK 5.0.0).
- **Autenticação**: Firebase Authentication integrado via UID de professor (`professorId`).
- **Isolamento Multi-tenant**: Cada professor visualiza e modifica apenas os documentos onde `professorId == request.auth.uid`.

---

## 2. Estrutura de Collections e Documentos

### 2.1. Collection `usuarios`
Armazena dados cadastrais e de perfil do professor autenticado.

- **ID do Documento**: `{uid}` (UID do Firebase Authentication)
- **Campos**:
  - `nome` (`string`, obrigatório): Nome completo do professor.
  - `email` (`string`, obrigatório): E-mail cadastrado.
  - `escola` (`string`, opcional): Nome da instituição de ensino.
  - `disciplinaPrincipal` (`string`, opcional): Disciplina primária lecionada.
  - `notificacoesEmail` (`boolean`, opcional, padrão: `true`): Preferência de recebimento de relatórios/notificações.
  - `ativo` (`boolean`, obrigatório, padrão: `true`): Estado de ativação da conta.
  - `criadoEm` (`timestamp`, obrigatório): Timestamp do servidor (`FieldValue.serverTimestamp()`).

---

### 2.2. Collection `turmas`
Agrupa alunos e avaliações associadas a uma classe letiva.

- **ID do Documento**: Auto-gerado pelo Firestore (`turmas.doc().id`)
- **Campos**:
  - `professorId` (`string`, obrigatório): UID do professor proprietário.
  - `descricao` (`string`, obrigatório): Nome/descrição da turma (ex.: `3º Ano A - Matemática`).
  - `semestre` (`number`, obrigatório): Semestre letivo (1 ou 2).
  - `ano` (`number`, obrigatório): Ano letivo (ex.: 2026).
  - `totalAlunos` (`number`, obrigatório, padrão: 0): Quantidade total de alunos matriculados.
  - `criadoEm` (`timestamp`, obrigatório): Data de criação.

---

### 2.3. Collection `alunos`
Registros individuais de alunos pertencentes a uma turma.

- **ID do Documento**: Auto-gerado pelo Firestore (`alunos.doc().id`)
- **Campos**:
  - `professorId` (`string`, obrigatório): UID do professor.
  - `turmaId` (`string`, obrigatório): ID da turma vinculada.
  - `nome` (`string`, obrigatório): Nome completo do aluno.
  - `matricula` (`string`, obrigatório): Identificador único do aluno na turma (ex.: `2026041`).
  - `criadoEm` (`timestamp`, obrigatório): Data de inclusão.
- **Restrição de Integridade**: Matrícula deve ser única dentro da mesma turma (`turmaId` + `matricula`).

---

### 2.4. Collection `avaliacoes`
Provas e avaliações criadas para aplicação em uma turma.

- **ID do Documento**: Auto-gerado pelo Firestore (`avaliacoes.doc().id`)
- **Campos**:
  - `professorId` (`string`, obrigatório): UID do professor.
  - `turmaId` (`string`, obrigatório): ID da turma.
  - `titulo` (`string`, obrigatório): Título da prova (ex.: `Avaliação bimestral — Cap. 4`).
  - `disciplina` (`string`, obrigatório): Disciplina da prova.
  - `status` (`string`, obrigatório): Estado da avaliação (`rascunho`, `agendada`, `concluida`).
  - `dataAplicacao` (`timestamp`, opcional): Data prevista ou realizada de aplicação.
  - `totalQuestoes` (`number`, obrigatório): Quantidade total de questões.
  - `gabarito` (`array<map>`, obrigatório): Lista com o gabarito oficial:
    - `questao` (`number`): Número ordinal da questão (1, 2, ...).
    - `alternativaCorreta` (`string?`): Alternativa correta (`A`, `B`, `C`, `D`, `E`) ou `null` se rascunho.
    - `peso` (`number`, padrão: 1.0): Peso ponderado da questão na nota final.
  - `criadoEm` (`timestamp`, obrigatório): Data de cadastro.

---

### 2.5. Collection `resultados`
Registros de correção e notas dos alunos para uma avaliação.

- **ID do Documento Determinístico**: `{avaliacaoId}_{alunoId}` (garante idempotência e unicidade de nota por aluno).
- **Campos**:
  - `professorId` (`string`, obrigatório): UID do professor.
  - `avaliacaoId` (`string`, obrigatório): ID da avaliação corrigida.
  - `turmaId` (`string`, obrigatório): ID da turma.
  - `alunoId` (`string`, obrigatório): ID do aluno avaliado.
  - `respostasAluno` (`array<map>`, obrigatório):
    - `questao` (`number`): Número da questão.
    - `alternativaMarcada` (`string?`): Alternativa marcada pelo aluno (`A`–`E`) ou `null` se em branco/ausente.
    - `correta` (`boolean`): Indicador de acerto frente ao gabarito.
  - `totalAcertos` (`number`, obrigatório): Número absoluto de acertos.
  - `notaCalculada` (`number`, obrigatório): Nota calculada de 0.0 a 10.0 ponderada pelo peso das questões.
  - `corrigidoEm` (`timestamp`, obrigatório): Data/hora da correção.

---

## 3. Regras de Integridade e Validação

1. **Unicidade de Matrícula**:
   Antes de inserir um aluno, o `AlunoRepository` consulta se já existe um aluno com a mesma matrícula na mesma turma. Caso exista, lança `MatriculaDuplicadaException`.
2. **Idempotência de Correção**:
   Como o documento de resultado é indexado pela chave composta `{avaliacaoId}_{alunoId}`, re-executar a correção atualiza a nota sem criar documentos órfãos.
3. **Cálculo da Nota Ponderada**:
   $$\text{nota} = 10 \times \frac{\sum_{\text{acertos}} \text{peso}_i}{\sum_{\text{todas}} \text{peso}_i}$$
   Se todas as questões tiverem peso 1.0, a nota equivale ao percentual de acertos multiplicado por 10.
4. **Ciclo de Vida do Status da Avaliação**:
   - `rascunho`: Avaliação criada sem todas as alternativas do gabarito definidas.
   - `agendada`: Gabarito preenchido integralmente.
   - `concluida`: Todos os alunos da turma foram corrigidos (ou a correção foi encerrada com atribuição de nota zero para alunos ausentes).

---

## 4. Evolução de Schema e Migrações

- **Estratégia**: Schema versionless compatível com retrocompatibilidade (Additive Changes).
- **Campos Novos**: Sempre declarados com valores padrão (`null` safe ou fallback) nos repositórios.
- **Validador em Tempo de Execução**: `lib/services/database/schema_validator.dart` fornece validações estáticas e dinâmicas para verificação de conformidade antes de gravações.
