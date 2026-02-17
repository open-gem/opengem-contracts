import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/mocks/payments/payment_splitter_imp.tact',
    options: {
        debug: true,
        external: true,
        experimental: {
            inline: true,
        },
    },
};
