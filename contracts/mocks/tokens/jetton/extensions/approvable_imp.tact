import "../../../../traits/tokens/jetton/jetton_master";
import "../../../../traits/tokens/jetton/jetton_wallet";
import "../../../../traits/tokens/jetton/extensions/approvable";

message Mint {
    amount: Int;
    receiver: Address;
}

contract MaxSupplyJettonImp with JettonMaster {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;

    init(owner: Address, content: Cell) {
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        require(self.mintable, "Can't Mint Anymore");
        let toWinit: StateInit = self.getJettonWalletInit(msg.receiver); // Create message
        self.mint(msg.receiver, msg.amount, self.owner, toWinit); // (to, amount, response_destination)
    }

    receive("Owner: MintClose") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        self.mintable = false;
    }

    receive(msg: JettonBurnNotification) {
        let toWinit: StateInit = self.getJettonWalletInit(msg.owner); // Create message
        self.tokenBurnNotification(msg, toWinit);
    }

    fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonApprovableWalletImp(myAddress(), address);
    }

    get fun jettonData(): JettonData {
        let winit: StateInit = self.getJettonWalletInit(myAddress());
        return self.jettonDataHandler(winit);
    }

    get fun walletAddress(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return self.walletAddressHandler(winit);
    }
}

contract JettonApprovableWalletImp with JettonWallet, ApprovableWallet {
    balance: Int;
    owner: Address;
    master: Address;
    allowances: map<Address, Int>;

    init(_master: Address, _owner: Address) {
        self.balance = 0;
        self.master = _master;
        self.owner = _owner;
    }

    receive(msg: JettonTransfer) {
        let init: StateInit = initOf JettonApprovableWalletImp(self.master, msg.destination);
        self.tokenTransfer(msg, init);
    }

    receive(msg: JettonBurn) {
        self.tokenBurn(msg);
    }

    receive(msg: JettonInternalTransfer) {
        // 0x178d4519
        let sinit: StateInit = initOf JettonApprovableWalletImp(self.master, msg.from);
        self.tokenTransferInternal(msg, sinit);
    }

    receive(msg: TokenApprove) {
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender");
        self.approve(msg.spender, msg.amount);
    }

// TODO : fix me
// receive(msg: JettonSpend) {
//     let ctx: Context = context();
//     self.spendAllowance(ctx.sender, msg.amount);
//     let init: StateInit = initOf JettonApproveableWalletImp(self.master, msg.destination);
//     self.tokenTransfer(JettonTransfer{
//             queryId: msg.queryId,
//             amount: msg.amount,
//             destination: msg.destination,
//             responseDestination: msg.responseDestination,
//             customPayload: msg.customPayload,
//             forwardTonAmount: msg.forwardTonAmount,
//             forwardPayload: msg.forwardPayload
//         },
//         init
//     );
// }

    get fun walletData(): WalletData {
        let sinit: Cell = initOf JettonApprovableWalletImp(self.master, self.owner).code;
        return self.walletDataHandler(sinit);
    }
}