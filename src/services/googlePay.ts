export interface GooglePayPaymentOptions {
  amount: string;
  currencyCode: string;
  merchantName: string;
  planName: string;
}

export interface GooglePayResult {
  transactionId: string;
  status: 'SUCCESS' | 'ERROR';
  details?: Record<string, unknown>;
}

class GooglePayService {
  public async isReadyToPay(): Promise<boolean> {
    return true;
  }

  public async processPayment(options: GooglePayPaymentOptions): Promise<GooglePayResult> {
    // Simulate processing payment via Google Pay JS SDK
    await new Promise((resolve) => setTimeout(resolve, 800));

    const transactionId = 'gpay_' + Date.now() + '_' + Math.random().toString(36).substring(2, 7);

    return {
      transactionId,
      status: 'SUCCESS',
      details: {
        amount: options.amount,
        currencyCode: options.currencyCode,
        merchantName: options.merchantName,
        planName: options.planName,
        timestamp: new Date().toISOString(),
      },
    };
  }
}

export const googlePay = new GooglePayService();
