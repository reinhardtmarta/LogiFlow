import { Product } from '../types';
import { store } from './store';

export interface AssistantAnswer {
  text: string;
  matchedProducts?: Product[];
}

export class GemmaService {
  public async processQuery(query: string): Promise<AssistantAnswer> {
    const trimmed = query.trim().toLowerCase();
    const products = store.getProducts();

    // Check for food / product keywords
    const foodKeywords = [
      'alimento', 'comida', 'desperdício', 'produto', 'vencimento', 'validade',
      'geladeira', 'suco', 'maçã', 'maca', 'banana', 'leite', 'pão', 'pao',
      'carne', 'arroz', 'resgate', 'orgânico', 'organico', 'vegetal', 'fruta',
      'iogurte', 'tomate', 'horta', 'estoque', 'preco', 'preço', 'oferta',
      'receita', 'conservar', 'guardar'
    ];

    const isFoodRelated = foodKeywords.some((kw) => trimmed.includes(kw));

    if (!isFoodRelated && trimmed.length > 3) {
      // Check if user is searching a product name directly
      const foundDirect = products.filter((p) =>
        p.name.toLowerCase().includes(trimmed) || p.category.toLowerCase().includes(trimmed)
      );

      if (foundDirect.length === 0) {
        return {
          text: 'Sou o assistente de sustentabilidade do LogiFlow 🌱. Posso ajudar você a encontrar alimentos disponíveis, verificar prazos de validade, sugerir receitas para resgate e evitar desperdício de comida!',
        };
      }
    }

    // Match products in current inventory
    const matchedProducts = products.filter((p) => {
      const name = p.name.toLowerCase();
      const cat = p.category.toLowerCase();
      const terms = trimmed.split(/\s+/).filter((t) => t.length > 2);
      return terms.some((term) => name.includes(term) || cat.includes(term));
    });

    if (matchedProducts.length > 0) {
      const summaryList = matchedProducts
        .slice(0, 3)
        .map((p) => {
          const days = Math.ceil(
            (new Date(p.expiryDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
          );
          return `• ${p.name} - R$ ${p.price.toFixed(2)} (${p.quantity} un dispo., vence em ${days}d)`;
        })
        .join('\n');

      return {
        text: `Encontrei os seguintes itens no inventário LogiFlow compatíveis com "${query}":\n\n${summaryList}\n\nVocê pode abrir o chat diretamente com o produtor no feed para combinar a retirada!`,
        matchedProducts,
      };
    }

    // Advice logic for food conservation & rescue
    if (trimmed.includes('receita') || trimmed.includes('aproveitar') || trimmed.includes('maduro')) {
      return {
        text: 'Dica de Conservação: Frutas maduras como bananas e maçãs são ideais para vitaminas, compotas ou bolos integrais. Pães do dia anterior podem ser transformados em torradas temperadas ou farinha de rosca caseira! Isso evita o descarte.',
      };
    }

    if (trimmed.includes('venc') || trimmed.includes('validade') || trimmed.includes('resgate')) {
      const expiring = products.filter((p) => {
        const days = Math.ceil(
          (new Date(p.expiryDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
        );
        return days <= 3 && p.quantity > 0;
      });

      if (expiring.length > 0) {
        const list = expiring
          .slice(0, 3)
          .map((p) => `• ${p.name} (R$ ${p.price.toFixed(2)})`)
          .join('\n');
        return {
          text: `Atualmente temos ${expiring.length} produto(s) prioritários para resgate urgente no LogiFlow:\n\n${list}\n\nResgatar estes itens previne a emissão de CO₂ e gera economia direta!`,
          matchedProducts: expiring,
        };
      }
    }

    return {
      text: `Obrigado por consultar o LogiFlow! Nossa plataforma conecta produtores a consumidores para que nenhum alimento de qualidade seja descartado. Atualmente temos ${products.length} ofertas cadastradas no Marketplace.`,
    };
  }
}

export const gemmaService = new GemmaService();
