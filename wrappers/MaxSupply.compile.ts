import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/mocks/tokens/jetton/extensions/max_supply_imp.tact',
    options: {
        debug: true,
        external: true,
        experimental: {
            inline: true,
        },
    },
};
