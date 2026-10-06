# LogiFlow — Progressive Web App (PWA) Architecture

Esta pasta contém as especificações, manifesto, service worker e configurações de compatibilidade PWA do **LogiFlow**.

---

## 📱 Recursos PWA Implementados

1. **Instalação Nativa (In-App)**:
   - Suporte a instalação direta em navegadores Chromium (Chrome, Edge, Brave, Opera) via `beforeinstallprompt`.
   - Guia visual integrado para instalação no **iOS Safari** ("Adicionar à Tela de Início").

2. **Suporte Offline & Cache Inteligente**:
   - Cache First para fontes e ícones estáticos.
   - Stale-While-Revalidate para imagens e assets de visualização.
   - Indicador visual não invasivo de status de conectividade (`OfflineIndicator.tsx`).

3. **Manifesto Web App (`manifest.json`)**:
   - Identificador único (`id: "/"`).
   - Display: `standalone`.
   - Ícones maskable e standard (192px e 512px).
   - Cores temáticas consistentes (`#047857` — Emerald Green).
