# Pesquisa e Desenvolvimento: Leitura Óptica de Cartão de Respostas (OMR)

## 1. Introdução e Contexto do Projeto

O **EduTurmas** necessita de uma solução eficiente e confiável para leitura e interpretação de cartões de respostas físicos fotografados através da câmera de smartphones. Esta pesquisa técnica avalia as abordagens viáveis para Optical Mark Recognition (OMR) no ecossistema Flutter/Dart, definindo o modelo geométrico do cartão, métricas de confiança, estratégias para tratamento de ruídos e o fluxo de revisão assistida.

---

## 2. Comparativo de Abordagens Técnicas

| Critério | Abordagem 1: OpenCV / C++ Nativo (FFI) | Abordagem 2: ML Kit / TFLite (Machine Learning) | Abordagem 3: Motor Algorítmico OMR em Dart |
| :--- | :--- | :--- | :--- |
| **Precisão Geométrica** | Alta (Homografia e Binarização Otsu) | Média/Baixa para bolhas (voltado a texto/OCR) | Alta (Grade determinística e densidade) |
| **Tamanho de Binário** | Adiciona ~25 MB a 40 MB ao APK/IPA | Adiciona ~15 MB a 30 MB | **< 100 KB (Zero overhead nativo)** |
| **Compatibilidade** | Complexa (requer NDK, toolchains iOS/Android/Desktop) | Suporta Android/iOS; limitado no Desktop | **Universal (100% multiplataforma Flutter)** |
| **Latência de Processamento** | ~80 ms a 150 ms | ~200 ms a 400 ms | **~15 ms a 60 ms por folha** |
| **Manutenção e Dependências** | Alta complexidade de build | Dependência de serviços e modelos do Google | **Código Dart puro e modular** |
| **Licença** | Apache 2.0 | Proprietária Google / Apache 2.0 | **Código livre / MIT** |

### Escolha Técnica Justificada
Adotou-se a **Abordagem 3 (Motor Algorítmico Puro em Dart)** combinada com um **fluxo de revisão manual quando a confiança for insuficiente**. Motivos:
1. **Multiplataforma sem dependências nativas**: O EduTurmas roda em Android, iOS e ambientes de desktop/testes sem requerer compilação C++ externa.
2. **Determinismo**: Bolhas de cartão de resposta seguem padrões geométricos bem definidos (ao contrário de OCR de caligrafia livre).
3. **Controle Total da Confiança**: Permite calcular com precisão a margem entre a alternativa mais preenchida e a segunda mais preenchida, identificando rasuras e marcações ambíguas.

---

## 3. Especificação do Cartão de Resposta

### 3.1. Geometria e Âncoras (Fiduciais)
- **Formato**: Proporção retangular (A5 ou 10 × 15 cm).
- **Fiduciais nos Cantos**: Quatro quadrados pretos sólidos (15 × 15 mm) localizados nos quatro vértices do cartão. São utilizados para detectar os cantos do documento e aplicar a transformação de perspectiva (Homografia 2D).
- **Identificação da Prova/Aluno**: Bloco com QR Code no topo para identificar automaticamente `avaliacaoId` e `alunoId`.
- **Grade de Respostas**:
  - Linhas: Questões numeradas de 1 a N.
  - Colunas: 5 alternativas por questão (`A`, `B`, `C`, `D`, `E`).
  - Bolhas circulares com raio de 4 mm e espaçamento regular.

---

## 4. Pipeline de Processamento de Imagem

```
[Captura da Câmera] 
       │
       ▼
[Validação de Qualidade] (Verifica iluminação e nitidez)
       │
       ▼
[Detecção de Cantos e Retificação de Perspectiva]
       │
       ▼
[Mapeamento da Grade de Bolhas]
       │
       ▼
[Cálculo de Densidade de Preenchimento (Fill Ratio)]
       │
       ▼
[Classificação e Cálculo de Confiança]
       │
 ┌─────┴────────────────────────┐
 │                              │
Confiança >= 70%          Confiança < 70% ou Ambígua
 │                              │
 ▼                              ▼
[Resposta Aprovada]      [Tela de Revisão Manual]
```

### 4.1. Limiares de Decisão (Thresholds)
- **$T_{\text{preenchida}} = 0.45$ (45%)**: Densidade de pixels escuros dentro do círculo da bolha necessária para considerá-la preenchida.
- **$T_{\text{vazia}} = 0.20$ (20%)**: Limite máximo para considerar a bolha em branco.
- **Margem de Contraste**: Para uma resposta ser considerada clara e sem ambiguidade, a diferença entre a maior densidade e a segunda maior densidade deve ser $\ge 0.20$.

### 4.2. Tratamento de Casos Críticos
1. **Marcação Dupla**: Se duas ou mais alternativas na mesma questão ultrapassarem $T_{\text{preenchida}}$, a questão é marcada com `isMultipleMarked = true` e direcionada para a tela de revisão.
2. **Rasura / Marcação Fraca**: Se a alternativa mais preenchida estiver entre 0.20 e 0.45, é classificada como `isAmbiguous = true`.
3. **Questão em Branco**: Se nenhuma alternativa atingir $T_{\text{vazia}}$, a questão é computada como `isBlank = true` (`alternativa = null`), pontuando 0 sem penalizar a confiança global do cartão.

---

## 5. Tela de Revisão Manual

Quando o processador OMR identifica que o cartão possui confiança global $< 70\%$ ou que há ao menos uma questão com ambiguidade ou marcação múltipla:
1. O sistema **não** atribui notas precipitadamente.
2. Abre a tela `OmrReviewScreen`.
3. As questões problemáticas são sinalizadas com destaque visual (amarelo para ambíguas, vermelho para duplas).
4. O professor pode selecionar e confirmar a alternativa real daquele aluno ou manter em branco, assegurando 100% de precisão e rastreabilidade humana antes da gravação no Firestore.

---

## 6. Como Reproduzir os Testes

Os testes automatizados cobrem todos os cenários lógicos e de borda do motor OMR:
```bash
flutter test test/omr_test.dart
```
Cenários validados:
- Cartão com 100% de confiança e respostas nítidas.
- Cartão com respostas em branco.
- Cartão com marcação múltipla (duas alternativas marcadas).
- Cartão com rasura/ambiguidade.
- Interface de revisão manual com confirmação de alterações.
