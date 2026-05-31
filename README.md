# 🦅 Vanguard - Gestor Tático de Estudos

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Open Source](https://img.shields.io/badge/Open_Source-100%25-brightgreen.svg?style=for-the-badge)

O **Vanguard** é um Centro de Operações completo para gestão de tempo e análise de desempenho, desenvolvido especificamente para estudantes de alto rendimento, concurseiros e candidatos a exames de extrema exigência.

Construído do zero em **Flutter**, o Vanguard foca-se na disciplina, retenção de conhecimento e blindagem contra distrações.

---

## 🚀 Funcionalidades de Elite

O aplicativo é dividido em 4 frentes principais de operação, perfeitamente sincronizadas:

- ⏱️ **Foco (Cronômetro Tático):** Registo de tempo em tempo real com **HUD de Meta Diária**. Define a tua meta de horas, inicia a sessão e acompanha a barra de progresso visual (com indicador de excedente em modo de superação).
- 📅 **Histórico:** Registo detalhado de todas as sessões. Consulta o que estudaste (Teoria, Questões, Simulados), quantas questões resolveste e o teu rácio de acertos.
- 🔄 **Sistema de Revisões:** *(Em desenvolvimento/Expansão)* Algoritmo para garantir que o conhecimento não se perde com o tempo.
- 📊 **Análise de Desempenho:** Gráficos e estatísticas brutas sobre o teu progresso diário, semanal e mensal. Sabe exatamente onde estás a investir o teu tempo.

### 🛡️ Ferramentas Exclusivas
- **Modo Prova:** Um simulador implacável para dias de teste. Sem pausas, apenas foco total.
- **Segurança de Dados Offline:** Sistema de *Exportar/Importar Backup* por código cifrado (Base64). Os teus dados são teus, guardados localmente (`SharedPreferences`), sem necessidade de internet.
- **Adição Manual:** Esqueceste-te de ligar o cronômetro? O painel de adição manual permite inserir sessões passadas com autocomplete inteligente de matérias e assuntos.

## 🛠️ Tecnologias Utilizadas

- **[Flutter](https://flutter.dev/):** Framework UI para compilação nativa.
- **[Dart](https://dart.dev/):** Linguagem de programação.
- **[Shared Preferences](https://pub.dev/packages/shared_preferences):** Armazenamento local leve e assíncrono para a base de dados do utilizador.
- **Arquitetura Reativa:** Utilização de `ValueNotifier` para sincronização em tempo real entre as várias abas sem quebrar o estado da aplicação.