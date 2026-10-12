# 🌿 APP LogiFlow: AI-Driven Food Rescue & Inventory Marketplace

![LogiFlow Logo](/assets/images/logiflowlogo.png)

> **O LogiFlow** é uma plataforma baseada em Inteligência Artificial voltada ao resgate de alimentos. Conectamos produtores, comerciantes e consumidores finais para combater o desperdício, redistribuindo excedentes agrícolas, produtos de padaria, laticínios e itens de mercearia a preços acessíveis.

---

## 🚀 Sobre o Projeto

O aplicativo foi originalmente idealizado em Flutter e totalmente reescrito como uma aplicação **Web React responsiva em TypeScript**, focada em alto desempenho e experiência do usuário. 

- **Evento:** Desenvolvido durante o **Gemma 4 Good Kaggle Hackathon**.
- **Aplicação Web:** [https://applogiflow.ai.studio/](https://applogiflow.ai.studio/)

---

## 🌟 Principais Recursos

### 📲 Feed Público & Análise com IA Gemma 4
- **Feed de Estoque em Tempo Real:** Selos dinâmicos de status:
  - `MAIS`: Produtos em destaque de assinantes.
  - `RESGATE URGENTE`: Produtos a $\le 3$ dias do vencimento.
  - `SAUDÁVEL`: Produtos frescos e in natura.
- **Insights por IA:** Banner contextual alimentado pelo **Gemma 4**, que analisa produtos próximos ao vencimento em tempo real e sugere ações de resgate.

### 🛒 Marketplace & Busca de Alimentos
- Busca por texto integral e filtros por categorias (*Panificação, Frutas e Verduras, Laticínios, Bebidas e Despensa*).
- **Chat Direto:** Comunicação em tempo real entre compradores e vendedores/produtores para combinar a retirada local.

### 📊 Painel do Vendedor & Gestão de Estoque
- **Dashboard em Tempo Real:** Monitoramento do total de itens ativos, próximos do vencimento ($\le 5$ dias) e itens vencidos.
- **Controle de Estoque Avançado:** Filtros por estado do produto (*Todos, Novos, Higienizados, Embalados, Perto do Vencimento*) com ajuste rápido de quantidade.
- **Planos de Vendedor (Múltiplos Níveis):**
  - **Gratuito:** Até 50 itens.
  - **Mais:** R$10,00 por a cada 1.000 itens.
  
  - *Gerenciamento por soft-lock (impede novos cadastros ao atingir o limite sem interromper operações ativas).*
- **Publicação Completa:** Suporte a múltiplas fotos, prazos de validade, marcação de resgate emergencial e etiquetas de produtor.

 para assinantes ativos.

### 🤖 Assistente Conversacional Gemma 4
- Chatbot dedicado para:
  - Consultas rápidas de estoque.
  - Dicas técnicas de conservação de alimentos.
  - Sugestão de receitas focadas em **desperdício zero**.

---

## 🛠️ Tecnologias Utilizadas

- **Frontend:** React (Web, Responsivo)
- **Linguagem:** TypeScript
- **IA / LLM:** Google Gemma 4
- **Pagamentos:** Stripe (Simulado)
- **Estilização / UI:** CSS3 / HTML5

---

## 🗺️ Roadmap & Próximos Passos

- [x] Migração de arquitetura de Flutter para React + TypeScript.
- [x] Integração do modelo Gemma 4 para geração de insights e assistente zero-waste.
- [x] Lançamento da versão Web (PWA / Web App).
- [ ] **Empacotamento Mobile (Android / TWA):** Adaptação da aplicação Web para publicação na **Google Play Store**.
- [ ] Integração com gateways de pagamento em produção.
- [ ] Sistema de geolocalização para busca por proximidade geográfica.

---

## 🌐 Acesse a Aplicação

Acesse a versão Web ao vivo:  
👉 **[applogiflow.ai.studio](https://applogiflow.ai.studio/)**

---

*Desenvolvido com o compromisso de reduzir o desperdício de alimentos através da tecnologia.*
