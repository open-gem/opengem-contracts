import "@stdlib/deploy";
import "../../../../traits/tokens/jetton/jetton_master.tact";
import "../../../../traits/tokens/jetton/jetton_wallet.tact";
import "../../../../traits/tokens/jetton/extensions/max_supply.tact";

contract MaxSupplyImp with JettonMaster, MaxSupply, Deployable {
    totalSupply: Int as coins;
    maxSupply: Int as coins;
    owner: Address;
    jettonContent: Cell;
    mintable: Bool;

    init(owner: Address, content: Cell) {
        self.totalSupply = 0;
        self.maxSupply = ton("1000");
        self.owner = owner;
        self.mintable = true;
        self.jettonContent = content;
    }

    override inline fun calculateJettonWalletInit(ownerAddress: Address): StateInit {
        return initOf JettonWalletImp(ownerAddress, myAddress());
    }

    override inline fun mintValidate(ctx: Context, msg: JettonMint) {
        require(ctx.sender == self.owner, "JettonMaster: Sender is not a Jetton owner");
        require(self.mintable, "JettonMaster: Jetton is not mintable");
        self.requireMaxSupply(msg.amount);
    }

    receive("Mint:Close") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "JettonMaster: Sender is not a Jetton owner");
        self.mintable = false;
    }
}

contract JettonWalletImp with JettonWallet, Deployable {
    balance: Int as coins = 0;
    owner: Address;
    jettonMaster: Address;

    init(owner: Address, jettonMaster: Address) {
        self.owner = owner;
        self.jettonMaster = jettonMaster;
    }

    override inline fun calculateJettonWalletInit(ownerAddress: Address): StateInit {
        return initOf JettonWalletImp(ownerAddress, self.jettonMaster);
    }
}