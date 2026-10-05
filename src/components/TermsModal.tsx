import React from 'react';
import { Shield, FileText, CheckCircle2 } from 'lucide-react';

interface TermsModalProps {
  onClose: () => void;
}

export const TermsModal: React.FC<TermsModalProps> = ({ onClose }) => {
  return (
    <div className="fixed inset-0 bg-gray-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-150">
      <div className="bg-white w-full max-w-lg rounded-3xl shadow-2xl border border-gray-100 p-6 relative max-h-[85vh] flex flex-col text-left">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-sm font-semibold cursor-pointer p-1"
        >
          ✕
        </button>

        {/* Header */}
        <div className="flex items-center gap-3 mb-4 pb-3 border-b border-gray-100">
          <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0">
            <FileText className="w-5 h-5" />
          </div>
          <div>
            <h3 className="font-extrabold text-gray-900 text-base">
              Termos de Uso & Política de Privacidade
            </h3>
            <p className="text-[11px] text-gray-500">
              Conformidade com a LGPD (Lei nº 13.709/2018) e Marco Civil da Internet
            </p>
          </div>
        </div>

        {/* Scrollable Legal Body */}
        <div className="flex-1 overflow-y-auto space-y-4 text-xs text-gray-600 leading-relaxed pr-2">
          <section>
            <h4 className="font-bold text-gray-900 text-xs mb-1">
              1. Objeto e Finalidade da Plataforma
            </h4>
            <p>
              O <strong>LogiFlow</strong> é uma aplicação de intermediação sustentável que conecta estabelecimentos produtores/vendedores de alimentos e consumidores para viabilizar o resgate de excedentes alimentares e mitigar o desperdício.
            </p>
          </section>

          <section>
            <h4 className="font-bold text-gray-900 text-xs mb-1">
              2. Minimização Estrita de Dados (Privacidade por Padrão)
            </h4>
            <p>
              Em estrita conformidade com o <strong>Art. 6º, inciso III da LGPD</strong> (Princípio da Minimização), o LogiFlow adota política de dados zero-custódia desnecessária:
            </p>
            <ul className="list-disc list-inside mt-1.5 space-y-1 text-gray-600">
              <li><strong>Sem Guarda de Senhas</strong>: A autenticação é delegada integralmente à Google LLC através do protocolo OAuth 2.0. O LogiFlow não possui acesso, armazenamento ou gerenciamento de suas senhas.</li>
              <li><strong>Dados Básicos Autorizados</strong>: O aplicativo armazena apenas as informações públicas básicas que você autoriza compartilhar ao autenticar (nome de exibição e e-mail).</li>
              <li><strong>Zero Retenção de Cartões</strong>: O aplicativo não coleta nem registra dados bancários, números de cartão de crédito ou códigos de segurança.</li>
            </ul>
          </section>

          <section>
            <h4 className="font-bold text-gray-900 text-xs mb-1">
              3. Transações Financeiras e Pagamentos
            </h4>
            <p>
              Quaisquer transações financeiras (como recargas de capacidade para produtores) são executadas diretamente pelas instituições de pagamento licenciadas (<strong>Mercado Pago / Mercado Livre</strong> e <strong>Google Pay</strong>), em conformidade internacional com os padrões PCI-DSS. O LogiFlow não realiza custódia financeira de valores.
            </p>
          </section>

          <section>
            <h4 className="font-bold text-gray-900 text-xs mb-1">
              4. Ponte Tecnológica e Isenção de Responsabilidade
            </h4>
            <p>
              O <strong>LogiFlow atua unicamente como ponte facilitadora de contato</strong> entre os usuários. A aplicação <strong>não se responsabiliza pelas informações divulgadas, condições dos alimentos ou conduta de compradores e vendedores</strong>.
            </p>
            <p className="mt-1">
              A cobrança e pagamento dos produtos, bem como o transporte ou retirada física, ocorrem <strong>exclusivamente entre as partes envolvidas sob sua inteira responsabilidade</strong>. Usuários são orientados a não compartilhar senhas, dados bancários ou documentos pessoais pelo chat.
            </p>
          </section>

          <section>
            <h4 className="font-bold text-gray-900 text-xs mb-1">
              5. Responsabilidade dos Anúncios
            </h4>
            <p>
              Os estabelecimentos e produtores cadastrados são integralmente responsáveis pela veracidade das informações dos itens disponibilizados, incluindo estado de conservação, data de validade informada e cumprimento das normas sanitárias vigentes.
            </p>
          </section>

          <section>
            <h4 className="font-bold text-gray-900 text-xs mb-1">
              6. Direitos do Titular (Art. 18 da LGPD)
            </h4>
            <p>
              O usuário tem direito a consultar seus dados, solicitar a retificação ou exclusão definitiva de sua conta e anúncios a qualquer momento diretamente pelo aplicativo.
            </p>
          </section>
        </div>

        {/* Footer */}
        <div className="pt-4 mt-3 border-t border-gray-100 flex items-center justify-between">
          <span className="text-[11px] text-gray-400">
            Atualizado em Outubro de 2026
          </span>
          <button
            onClick={onClose}
            className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs transition cursor-pointer"
          >
            Entendido
          </button>
        </div>
      </div>
    </div>
  );
};
