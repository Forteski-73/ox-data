# Gestão de Quebras (BreakagePage)

Guia para quem (pessoa ou IA) for implementar ou alterar a tela de Gestão de Quebras.
Leia inteiro antes de mexer no código: aqui estão o objetivo da tela, as regras de negócio,
os perfis de acesso, o contrato com a API, as tabelas do banco e os padrões que o projeto segue.

> **Versão 2.1** — aprovação em duas etapas (Gerente da Loja → Controles Internos), com
> **reprovação que volta ao gerente** em ciclos (envia → aprova/reprova → reenvia…), edição com
> justificativa, **exclusão lógica** (o histórico nunca se perde), linha do tempo do fluxo,
> identificação da loja, valores unitário/total, filtros por data e loja e perfis de usuário.
> As seções marcadas com **[NOVO]** ou **[ALTERADO]** descrevem o que muda em relação à v1;
> **[v2.1]** marca o que mudou na revisão de perfis. Existem **só três perfis**: ESTOQUISTA,
> GERENTE_LOJA e CONTROLES_INT.

---

## 1. Objetivo

Registrar peças quebradas (avarias acidentais) com **foto como evidência**, identificando a
**loja** responsável. O registro passa por **duas aprovações** (gerente da loja e Controles
Internos) e depois tem **baixa no estoque**. Tudo fica num histórico auditável, que inclui
cada edição com a justificativa, e pode ser exportado.

### 1.1 Fluxo de status **[ALTERADO] [v2.1]**

```
ESTOQUISTA
    │ Registrar
    ▼
┌────────────────────┐  Aprovar (GERENTE_LOJA)   ┌────────────────────┐  Aprovar (CONTROLES_INT)  ┌──────────┐
│  PENDENTE_GERENTE  │ ────────────────────────► │    PENDENTE_CI     │ ────────────────────────► │ APROVADO │
│ fila: GERENTE_LOJA │                           │ fila: CONTROLES_INT│                           └────┬─────┘
│ (Editar)           │                           └────────────────────┘                                │ Dar baixa
└─────────┬──────────┘                             │              ▲                                    ▼ (CONTROLES_INT)
          │                     Reprovar (CI,      │              │ Reenviar                      ┌─────────┐
          │                     motivo obrig.)     ▼              │ (GERENTE_LOJA)                │ BAIXADO │
          │                                    ┌────────────────────┐                             └─────────┘
          │                                    │     DEVOLVIDO      │
          │                                    │ fila: GERENTE_LOJA │
          │                                    │ (Editar)           │
          │                                    └─────────┬──────────┘
          │ Excluir (GERENTE_LOJA, motivo obrig.)        │ Excluir (GERENTE_LOJA, motivo obrig.)
          ▼                                              ▼
     ┌──────────┐                                   ┌──────────┐
     │ EXCLUIDO │                                   │ EXCLUIDO │
     └──────────┘                                   └──────────┘
```

O ciclo **PENDENTE_CI → DEVOLVIDO → PENDENTE_CI** pode se repetir quantas vezes for preciso;
cada passagem fica registrada no histórico (seção 4.8).

| Status | Rótulo na tela | Significado | Fila de quem |
|---|---|---|---|
| `PENDENTE_GERENTE` | Pend. Gerente | Registrado pelo estoquista, aguardando a aprovação 1 | GERENTE_LOJA |
| `PENDENTE_CI` | Pend. Controles Internos | Aprovado pelo gerente, aguardando a aprovação 2 | CONTROLES_INT |
| `DEVOLVIDO` | Reprovado (CI) | Controles Internos reprovou; voltou para o gerente corrigir | GERENTE_LOJA |
| `APROVADO` | Aprovado | Aprovado nas duas etapas, aguardando baixa | CONTROLES_INT (baixa) |
| `BAIXADO` | Baixado | Baixado no estoque (final) | — |
| `EXCLUIDO` | Excluído | Excluído pelo gerente, com motivo (final). O registro e o histórico **continuam no banco** | — |
| `REJEITADO` | Rejeitado (legado) | Só registros da v1. **Não é mais gerado** | — |

Transições permitidas (qualquer outra é recusada **pela API** com 409, não só pela tela):

| De | Para | Ação | Perfil | Motivo / justificativa | Evento no histórico |
|---|---|---|---|---|---|
| — | `PENDENTE_GERENTE` | Registrar | ESTOQUISTA, GERENTE_LOJA | — | `CRIADO` |
| `PENDENTE_GERENTE` | (mesmo) | Editar | GERENTE_LOJA | **Obrigatória** | `EDITADO` |
| `PENDENTE_GERENTE` | `PENDENTE_CI` | Aprovar | GERENTE_LOJA | — | `APROVADO_GERENTE` |
| `PENDENTE_GERENTE` | `EXCLUIDO` | Excluir | GERENTE_LOJA | **Obrigatório** | `EXCLUIDO` |
| `PENDENTE_CI` | `APROVADO` | Aprovar | CONTROLES_INT | — | `APROVADO_CI` |
| `PENDENTE_CI` | `DEVOLVIDO` | Reprovar | CONTROLES_INT | **Obrigatório** | `DEVOLVIDO_CI` |
| `DEVOLVIDO` | (mesmo) | Editar | GERENTE_LOJA | **Obrigatória** | `EDITADO` |
| `DEVOLVIDO` | `PENDENTE_CI` | Reenviar | GERENTE_LOJA | Opcional | `REENVIADO_CI` |
| `DEVOLVIDO` | `EXCLUIDO` | Excluir | GERENTE_LOJA | **Obrigatório** | `EXCLUIDO` |
| `APROVADO` | `BAIXADO` | Dar baixa | CONTROLES_INT | — | `BAIXADO` |

Regras de ouro:
- **Cada perfil só mexe na sua fila.** GERENTE_LOJA só age em `PENDENTE_GERENTE` e `DEVOLVIDO`
  (das suas lojas); CONTROLES_INT só age em `PENDENTE_CI` (aprovar/reprovar) e em `APROVADO`
  (dar baixa). Fora disso o registro é **somente leitura** para eles (pode ser consultado no
  Histórico, mas sem botões de ação).
- A reprovação de Controles Internos **não encerra** o registro: ele volta para o gerente
  (`DEVOLVIDO`), que corrige e reenvia, ou exclui.
- Quem encerra um registro sem baixa é **só o gerente**, excluindo (com motivo).
- Depois que o gerente aprova, ele **não pode mais editar nem excluir** até o registro voltar
  como `DEVOLVIDO`.

---

## 2. Arquivos envolvidos

| Camada | Arquivo | Papel |
|---|---|---|
| View | `lib/app/views/breakage/breakage_page.dart` | Tela com as 4 abas |
| View | `lib/app/views/breakage/breakage_camera_page.dart` | Captura de foto na **web** (pacote `camera`); devolve `Uint8List` via `Navigator.pop` |
| View **[NOVO]** | `lib/app/views/breakage/breakage_edit_dialog.dart` | Diálogo de edição (foto + quantidade + justificativa) |
| View **[NOVO]** | `lib/app/views/breakage/breakage_history_sheet.dart` | Linha do tempo do registro (eventos e alterações) |
| View **[NOVO]** | `lib/app/views/breakage/breakage_filter_bar.dart` | Barra de filtros (período + loja) reutilizada nas abas |
| Service | `lib/app/core/services/breakage_service.dart` | `ChangeNotifier` com a lista, filtros, lojas, perfil, cache de fotos/nomes e as ações |
| Repository | `lib/app/core/repositories/breakage_repository.dart` | Chamadas HTTP do endpoint `Breakage` |
| Repository **[NOVO]** | `lib/app/core/repositories/store_repository.dart` | Chamadas HTTP do endpoint `Store` |
| Model | `lib/app/core/models/breakage_model.dart` | `BreakageModel` e constantes `BreakageStatus` |
| Model **[NOVO]** | `lib/app/core/models/breakage_history_model.dart` | `BreakageHistoryModel` e constantes `BreakageEvent` |
| Model **[NOVO]** | `lib/app/core/models/store_model.dart` | `StoreModel` |
| Model **[NOVO]** | `lib/app/core/models/breakage_profile.dart` | Enum/flags de perfil (`BreakageProfile`) |
| Rotas API | `lib/app/core/globals/ApiRoutes.dart` | `ApiRoutes.breakage = 'Breakage'`, `ApiRoutes.store = 'Store'` |
| Injeção | `lib/app/core/injector/injector.dart` | Registra `BreakageRepository`, `StoreRepository` (Provider) e `BreakageService` (ChangeNotifierProvider) |
| Navegação | `lib/app/core/routes/route_generator.dart` | Rota `RouteGenerator.breakagePage` |
| Menu | `lib/app/views/home/home_page.dart` | Item de menu com `routeName == 'QUEBRA'` abre a tela |

Dependências reaproveitadas: `FtpRepository` (upload/download da foto), `ProductRepository`
e `ProductService` (nome e busca de produto), `SearchProductsPage` (pesquisa de produto).

---

## 3. Perfis e permissões **[ALTERADO] [v2.1]**

### 3.1 Perfis

O menu `QUEBRA` continua sendo o que abre a tela (`home_page.dart`). O que o usuário pode fazer
dentro dela vem do **perfil**, cadastrado na tabela `profiles`. Existem **só três perfis**:

| `profiles.id` | `profiles.name` | Quem é | Responsabilidade |
|---|---|---|---|
| 10 | `ESTOQUISTA` | Estoquista da loja | **Só registra** quebras das suas lojas. Não vê listas, não aprova, não edita |
| 11 | `GERENTE_LOJA` | Gerente de loja | **Registra** quebras das suas lojas; fila de aprovação 1 das **suas lojas**: aprova, edita, exclui; corrige e reenvia os reprovados pelo CI |
| 12 | `CONTROLES_INT` | Controles Internos | Fila de aprovação 2 de **todas as lojas**: aprova ou reprova (volta ao gerente); **dá baixa** nos aprovados |

- **Não existem outros perfis** na Gestão de Quebras: nada de `ADMIN_LOJAS`, `INVENTADM`,
  `QUEBRAGER`, `QUEBRACI` ou `QUEBRAADM`. Usuário sem nenhum dos três perfis não tem abas
  (mostrar estado vazio "Você não tem perfil de acesso à Gestão de Quebras").
- O app identifica o perfil pelo **`name`** (`ESTOQUISTA`, `GERENTE_LOJA`, `CONTROLES_INT`),
  nunca pelo id. Os perfis do usuário vêm da mesma fonte que o app já usa para os dados do
  usuário logado (resposta do login / `StorageService`); verifique no código onde eles chegam.
- Um usuário pode ter mais de um perfil; as permissões **somam**.
- A coluna `profiles.is_readonly` **não** é usada nas regras desta tela.
- A lógica fica em `BreakageService` (getters `isStockist`, `isStoreManager`, `isInternalControl`),
  com os nomes nas constantes de `BreakageProfile`. Nunca comparar string solta.

### 3.2 Lojas do usuário

- Cada usuário (`api_user.id`) é vinculado a uma ou mais lojas (tabela `user_store`, seção 7.3).
- ESTOQUISTA e GERENTE_LOJA só veem e agem sobre registros das **suas lojas**.
- CONTROLES_INT vê **todas as lojas**.
- A **API é quem garante** esse recorte (filtra pelo usuário autenticado). O app só monta
  os filtros; nunca confiar apenas no filtro da tela.

### 3.3 Matriz de acesso às abas

| Aba | ESTOQUISTA | GERENTE_LOJA | CONTROLES_INT |
|---|---|---|---|
| Registrar | ✔ | ✔ | — |
| Aprovações | — | ✔ fila: `PENDENTE_GERENTE` + `DEVOLVIDO` | ✔ fila: `PENDENTE_CI` |
| Baixar | — | — | ✔ fila: `APROVADO` |
| Histórico | — | ✔ suas lojas, todos os status (**só leitura**) | ✔ todas as lojas, todos os status (**só leitura**) |

### 3.4 Matriz de ações (o que a API aceita)

| Ação | Perfil | Status aceitos | Recorte de loja |
|---|---|---|---|
| Registrar | ESTOQUISTA, GERENTE_LOJA | — | Suas lojas |
| Editar | GERENTE_LOJA | `PENDENTE_GERENTE`, `DEVOLVIDO` | Suas lojas |
| Aprovar (etapa 1) | GERENTE_LOJA | `PENDENTE_GERENTE` | Suas lojas |
| Excluir | GERENTE_LOJA | `PENDENTE_GERENTE`, `DEVOLVIDO` | Suas lojas |
| Reenviar | GERENTE_LOJA | `DEVOLVIDO` | Suas lojas |
| Aprovar (etapa 2) | CONTROLES_INT | `PENDENTE_CI` | Todas |
| Reprovar | CONTROLES_INT | `PENDENTE_CI` | Todas |
| Dar baixa | CONTROLES_INT | `APROVADO` | Todas |
| Ver linha do tempo | GERENTE_LOJA, CONTROLES_INT | Todos | Conforme 3.2 |

Perfil errado ou loja fora do recorte → **403**. Perfil certo mas status fora da fila → **409**.

### 3.5 Auditoria

O usuário logado (`StorageService().readCredentials()['username']`) é enviado nas ações, mas
**quem grava** `createdBy`, `managerReviewedBy`, `icReviewedBy`, `writtenOffBy` e as linhas de
`breakage_history` é a API, a partir do token. As datas também são da API/banco.

Cada ação grava o usuário **duas vezes** (seção 7):
- `*_user_id` — FK para `api_user.id` (vínculo real, para JOINs e relatórios);
- `created_by`, `manager_reviewed_by`… — login em texto (`api_user.user`) no momento da ação.
  É o que o app recebe em `createdBy`, `managerReviewedBy` etc.

O app **não envia nem recebe** os `*_user_id`; continua trabalhando só com o login.

---

## 4. Abas e regras de negócio

### 4.1 Registrar (índice 0) — ESTOQUISTA e GERENTE_LOJA

Campos, nesta ordem:

1. **Loja** **[NOVO]** (obrigatória)
   - Se o usuário tem **uma** loja, ela vem preenchida e o campo fica só de leitura.
   - Se tem **várias**, dropdown com as lojas do usuário (`BreakageService.stores`).
   - A última loja escolhida fica lembrada no `StorageService` para o próximo registro.
2. **Evidência fotográfica** (obrigatória)
   - A foto deve ser **tirada na hora**. **Não oferecer galeria/arquivo.**
   - Android/iOS nativo: `ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80)`.
   - Web (computador, tablet ou celular): abre `BreakageCameraPage`.
3. **Produto** (obrigatório): widget `ProductSearch`. O código pode ser digitado, lido no
   scanner ou escolhido em `SearchProductsPage(shouldNavigate: false)`. Se não veio da
   pesquisa, é resolvido com `ProductService.quickSearch` (casa por `productId` ou `barcode`).
   - **[NOVO]** Depois de escolher o produto, mostrar o **valor unitário** (só leitura).
4. **Quantidade**: inteiro ≥ 1, botões − / +.
   - **[NOVO]** Mostrar o **valor total** (quantidade × unitário), atualizado ao mudar a quantidade.
5. **Motivo da ocorrência**: dropdown com lista fixa:
   - Acidente de Manuseio / Queda
   - Tombamento de Palete / Empilhadeira
   - Falha de Embalagem / Caixa Danificada
   - Defeito no Forno / Trinca Térmica
   - Outros

Botão **ENVIAR PARA APROVAÇÃO** → `BreakageService.registerBreakage`:
1. Envia a foto ao FTP (Base64) no caminho `QUEBRAS/{productId}/{ddMMyyyy_HHmm}_001.jpg`.
2. Grava o registro com `storeId`, `photoUrl = 'https://oxfordtec.com.br/Imagens/' + caminho`.
   A API define o status `PENDENTE_GERENTE`, grava o `unitPrice` (ver 4.6) e cria o evento
   `CRIADO` no histórico.
3. Limpa o formulário (mantém a loja), permanece em Registrar e mostra
   `MessageService.showSuccess("Quebra enviada para aprovação do gerente")`.

### 4.2 Aprovações (índice 1) **[ALTERADO] [v2.1]**

A aba mostra **só a fila do perfil** — registros em que o usuário pode agir agora. Quem tem os
dois perfis vê duas seções (`Etapa 1 — Gerente da Loja` e `Etapa 2 — Controles Internos`),
separadas por um cabeçalho.

Cada card mostra: `#id • data`, **loja**, nome do produto, código, colaborador (quem registrou),
foto (toque amplia), quantidade, **valor unitário**, **valor total**, motivo, chip de status e o
link **"Ver linha do tempo"** (abre `BreakageHistorySheet`, seção 4.8).
Se o registro já foi reprovado alguma vez, o card mostra o selo **"Reprovado N×"** (`returnCount`).

#### GERENTE_LOJA (etapa 1)

- Fila: `PENDENTE_GERENTE` + `DEVOLVIDO` das suas lojas, com os **reprovados (`DEVOLVIDO`)
  primeiro**, depois por data.
- Card `DEVOLVIDO`: faixa vermelha em destaque com o **motivo da reprovação**, quem reprovou e quando.
- Ações em `PENDENTE_GERENTE`:
  - **Aprovar** → `PENDENTE_CI` (pede confirmação).
  - **Editar** → ver 4.5.
  - **Excluir** → diálogo com **motivo obrigatório** → `EXCLUIDO` (ver 4.10).
- Ações em `DEVOLVIDO`:
  - **Editar** → ver 4.5 (caminho normal de correção).
  - **Reenviar para Controles Internos** → `PENDENTE_CI` (observação opcional).
  - **Excluir** → diálogo com **motivo obrigatório** → `EXCLUIDO`.
- Depois de aprovar, o registro **some da fila do gerente** e ele não consegue mais agir nele.

#### CONTROLES_INT (etapa 2)

- Fila: `PENDENTE_CI` de todas as lojas.
- Card mostra quem aprovou na etapa 1 e quando, e se o registro foi editado (ícone com contador
  de edições). Se foi reenviado, mostra a observação do reenvio.
- **Aprovar** → `APROVADO` (pede confirmação).
- **Reprovar** → diálogo com **motivo obrigatório** → `DEVOLVIDO` (volta para a fila do gerente).
  Texto de apoio no diálogo: "O registro voltará para o gerente da loja corrigir ou excluir."
- CONTROLES_INT **não edita nem exclui**.

#### Comum

- Filtros de período e loja (ver 4.7) no topo.
- Card de resumo: quantidade de registros na fila e **valor total** correspondente.
- Badge vermelho no ícone da aba = nº de registros na fila do usuário
  (GERENTE_LOJA: `PENDENTE_GERENTE` + `DEVOLVIDO`; CONTROLES_INT: `PENDENTE_CI`; ambos: a soma).
- Se a API responder **409** (outro usuário já agiu), mostrar aviso e recarregar a fila.

### 4.3 Baixar (índice 2) — CONTROLES_INT **[ALTERADO] [v2.1]**

- Só para **CONTROLES_INT**: depois de aprovar na etapa 2, o próprio Controles Internos dá a baixa.
- Lista **somente** registros `APROVADO` (aprovados nas duas etapas), de todas as lojas.
  `BreakageService.notWrittenOff` passa a filtrar só `APROVADO`; a versão anterior incluía
  `REJEITADO`, o que deixa de fazer sentido com o novo fluxo.
- Filtros de período e loja (ver 4.7).
- Cards de resumo: "AGUARDANDO BAIXA" (nº de registros), "PEÇAS A BAIXAR" (soma das
  quantidades) e **"VALOR A BAIXAR"** (soma de `totalValue`). Os resumos consideram os filtros.
- Seleção de 1 ou N registros (checkbox em cada card + "Selecionar todos").
  O rodapé mostra também o **valor total dos selecionados**.
- Botão **DAR BAIXA (N)**, desabilitado sem seleção. Pede confirmação (`showConfirmDialog`)
  → `BAIXADO`.
- Badge no ícone da aba = nº de registros aguardando baixa.

### 4.4 Histórico (índice 3) **[ALTERADO] [v2.1]**

Consulta **somente leitura**: nenhuma ação de fluxo (aprovar, reprovar, editar, excluir) aparece
aqui — ações só na fila (aba Aprovações). Isso garante a regra "cada perfil só mexe na sua fila".

- Filtros de período e loja (ver 4.7) + filtro de status.
- Filtros de status por perfil:
  - GERENTE_LOJA e CONTROLES_INT: Todos, Pend. Gerente, Pend. CI, Reprovados (CI), Aprovados,
    Baixados, Excluídos (e Rejeitados (legado), só se houver).
- Cor da barra lateral por status (`_statusColor`):
  `PENDENTE_GERENTE` = âmbar, `PENDENTE_CI` = laranja, `DEVOLVIDO` = vermelho,
  `APROVADO` = verde, `BAIXADO` = azul, `EXCLUIDO` = cinza, `REJEITADO` = vermelho.
- Reprovados mostram "Motivo reprovação: …" em vermelho; Excluídos mostram "Motivo exclusão: …"
  em cinza.
- Cada card mostra loja, valores, selo "Reprovado N×" (se houver) e o link
  **"Ver linha do tempo"**.
- **Exportar** os selecionados (seleção de 1 ou N, igual à aba Baixar):
  - **Excel `.xlsx`** (pacote `excel`, planilha "Quebras"). O pacote não gera `.xls`.
  - **Texto `.txt`** separado por tabulação.
  - Colunas, nesta ordem:
    ID, **Cód. Loja**, **Loja**, Código, Produto, Quantidade, **Valor Unitário**,
    **Valor Total**, Motivo, Colaborador, Data, Status,
    **Aprovado Gerente por**, **Data Aprov. Gerente**, **Aprovado CI por**, **Data Aprov. CI**,
    **Qtd. Reprovações**, Último Motivo Reprovação/Exclusão, **Qtd. Edições**, Baixado por,
    **Data Baixa**, Foto.
  - No Excel, as colunas de valor são **numéricas** (`DoubleCellValue`) com formato
    `#,##0.00`, para que dê para somar na planilha. No `.txt`, usar vírgula decimal (`pt_BR`).
  - Última linha do Excel: **TOTAL** com a soma de Quantidade e Valor Total.
  - Nome do arquivo: `quebras_AAAAMMDD_HHMM`.
  - Salvo com `DownloadFile.saveBytes` / `DownloadFile.saveTxt` (web baixa o arquivo;
    mobile abre o compartilhar).

### 4.5 Edição de registros **[NOVO]**

- **Quem**: só o **Gerente** da loja do registro.
- **Quando**: só nos status `PENDENTE_GERENTE` e `DEVOLVIDO`. Em qualquer outro status o
  botão não aparece e a API recusa.
- **O quê**: apenas **foto** e **quantidade**. Loja, produto e motivo não são editáveis.
- **Justificativa obrigatória** (mínimo 10 caracteres) num campo de texto no próprio diálogo.
  O botão **Salvar** fica desabilitado até haver alguma alteração **e** a justificativa.
- Foto nova: mesmas regras do registro (câmera na hora, sem galeria). O upload vai para um
  **arquivo novo** (`QUEBRAS/{productId}/{ddMMyyyy_HHmm}_{seq}.jpg`, com `seq` = nº da versão
  da foto, `002`, `003`…). **A foto anterior não é apagada do FTP**, para o histórico continuar
  mostrando a evidência original.
- Ao salvar → `BreakageService.editBreakage` → `POST Breakage/{id}/edit`. A API grava uma linha
  `EDITADO` em `breakage_history` **por campo alterado** (valor antigo, valor novo, justificativa,
  usuário, data) e recalcula `totalValue`.
- Editar **não muda o status**. Em `DEVOLVIDO`, o gerente edita e depois usa **Reenviar**.

### 4.6 Valores **[NOVO]**

- `unitPrice` é uma **foto do preço no momento do registro**: a API lê o preço do produto e
  grava no registro. O app **não envia** `unitPrice` nem `totalValue`.
- `totalValue = quantity × unitPrice`, calculado no banco (coluna gerada). Muda quando a
  quantidade é editada; não muda se o preço do produto mudar depois.
- No formulário de registro, o valor exibido antes de salvar vem do produto (busca) e é só
  informativo; o que vale é o gravado pela API.
- Formato de exibição: `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`.
- Registros antigos (anteriores à v2) podem ter `unitPrice` nulo: exibir "—" e tratar como 0
  nas somas.

### 4.7 Filtros de período e loja **[NOVO]**

Componente único `BreakageFilterBar`, usado nas abas Aprovações, Baixar e Histórico.

- **Período**: botão que abre `showDateRangePicker` (locale `pt_BR`) + atalhos
  "Hoje", "7 dias", "30 dias", "Este mês". O filtro é pela data de registro (`createdAt`).
  Padrão: **últimos 30 dias** no Histórico; **sem limite** em Aprovações e Baixar (pendências
  antigas não podem sumir da fila).
- **Loja**: dropdown com "Todas as lojas" + as lojas que o usuário pode ver. Se ele só vê uma
  loja, o dropdown não aparece.
- Os filtros ficam no `BreakageService` (**por aba**, para que mudar o filtro numa aba não altere
  as outras) e são enviados à API como query string (seção 6). Os cards de resumo e os badges
  respeitam os filtros da aba.
- Mostrar os filtros ativos em chips com "x" para limpar.

### 4.8 Linha do tempo do registro **[NOVO] [v2.1]**

`BreakageHistorySheet` (bottom sheet arrastável, ocupa até 90% da altura) carrega
`GET Breakage/{id}/history` e mostra o fluxo como uma **linha do tempo vertical**, fácil de
ler de relance. Abre pelo link "Ver linha do tempo" em qualquer card (Aprovações, Baixar,
Histórico).

**Cabeçalho do sheet**
- `#id`, produto, loja, quantidade e valor total atuais.
- Chip grande com o **status atual** e "na fila de: Gerente da Loja / Controles Internos /
  Controles Internos (baixa) / —".
- Resumo em uma linha: "Enviado ao CI 3× • Reprovado 2× • Editado 4× • Tempo total: 2d 5h".

**Linha do tempo** (ordem **cronológica**, do registro até hoje, para ler o fluxo como uma
história; botão no topo para inverter a ordem)
- Cada evento é um nó com: ícone colorido no círculo, título, usuário, data/hora
  (`dd/MM/yyyy HH:mm`) e, à direita, o tempo desde o evento anterior ("+3h 20min").
- Linha vertical ligando os nós, na cor do evento seguinte.
- Eventos são **agrupados por ciclo**: um separador "Ciclo 1", "Ciclo 2"… começa a cada envio
  ao CI (`APROVADO_GERENTE` ou `REENVIADO_CI`). Assim fica claro quantas vezes o registro foi e
  voltou.
- Motivos e justificativas aparecem num balão abaixo do título (texto completo, sem cortar).

| Evento | Ícone / cor | Título exibido | Detalhe |
|---|---|---|---|
| `CRIADO` | `add_circle` / azul institucional | "Registrado por {usuário}" | Quantidade, motivo da quebra, miniatura da foto |
| `EDITADO` | `edit` / âmbar | "{usuário} alterou {Quantidade/Foto}" | "{antigo} → {novo}" + justificativa. Foto: miniaturas antiga e nova lado a lado (toque amplia) |
| `APROVADO_GERENTE` | `check_circle` / verde | "Aprovado pelo gerente {usuário}" | "Enviado a Controles Internos" |
| `REENVIADO_CI` | `send` / laranja | "Reenviado a Controles Internos por {usuário}" | Observação, se houver |
| `DEVOLVIDO_CI` | `undo` / vermelho | "Reprovado por Controles Internos ({usuário})" | Motivo (destacado) + "Voltou para o gerente" |
| `APROVADO_CI` | `verified` / verde escuro | "Aprovado por Controles Internos ({usuário})" | — |
| `BAIXADO` | `inventory` / azul | "Baixado por {usuário}" | — |
| `EXCLUIDO` | `delete` / cinza | "Excluído por {usuário}" | Motivo |
| `REJEITADO_GERENTE` | `cancel` / vermelho | "Rejeitado por {usuário} (legado)" | Motivo |

- Rótulos e cores dos eventos ficam num único lugar (`BreakageEvent.label` / `.icon` / `.color`).
- Estado de carregamento: esqueleto de 3 nós. Erro: mensagem + "Tentar novamente".
- Registros antigos (v1) podem ter poucos eventos ou nenhum: mostrar "Sem histórico detalhado
  (registro anterior à v2)" abaixo do que houver.

### 4.9 Comportamentos comuns

- Abas com `IndexedStack` + barra inferior própria (`_buildNavItem`). Abas sem permissão
  **não aparecem** na barra; se o usuário só tem uma aba, a barra inferior é ocultada.
- Aba inicial: a primeira que o usuário pode ver.
- Puxar para baixo (`RefreshIndicator`) recarrega com `fetchBreakages` (com os filtros da aba).
- Lista vazia ou erro de carga: `_buildEmptyState` (com "Tentar novamente" em caso de erro).
- Fotos das listas vêm do FTP em Base64, em segundo plano, com cache em memória
  (`BreakageService.fetchPhotos`). Se não houver bytes, tenta `Image.network(photoUrl)`.
- Datas exibidas no formato `dd/MM/yyyy HH:mm`.

### 4.10 Exclusão **[NOVO] [v2.1]**

- **Quem**: só o GERENTE_LOJA da loja do registro.
- **Quando**: só em `PENDENTE_GERENTE` ou `DEVOLVIDO` (a fila dele).
- **Como**: diálogo com **motivo obrigatório** (mínimo 10 caracteres) → `POST Breakage/{id}/delete`.
- É **exclusão lógica**: o status vira `EXCLUIDO`, o motivo vai para `rejection_reason`, quem
  excluiu vai para `manager_reviewed_by(_user_id)/_at` e o evento `EXCLUIDO` entra no histórico.
  O registro **não sai do banco** e a linha do tempo continua consultável (aba Histórico,
  filtro "Excluídos").
- Excluídos não entram em resumos, badges nem na exportação, a menos que o filtro "Excluídos"
  esteja selecionado.

---

## 5. Decisões de UI que **não** devem ser revertidas

- **[ALTERADO]** Valores monetários agora **são exibidos** (valor unitário e total, nos cards,
  resumos e exportação), sempre em R$ e formato `pt_BR`. Não exibir margem, preço de venda
  ou qualquer valor que não seja `unitPrice`/`totalValue`.
- AppBar padrão do app: `AppBarCustom(title: 'Gestão de Quebras')` dentro de
  `PreferredSize(preferredSize: Size.fromHeight(kToolbarHeight))`. Não criar cabeçalho próprio.
- Ícone da aba selecionada na barra inferior em **preto**; os não selecionados em cinza.
- Os botões **Reprovar** e **Excluir** (`OutlinedButton`) têm o mesmo formato do **Aprovar**:
  raio 12 e padding vertical 16 (o `ElevatedButton` herda isso do tema em `lib/app/app.dart`).
  Excluir e Reprovar em vermelho (fonte e contorno). Botões só aparecem nos cards da **fila** (aba Aprovações).
- Cor institucional: `Color(0xFF002B49)` (`_oxfordColor`). Fundo da página `0xFFF1F5F9`.
- Textos da interface em **português**. Na tela, os status aparecem com rótulos amigáveis
  ("Pend. Gerente", "Pend. Controles Internos", "Reprovado (CI)", "Aprovado", "Baixado",
  "Excluído", "Rejeitado (legado)"), nunca com o código cru.

---

## 6. Contrato com a API **[ALTERADO]**

Base: `ApiRoutes.baseUrl` (`https://oxfordonline.com.br/API/v1/`). Todas as chamadas são
autenticadas (`getAuth`, `postAuth1`, `deleteAuth` do `ApiClient`).
O backend (BreakageController / StoreController) **não está neste repositório**.

As **mudanças de status e a edição deixam de ser "POST do registro inteiro"** e passam a ter
rotas de ação. Assim a API valida a transição e o perfil, grava quem/quando e alimenta o
histórico numa única transação.

| Método | Rota | Uso | Perfil |
|---|---|---|---|
| GET | `Store` | Lojas que o usuário pode ver (`[{storeId, name}]`) | Todos |
| GET | `Breakage?status=&storeId=&dateFrom=&dateTo=` | Lista registros filtrados (todos os parâmetros opcionais; `status` aceita lista separada por vírgula; datas `yyyy-MM-dd`, inclusivas). A API já restringe às lojas do usuário. Sem `status`, não retorna `EXCLUIDO` | GERENTE_LOJA, CONTROLES_INT |
| POST | `Breakage` | **Só cria** (`breakageId = 0`). Retorna 201 com o registro | ESTOQUISTA, GERENTE_LOJA |
| POST | `Breakage/{id}/edit` | Edita foto e/ou quantidade (`PENDENTE_GERENTE`/`DEVOLVIDO`) | GERENTE_LOJA |
| POST | `Breakage/{id}/approve` | `PENDENTE_GERENTE → PENDENTE_CI` (GERENTE_LOJA) ou `PENDENTE_CI → APROVADO` (CONTROLES_INT). A API decide pelo status atual **e** exige o perfil daquela etapa | GERENTE_LOJA, CONTROLES_INT |
| POST | `Breakage/{id}/return` | **Reprovar**: `PENDENTE_CI → DEVOLVIDO`. `reason` obrigatório | CONTROLES_INT |
| POST | `Breakage/{id}/resubmit` | `DEVOLVIDO → PENDENTE_CI`. `reason` opcional | GERENTE_LOJA |
| POST | `Breakage/{id}/delete` | **Exclusão lógica**: `PENDENTE_GERENTE`/`DEVOLVIDO → EXCLUIDO`. `reason` obrigatório | GERENTE_LOJA |
| POST | `Breakage/writeoff` | Baixa em lote: `{ "ids": [1,2,3] }` → `APROVADO → BAIXADO`. Retorna `{ "succeeded": [..], "failed": [{id, message}] }` | CONTROLES_INT |
| GET | `Breakage/{id}/history` | Linha do tempo (array de `BreakageHistoryModel`, ordem cronológica) | GERENTE_LOJA, CONTROLES_INT |
| POST | `Ftp/Images/SetBase64` | Upload da foto | — |
| POST | `Ftp/Images/GetBase64` | Download das fotos (lista de caminhos relativos) | — |

**Removidas na v2.1**: `POST Breakage/{id}/reject` (o gerente não rejeita mais; exclui) e
`DELETE Breakage/{id}` (exclusão física apagava o histórico). A API deve responder **404/405**
nessas rotas.

Respostas de erro esperadas: **403** (perfil sem permissão para a ação ou loja fora do recorte),
**409** (status fora da fila do perfil, ou outro usuário já agiu), **422** (validação: motivo /
justificativa vazios ou curtos, quantidade < 1, edição sem mudança). O repository lê `message` do
corpo e devolve em `ApiResponse`.

### 6.1 Corpos

Criar — `POST Breakage` (`BreakageModel.toCreateMap`):

```json
{
  "breakageId": 0,
  "storeId": "01",
  "productId": "002687",
  "quantity": 2,
  "reason": "Acidente de Manuseio / Queda",
  "photoUrl": "https://oxfordtec.com.br/Imagens/QUEBRAS/002687/05112026_1426_001.jpg"
}
```

Editar — `POST Breakage/{id}/edit` (só os campos alterados; `justification` obrigatória):

```json
{
  "quantity": 3,
  "photoUrl": "https://oxfordtec.com.br/Imagens/QUEBRAS/002687/11112026_1015_002.jpg",
  "justification": "Recontagem: havia mais uma peça trincada no palete."
}
```

Reprovar / Reenviar / Excluir:

```json
{ "reason": "Foto não mostra a avaria com clareza." }
```

(`reason` obrigatório em `return` e `delete`, mínimo 10 caracteres; opcional em `resubmit`.
`approve` e `writeoff` não precisam de corpo além do indicado.)

### 6.2 Retorno do GET (`BreakageModel.fromMap`)

```json
{
  "breakageId": 19,
  "storeId": "01",
  "storeName": "Loja Centro",
  "productId": "002687",
  "productName": "PRATO RASO 27CM",
  "quantity": 3,
  "unitPrice": 12.50,
  "totalValue": 37.50,
  "reason": "Acidente de Manuseio / Queda",
  "photoUrl": "https://oxfordtec.com.br/Imagens/QUEBRAS/002687/11112026_1015_002.jpg",
  "status": "PENDENTE_CI",
  "rejectionReason": null,
  "editCount": 1,
  "returnCount": 2,
  "createdBy": "estoquista1",
  "createdAt": "2026-11-11T10:02:00",
  "managerReviewedBy": "gerente1",
  "managerReviewedAt": "2026-11-11T10:20:00",
  "icReviewedBy": null,
  "icReviewedAt": null,
  "writtenOffBy": null,
  "writtenOffAt": null
}
```

- `storeName`, `productName`, `editCount` e `returnCount` vêm de JOIN/contagem na API; não são
  colunas da quebra. `editCount` = nº de eventos `EDITADO`; `returnCount` = nº de eventos
  `DEVOLVIDO_CI` (quantas vezes CI reprovou).
- `rejectionReason` guarda o **último** motivo de reprovação (CI) ou exclusão (gerente), para
  exibir no card. O histórico completo está em `GET Breakage/{id}/history`.
- `reviewedBy`/`reviewedAt` **deixam de existir** (substituídos por `managerReviewedBy/At` e
  `icReviewedBy/At`). O `fromMap` deve aceitar a ausência dos campos novos (registros antigos).

### 6.3 Histórico (`BreakageHistoryModel.fromMap`)

```json
{
  "historyId": 57,
  "breakageId": 19,
  "event": "EDITADO",
  "fieldName": "quantity",
  "oldValue": "2",
  "newValue": "3",
  "justification": "Recontagem: havia mais uma peça trincada no palete.",
  "createdBy": "gerente1",
  "createdAt": "2026-11-11T10:15:00"
}
```

---

## 7. Banco de dados (MariaDB/MySQL) **[ALTERADO]**

Esta é a estrutura **real, já aplicada** no banco (`u700242432_appprodutos`). Não recriar as
tabelas; qualquer mudança deve ser feita com `ALTER TABLE`.

Regras gerais:
- Todas as tabelas: InnoDB, `utf8mb4_general_ci` (igual a `product`); colunas de texto com
  collation diferente fazem as FKs e os JOINs falharem.
- `api_user.id` é **`INT(11)` com sinal**: toda coluna que aponta para usuário (`user_id`,
  `*_user_id`) usa exatamente esse tipo.
- Login do usuário: coluna `api_user.user` (`VARCHAR(100)`, `utf8mb4_general_ci`).

### 7.1 Diagrama de relacionamentos

```
api_user (id) ─┬─< user_store (user_id)            ON DELETE CASCADE
               │        └─> store (store_id)        ON DELETE CASCADE
               │
               ├─< breakage_record.created_by_user_id           ┐
               ├─< breakage_record.manager_reviewed_by_user_id  │ ON DELETE RESTRICT
               ├─< breakage_record.ic_reviewed_by_user_id       │ (usuário com quebra
               ├─< breakage_record.written_off_by_user_id       │  não pode ser excluído)
               └─< breakage_history.created_by_user_id          ┘

store (store_id)      ─< breakage_record.store_id        ON DELETE RESTRICT
product (product_id)  ─< breakage_record.product_id      ON DELETE RESTRICT
breakage_record (id)  ─< breakage_history.breakage_id    ON DELETE CASCADE
```

Todas as FKs têm `ON UPDATE CASCADE`.

### 7.2 `store` — lojas **[NOVO]**

```sql
CREATE TABLE `store` (
	`store_id` VARCHAR(10) NOT NULL COLLATE 'utf8mb4_general_ci',
	`name` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_general_ci',
	`active` TINYINT(1) NOT NULL DEFAULT '1',
	`created_at` DATETIME NOT NULL DEFAULT current_timestamp(),
	PRIMARY KEY (`store_id`) USING BTREE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB;
```

- `store_id`: código da loja (usar o mesmo do ERP/D365, se houver).
- `GET Store` só devolve lojas com `active = 1`.

### 7.3 `user_store` — vínculo usuário × loja **[NOVO]**

```sql
CREATE TABLE `user_store` (
	`user_id` INT(11) NOT NULL,
	`store_id` VARCHAR(10) NOT NULL COLLATE 'utf8mb4_general_ci',
	PRIMARY KEY (`user_id`, `store_id`) USING BTREE,
	INDEX `ix_user_store_store` (`store_id`) USING BTREE,
	CONSTRAINT `fk_user_store_store` FOREIGN KEY (`store_id`) REFERENCES `store` (`store_id`) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT `fk_user_store_user` FOREIGN KEY (`user_id`) REFERENCES `api_user` (`id`) ON UPDATE CASCADE ON DELETE CASCADE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB;
```

- Usado para **ESTOQUISTA e GERENTE_LOJA**. CONTROLES_INT vê todas as lojas pelo perfil e não
  precisa de linhas aqui.
- Aqui o `CASCADE` é correto: excluir usuário ou loja só remove o vínculo.
- A quebra **não** tem FK para `user_store`: o vínculo pode mudar depois (e CONTROLES_INT não
  tem linhas). Validar "o usuário pertence à loja" é responsabilidade da API, no momento da ação.

### 7.4 `breakage_record` — registro da quebra

> Estrutura **antes** da alteração da v2.1. Depois de rodar a seção 7.6, o ENUM `status` ganha
> `EXCLUIDO` no fim.

```sql
CREATE TABLE `breakage_record` (
	`breakage_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
	`store_id` VARCHAR(10) NOT NULL COLLATE 'utf8mb4_general_ci',
	`product_id` VARCHAR(10) NOT NULL COLLATE 'utf8mb4_general_ci',
	`quantity` INT(11) UNSIGNED NOT NULL,
	`unit_price` DECIMAL(15,2) NULL DEFAULT NULL COMMENT 'Preço unitário no momento do registro',
	`total_value` DECIMAL(17,2) AS (`quantity` * `unit_price`) stored,
	`reason` VARCHAR(200) NOT NULL COLLATE 'utf8mb4_general_ci',
	`photo_url` VARCHAR(500) NOT NULL COMMENT 'Foto atual (versões anteriores ficam em breakage_history)' COLLATE 'utf8mb4_general_ci',
	`status` ENUM('PENDENTE_GERENTE','PENDENTE_CI','DEVOLVIDO','APROVADO','REJEITADO','BAIXADO') NOT NULL DEFAULT 'PENDENTE_GERENTE' COLLATE 'utf8mb4_general_ci',
	`rejection_reason` VARCHAR(500) NULL DEFAULT NULL COMMENT 'Último motivo de rejeição/devolução' COLLATE 'utf8mb4_general_ci',
	`created_by` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_general_ci',
	`created_by_user_id` INT(11) NULL DEFAULT NULL,
	`created_at` DATETIME NOT NULL DEFAULT current_timestamp(),
	`manager_reviewed_by` VARCHAR(100) NULL DEFAULT NULL COMMENT 'Aprovação 1 (gerente)' COLLATE 'utf8mb4_general_ci',
	`manager_reviewed_by_user_id` INT(11) NULL DEFAULT NULL,
	`manager_reviewed_at` DATETIME NULL DEFAULT NULL,
	`ic_reviewed_by` VARCHAR(100) NULL DEFAULT NULL COMMENT 'Aprovação 2 (Controles Internos)' COLLATE 'utf8mb4_general_ci',
	`ic_reviewed_by_user_id` INT(11) NULL DEFAULT NULL,
	`ic_reviewed_at` DATETIME NULL DEFAULT NULL,
	`written_off_by` VARCHAR(100) NULL DEFAULT NULL COMMENT 'Quem deu baixa' COLLATE 'utf8mb4_general_ci',
	`written_off_by_user_id` INT(11) NULL DEFAULT NULL,
	`written_off_at` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`breakage_id`) USING BTREE,
	INDEX `ix_breakage_status_created` (`status`, `created_at`) USING BTREE,
	INDEX `ix_breakage_product` (`product_id`) USING BTREE,
	INDEX `ix_breakage_store_status_created` (`store_id`, `status`, `created_at`) USING BTREE,
	INDEX `ix_breakage_created_by_user` (`created_by_user_id`) USING BTREE,
	INDEX `ix_breakage_manager_by_user` (`manager_reviewed_by_user_id`) USING BTREE,
	INDEX `ix_breakage_ic_by_user` (`ic_reviewed_by_user_id`) USING BTREE,
	INDEX `ix_breakage_written_off_by_user` (`written_off_by_user_id`) USING BTREE,
	CONSTRAINT `fk_breakage_created_by_user` FOREIGN KEY (`created_by_user_id`) REFERENCES `api_user` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT `fk_breakage_ic_by_user` FOREIGN KEY (`ic_reviewed_by_user_id`) REFERENCES `api_user` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT `fk_breakage_manager_by_user` FOREIGN KEY (`manager_reviewed_by_user_id`) REFERENCES `api_user` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT `fk_breakage_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT `fk_breakage_store` FOREIGN KEY (`store_id`) REFERENCES `store` (`store_id`) ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT `fk_breakage_written_off_by_user` FOREIGN KEY (`written_off_by_user_id`) REFERENCES `api_user` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT `ck_breakage_quantity` CHECK (`quantity` > 0),
	CONSTRAINT `ck_breakage_unit_price` CHECK (`unit_price` is null or `unit_price` >= 0)
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB;
```

Pares "quem fez" (login em texto + FK para `api_user`):

| Ação | Login (texto) | FK (`api_user.id`) | Data |
|---|---|---|---|
| Registrar | `created_by` | `created_by_user_id` | `created_at` |
| Aprovação 1 / reenvio / exclusão (GERENTE_LOJA) | `manager_reviewed_by` | `manager_reviewed_by_user_id` | `manager_reviewed_at` |
| Aprovação 2 / reprovação (CONTROLES_INT) | `ic_reviewed_by` | `ic_reviewed_by_user_id` | `ic_reviewed_at` |
| Baixa (CONTROLES_INT) | `written_off_by` | `written_off_by_user_id` | `written_off_at` |

- A API grava **sempre os dois** campos de cada par, a partir do token.
- `*_user_id` são `NULL` até a ação acontecer. Em registros antigos (v1) podem continuar `NULL`
  se o login gravado não existir mais em `api_user`.
- `total_value` é **coluna gerada**: nunca gravar; ler depois do `INSERT`/`UPDATE`.

### 7.5 `breakage_history` — trilha de auditoria **[NOVO]**

> Estrutura **antes** da alteração da v2.1. Depois de rodar a seção 7.6, o ENUM `event` ganha
> `EXCLUIDO` no fim.

```sql
CREATE TABLE `breakage_history` (
	`history_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
	`breakage_id` INT(11) UNSIGNED NOT NULL,
	`event` ENUM('CRIADO','EDITADO','APROVADO_GERENTE','REJEITADO_GERENTE','APROVADO_CI','DEVOLVIDO_CI','REENVIADO_CI','BAIXADO') NOT NULL COLLATE 'utf8mb4_general_ci',
	`field_name` VARCHAR(50) NULL DEFAULT NULL COMMENT 'Só em EDITADO: quantity | photo_url' COLLATE 'utf8mb4_general_ci',
	`old_value` VARCHAR(500) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	`new_value` VARCHAR(500) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	`justification` VARCHAR(500) NULL DEFAULT NULL COMMENT 'Obrigatória em EDITADO, REJEITADO_GERENTE e DEVOLVIDO_CI' COLLATE 'utf8mb4_general_ci',
	`created_by` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_general_ci',
	`created_by_user_id` INT(11) NULL DEFAULT NULL,
	`created_at` DATETIME NOT NULL DEFAULT current_timestamp(),
	PRIMARY KEY (`history_id`) USING BTREE,
	INDEX `ix_history_breakage` (`breakage_id`, `created_at`) USING BTREE,
	INDEX `ix_history_created_by_user` (`created_by_user_id`) USING BTREE,
	CONSTRAINT `fk_history_breakage` FOREIGN KEY (`breakage_id`) REFERENCES `breakage_record` (`breakage_id`) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT `fk_history_created_by_user` FOREIGN KEY (`created_by_user_id`) REFERENCES `api_user` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB;
```

Regras que a **API** deve cumprir ao gravar (não dá para garantir só com constraint):
- Toda ação da tabela 1.1 grava **na mesma transação** a mudança em `breakage_record` e a(s)
  linha(s) em `breakage_history`.
- Toda linha de histórico grava `created_by` **e** `created_by_user_id` do usuário do token.
- Uma edição de foto e quantidade gera **duas** linhas `EDITADO`, com a mesma justificativa.
- **Fila por perfil**: cada `UPDATE` de status filtra pelo status esperado da fila do perfil
  (`UPDATE ... WHERE breakage_id = ? AND status IN (<status da fila>)`); se nenhuma linha mudou,
  responder 409. Isso também evita que dois usuários ajam no mesmo registro ao mesmo tempo.
- Exclusão é **lógica** (`status = 'EXCLUIDO'`). Não há `DELETE` físico de quebras pela API.
- Usuários **não são excluídos** se tiverem quebras ou histórico (FKs `RESTRICT`): desativar
  o usuário em vez de excluir.

### 7.6 Alteração de banco da v2.1 (executar uma vez) **[v2.1]**

Adiciona o status e o evento `EXCLUIDO`. `REJEITADO` / `REJEITADO_GERENTE` continuam no ENUM
só por causa dos registros da v1.

```sql
ALTER TABLE `breakage_record`
    MODIFY COLUMN `status`
        ENUM('PENDENTE_GERENTE','PENDENTE_CI','DEVOLVIDO','APROVADO','REJEITADO','BAIXADO','EXCLUIDO')
        NOT NULL DEFAULT 'PENDENTE_GERENTE',
    MODIFY COLUMN `rejection_reason` VARCHAR(500) NULL DEFAULT NULL
        COMMENT 'Último motivo de reprovação (CI) ou exclusão (gerente)';

ALTER TABLE `breakage_history`
    MODIFY COLUMN `event`
        ENUM('CRIADO','EDITADO','APROVADO_GERENTE','REJEITADO_GERENTE','APROVADO_CI',
             'DEVOLVIDO_CI','REENVIADO_CI','BAIXADO','EXCLUIDO') NOT NULL,
    MODIFY COLUMN `justification` VARCHAR(500) NULL DEFAULT NULL
        COMMENT 'Obrigatória em EDITADO, DEVOLVIDO_CI e EXCLUIDO';
```

Adicionar valores **no fim** do ENUM não altera os dados existentes.

### 7.7 Mapeamento coluna × JSON

| Coluna | JSON / Model | Para que serve |
|---|---|---|
| `breakage_id` | `breakageId` | Identificador do registro (auto incremento) |
| `store_id` | `storeId` (+ `storeName` via JOIN) | Loja responsável (FK `store`) |
| `product_id` | `productId` (+ `productName` via JOIN) | Produto quebrado (FK `product`) |
| `quantity` | `quantity` | Quantas peças quebraram (editável pelo gerente) |
| `unit_price` | `unitPrice` | Preço unitário gravado no registro |
| `total_value` | `totalValue` | `quantity × unit_price` (coluna gerada) |
| `reason` | `reason` | Motivo da quebra |
| `photo_url` | `photoUrl` | URL da foto atual no FTP (editável pelo gerente) |
| `status` | `status` | Ver 1.1 (inclui `EXCLUIDO` a partir da v2.1) |
| `rejection_reason` | `rejectionReason` | Último motivo de reprovação (CI) ou exclusão (gerente) |
| `created_by` / `created_at` | `createdBy` / `createdAt` | Quem registrou / quando |
| `manager_reviewed_by` / `_at` | `managerReviewedBy` / `managerReviewedAt` | Aprovação 1 |
| `ic_reviewed_by` / `_at` | `icReviewedBy` / `icReviewedAt` | Aprovação 2 |
| `written_off_by` / `_at` | `writtenOffBy` / `writtenOffAt` | Quem deu baixa (CONTROLES_INT) / quando |
| `*_user_id` | — (não exposto ao app) | FK para `api_user.id`; uso interno da API (JOINs, relatórios) |

---

## 8. Padrões do projeto (siga ao implementar)

- **Camadas**: View → Service (`ChangeNotifier`) → Repository → `ApiClient`.
  A View nunca chama HTTP direto.
- **Repository** retorna sempre `ApiResponse<T>` (`success`, `message`, `data`;
  definido em `auth_repository.dart`), nunca lança exceção para a View. Trata `statusCode`
  (incluindo 403/409/422) e tenta ler `message` do corpo de erro.
- **Service** guarda o estado (`_breakages`, `_stores`, filtros por aba, `_isLoading`,
  `_errorMessage`), expõe getters e chama `notifyListeners()`. Depois de gravar, recarrega com
  `fetchBreakages()`.
- **Registro de dependências**: novos repositories/services vão em `injector.dart`
  (numerados em sequência, `context.read<...>()` para dependências).
- **Rotas de API**: constantes novas em `ApiRoutes` (seção "GESTÃO DE QUEBRAS"):
  `store`, e helpers para as rotas de ação (`breakageAction(id, 'approve')`, etc.).
- **Status e eventos**: sempre pelas constantes `BreakageStatus` / `BreakageEvent`, nunca string
  solta. Rótulos e cores de status num único lugar (`BreakageStatus.label` / `_statusColor`).
- **Valores**: `double` no model; formatar só na View, com `NumberFormat.currency` `pt_BR`.
- **Ações na View**: envolver com `CallAction.run(action:…, onFinally:…)`; mostrar/ocultar
  `LoadingService` (`show()` / `hide()`); feedback com `MessageService.showSuccess / showWarning /
  showError`. Na BreakagePage existe o helper `_runAction` que já faz isso.
- **Diálogos**: `showConfirmDialog` (`app_confirm_dialog.dart`) e `showConfirmDelete`
  (`delete_confirm_dialog.dart`). Diálogos com motivo/justificativa: um único helper
  `_askReason(title, label, minLength)` reaproveitado em Reprovar, Excluir, Reenviar e Editar.
- **Ler serviço**: `context.watch<BreakageService>()` no `build`; `context.read<…>()` em callbacks.
  Checar `mounted` após `await` antes de usar `context`/`setState`.
- **Nomes**: model/API em inglês (`breakageId`, `managerReviewedBy`); variáveis e métodos da tela
  podem estar em português (`_quantidade`, `_confirmarBaixa`), seguindo o arquivo.
- **Cabeçalho** nos arquivos de `core`: comentário com o caminho
  (`// app/core/services/breakage_service.dart`).
- Ao criar uma nova aba: adicionar ao `IndexedStack`, ao `_buildNavItem` (índice novo), à matriz
  de permissões (3.3) e atualizar o comentário de `_currentIndex`.
- **Permissões**: esconder na tela o que o perfil não pode fazer, mas **sempre** contar com a API
  recusando (403/409). Nunca decidir permissão só no app.

---

## 9. Ordem sugerida de implementação

1. Banco: ✔ estrutura v2 já aplicada (seção 7). Rodar a alteração da v2.1 (seção 7.6). Cadastrar
   as lojas em `store` e os vínculos em `user_store` (`user_id` × `store_id`) de ESTOQUISTA e
   GERENTE_LOJA.
2. Perfis: ✔ `ESTOQUISTA` (10), `GERENTE_LOJA` (11) e `CONTROLES_INT` (12) já cadastrados em
   `profiles`. Falta vincular os usuários.
3. API: `Store`, filtros no GET (+ `returnCount`), rotas de ação com **validação de fila por
   perfil**, `delete` lógico, remoção de `reject` e `DELETE`, `history`, preço no create.
4. App — models (`BreakageModel` novos campos/status, `BreakageHistoryModel` com `EXCLUIDO`,
   `StoreModel`, `BreakageProfile` com os 3 perfis).
5. App — repositories e service (perfis, lojas, filtros, ações novas).
6. App — tela: perfis/abas → Registrar (loja + valores) → Aprovações (filas por perfil) →
   Edição → Exclusão → Baixar → Histórico (só leitura, filtros, exportação) → Linha do tempo.

---

## 10. Como validar uma alteração

```bash
flutter analyze lib/app/views/breakage/ lib/app/core/services/breakage_service.dart \
  lib/app/core/repositories/breakage_repository.dart lib/app/core/repositories/store_repository.dart \
  lib/app/core/models/breakage_model.dart lib/app/core/models/breakage_history_model.dart \
  lib/app/core/models/store_model.dart lib/app/core/models/breakage_profile.dart
```

Não pode haver **erros**. Avisos já existentes: uso de `withOpacity` (obsoleto) — siga o
padrão do arquivo ou migre todos para `withValues` de uma vez.

Teste manual mínimo (um usuário por perfil, um com GERENTE_LOJA + CONTROLES_INT e um sem
nenhum dos três perfis):

1. **ESTOQUISTA**: só vê a aba Registrar (sem barra inferior); loja vem preenchida; registrar
   com foto e produto; valores aparecem. Chamar `GET Breakage` direto na API → 403.
2. **GERENTE_LOJA**: vê o registro na fila; editar quantidade **sem** justificativa (bloqueado)
   e **com** justificativa (ok, total recalculado); aprovar → some da fila dele. No Histórico, o
   registro aparece **sem** botões. Chamar `edit` / `delete` na API com o registro em
   `PENDENTE_CI` → 409.
3. **CONTROLES_INT**: vê na fila com o ícone de edição; reprovar sem motivo (bloqueado) e com
   motivo → some da fila do CI. Tentar `approve` num `DEVOLVIDO` pela API → 409.
4. **GERENTE_LOJA**: vê o reprovado no topo com a faixa vermelha e o motivo; trocar a foto com
   justificativa; reenviar.
5. **CONTROLES_INT**: reprovar de novo (ciclo 2); **GERENTE_LOJA** reenvia; **CONTROLES_INT**
   aprova → `APROVADO`. Card mostra "Reprovado 2×".
6. **GERENTE_LOJA**: excluir outro registro (motivo obrigatório) → status `EXCLUIDO`, continua
   no Histórico com filtro "Excluídos" e com linha do tempo.
7. **CONTROLES_INT**: vê o aprovado na aba Baixar com "VALOR A BAIXAR"; dar baixa em lote →
   `BAIXADO`. GERENTE_LOJA não vê a aba Baixar; `writeoff` chamado por ele na API → 403.
8. **Linha do tempo**: conferir os ciclos (Ciclo 1, Ciclo 2, Ciclo 3), edições com antigo/novo e
   fotos, motivos de reprovação, tempos entre eventos e o resumo do cabeçalho.
9. **Filtros**: período e loja em Aprovações, Baixar e Histórico; resumos e badges acompanham.
10. **Exportação**: `.xlsx` e `.txt` com loja, valores e "Qtd. Reprovações"; somar Valor Total.
11. **Segurança**: gerente da loja A não vê nem consegue aprovar/editar/excluir registro da loja B
    (testar também chamando a API direto).
12. **Sem perfil**: usuário que abre a tela sem ESTOQUISTA, GERENTE_LOJA nem CONTROLES_INT vê o
    estado vazio de "sem perfil"; a API responde 403 em tudo.

---

## 11. Pendências e decisões a confirmar

**Decisões tomadas na v2.1** (revisar se o negócio discordar):
- **Registrar: ESTOQUISTA e GERENTE_LOJA.** O gerente também registra quebras das suas lojas.
  O registro dele entra em `PENDENTE_GERENTE` como os demais. Se a regra de não aprovar a própria
  quebra for necessária, a API pode recusar `approve` quando `created_by_user_id` = id do usuário.
- **Excluir é lógico** (status `EXCLUIDO`, motivo obrigatório), para a linha do tempo nunca se
  perder. Exclusão física foi removida.
- **"Rejeitar" do gerente foi removido**: o gerente só aprova, edita ou exclui. `REJEITADO` fica
  só para registros da v1.
- **Histórico é só leitura** para todos os perfis; ações só na fila (abas Aprovações e Baixar).
- **Baixa é do CONTROLES_INT**: não existe perfil de Administrador de Lojas.

Pendências:
- **Origem do preço**: qual coluna de `product` (ou outra tabela) a API usa para `unit_price`:
  custo médio, último custo ou preço de venda? **Recomendado: custo**, para medir perda real.
- **Registros antigos**: a migração converteu `PENDENTE` em `PENDENTE_GERENTE`, renomeou
  `reviewed_by/at` para `manager_reviewed_by/at` e manteve `APROVADO` como aprovado nas duas
  etapas (sem `ic_reviewed_by`). Lojas foram atribuídas a uma loja padrão e `unit_price` ficou
  `NULL` — conferir/corrigir manualmente se necessário. Os `*_user_id` foram preenchidos casando
  o login com `api_user.user`; os que não casaram ficaram `NULL`.
- **`created_by_user_id` NOT NULL**: hoje aceita `NULL` (por causa dos registros antigos). Se
  todos os registros tiverem o id preenchido, pode passar a `NOT NULL` em `breakage_record` e
  `breakage_history`.
- Lista de motivos ainda fixa no código. Se precisar ser editável, criar tabela `breakage_reason`
  e guardar o id.
- A tabela `product` não tem categoria; a tela não exibe categoria.
- A baixa só altera o status no banco do app; integração com estoque/D365 não existe ainda.
- **Resolvida na v2**: a aba Baixar não inclui mais registros `REJEITADO` (ver 4.3).