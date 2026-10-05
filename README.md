# 🌿 LogiFlow: AI-Driven Food Rescue & Inventory Marketplace

![LogiFlow Logo](/assets/images/logiflowlogo.png)

LogiFlow is an AI-driven food rescue marketplace connecting producers, sellers, and consumers to eliminate food waste and redistribute surplus produce, bakery items, dairy, and groceries at accessible prices.

Rewritten from Flutter as a high-performance, responsive React application.

---

## 🌟 Key Features

- **Public Food Feed & Gemma AI Insights**:
  - Live inventory feed with dynamic status badges: `PREMIUM` (featured), `RESGATE URGENTE` (≤ 3 days to expiry), `SAUDÁVEL` (healthy/fresh).
  - Contextual AI insight banner powered by Gemma 4 analyzing expiring items in real time.
- **Consumer Marketplace & Food Search**:
  - Full-text search and category filtering for bakery, fruits, dairy, beverages, and pantry items.
  - Direct chat integration between consumers and sellers to coordinate pickups.
- **Seller Dashboard & Inventory Management**:
  - Live inventory overview tracking total active items, items expiring soon (≤ 5 days), and expired products.
  - Multi-tier seller plans (Free: 50 items, Basic: 1,000 items, Pro: unlimited) with soft-lock management.
  - Full item publishing with category, condition, multi-photo limits, expiry date, producer tags, and food rescue flagging.
- **Stock Management Screen**:
  - Quick status filtering (`All`, `New`, `Cleaned`, `Packaged`, `Expiring`).
  - Real-time stock quantity adjustments with increment/decrement controls.
- **Stripe Subscription & Upgrade Flow**:
  - Seamless simulated Stripe checkout flow for Basic (R$ 10,00/month) and Pro (R$ 100,00/month) plans.
  - Featured product pinning in the public feed for active subscribers.
- **Gemma 4 AI Assistant**:
  - Dedicated conversational assistant for stock inquiry, food conservation advice, and zero-waste recipes.
- **Direct Messaging**:
  - In-app chat between buyers and food producers.

---

## 🚀 Getting Started

### Prerequisites

- Node.js 22+
- npm

### Installation & Development

```bash
npm install
npm run dev
```

The application runs on `http://localhost:3000`.

### Production Build

```bash
npm run build
```
