/**
 * Payment Gateways Configuration
 * Mercado Pago & Google Pay integration URLs
 */

export const MERCADO_PAGO_CONFIG = {
  // Link de pagamento oficial gerado no Mercado Pago pelo usuário para o Plano Basic (R$ 20,00)
  basicPlanUrl: 'https://mpago.la/2FX9UEy',
  
  // Link de pagamento para o Plano Pro
  proPlanUrl: 'https://mpago.la/2FX9UEy',

  // URL de retorno configurada
  successRedirectUrl: typeof window !== 'undefined' ? window.location.origin + '?payment=success' : '',
};
