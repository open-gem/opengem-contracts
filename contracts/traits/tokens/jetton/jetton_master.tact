import "./jetton_wallet.tact";

message JettonMint {
    origin: Address;
    receiver: Address;
    amount: Int;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
}

// ============================================================ //

trait JettonMaster {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    jettonContent: Cell;

    receive(msg: JettonMint) {
        let ctx: Context = context();
        self.mintValidate(ctx, msg);
        self.mint(ctx, msg);
    }

    receive(msg: JettonBurnNotification) {
        let ctx: Context = context();
        self.burnNotificationValidate(ctx, msg);
        self.burnNotification(ctx, msg);
    }

    abstract inline fun calculateJettonWalletInit(ownerAddress: Address): StateInit;

    virtual inline fun mintValidate(ctx: Context, msg: JettonMint) {
        require(ctx.sender == self.owner, "JettonMaster: Sender is not a Jetton owner");
        require(self.mintable, "JettonMaster: Jetton is not mintable");
    }

    virtual inline fun burnNotificationValidate(ctx: Context, msg: JettonBurnNotification) {
        let initCode: StateInit = self.calculateJettonWalletInit(msg.sender);
        require(ctx.sender == contractAddress(initCode), "Sender is not a Jetton wallet");
    }

    virtual inline fun mint(ctx: Context, msg: JettonMint) {
        let initCode: StateInit = self.calculateJettonWalletInit(msg.receiver);
        self.totalSupply = (self.totalSupply + msg.amount);
        send(SendParameters{
            to: contractAddress(initCode),
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: JettonInternalTransfer{
                queryId: 0,
                amount: msg.amount,
                responseAddress: msg.origin,
                from: myAddress(),
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload
            }.toCell(),
            code: initCode.code,
            data: initCode.data
        }
        );
    }

    inline fun burnNotification(ctx: Context, msg: JettonBurnNotification) {
        self.totalSupply = (self.totalSupply - msg.amount);
        if (msg.responseDestination.toString() != "") {
            send(SendParameters{
                to: msg.responseDestination,
                value: 0,
                bounce: false,
                mode: (SendRemainingValue + SendIgnoreErrors)
            }
            );
        }
    }

    // ====== Get Methods ====== //
    get fun jettonData(): JettonData {
        return
        JettonData{
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            adminAddress: self.owner,
            jettonContent: self.jettonContent,
            jettonWalletCode: self.calculateJettonWalletInit(myAddress()).code
        };
    }

    get fun walletAddress(ownerAddress: Address): Address {
        let initCode: StateInit = self.calculateJettonWalletInit(ownerAddress);
        return contractAddress(initCode);
    }
}