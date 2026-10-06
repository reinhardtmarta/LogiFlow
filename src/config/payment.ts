/**
 * Payment Gateways Configuration
 * Mercado Pago & Google Pay integration URLs
 */

export const MERCADO_PAGO_CONFIG = {
  // Link de pagamento do Mercado Pago configurável via segredos / variáveis de ambiente
  basicPlanUrl: import.meta.env.VITE_MERCADO_PAGO_BASIC_URL || 'https://mpago.la/2FX9UEy',
  
  // Link de pagamento para o Plano Pro
  proPlanUrl: import.meta.env.VITE_MERCADO_PAGO_PRO_URL || import.meta.env.VITE_MERCADO_PAGO_BASIC_URL || 'https://mpago.la/2FX9UEy',

  // URL de retorno configurada
  successRedirectUrl: typeof window !== 'undefined' ? window.location.origin + '?payment=success' : '',
};
