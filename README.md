# EduTurmas

Protótipo mobile em Flutter para gestão de turmas, avaliações e correção de
provas. A primeira entrega prioriza a interface, a navegação entre telas e o
uso de dados simulados.

## Fluxos disponíveis

- Login, cadastro e recuperação de senha.
- Painel inicial com atalhos para turmas e avaliações.
- Listagem de turmas, alunos e provas com dados mockados.
- Avaliações recentes com filtros por status.
- Criação de uma nova avaliação como rascunho.
- Detalhes da avaliação e configuração visual do gabarito.
- Acesso direto à correção e simulação da leitura de QR Code.
- Estatísticas gerais por turma e estatísticas detalhadas de cada prova
  (acerto médio, questão mais errada e acertos por questão).
- Geração de relatório de desempenho com prévia simulada em PDF.
- Demonstração dos estados vazio e de erro nas telas de avaliações e de
  estatísticas.

## Como executar

```bash
flutter pub get
flutter run
```

## Validação

```bash
flutter analyze
flutter test
```

Nesta etapa não há integração com backend, câmera, OCR ou leitura real de QR
Code. Os comportamentos são intencionalmente simulados para validar a jornada
e a experiência do usuário.
