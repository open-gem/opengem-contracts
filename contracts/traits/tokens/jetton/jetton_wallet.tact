message(0x0f8a7ea5) JettonTransfer {
    queryId: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to transfer
    destination: Address; // address of the new owner of the jettons
    responseDestination: Address; // address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins.
    customPayload: Cell?; // optional custom payload
    forwardTonAmount: Int as coins; // the amount of nanotons to be sent to the destination address.
    forwardPayload: Slice as remaining; // optional custom data that should be sent to the destination address.
}

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to transfer
    sender: Address; // address of the sender of the jettons
    forwardPayload: Slice as remaining; // optional custom payload
}

message(0x595f07bc) JettonBurn {
    queryId: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to burn
    responseDestination: Address; // address where to send a response with confirmation of a successful burn and the rest of the incoming message coins.
    customPayload: Cell?; // optional custom payload
}

message(0xd53276db) JettonExcesses {
    queryId: Int as uint64; // arbitrary request number
}

message(0x178d4519) JettonInternalTransfer {
    queryId: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to transfer
    from: Address; // address of the sender of the jettons
    responseAddress: Address?; // address where to send a response with confirmation of a successful transfer and the rest of the incoming message coins.
    forwardTonAmount: Int as coins; // the amount of nanotons to be sent to the destination address.
    forwardPayload: Slice as remaining; // optional custom data that should be sent to the destination address.
}

message(0x7bdd97de) JettonBurnNotification {
    queryId: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to burn
    sender: Address; // address of the sender of the jettons
    responseDestination: Address; // address where to send a response with confirmation of a successful burn and the rest of the incoming message coins.
}

struct WalletData {
    balance: Int as coins; // amount of jettons on wallet
    owner: Address; // address of wallet owner;
    jetton: Address; // address of Jetton master-address
    jettonWalletCode: Cell; // with code of this wallet
}

// ============================================================ //

trait JettonWallet {
    balance: Int as coins;
    owner: Address;
    jettonMaster: Address;
    virtual const gasConsumption: Int = ton("0.01");
    virtual const minTonsForStorage: Int = ton("0.01");

    receive(msg: JettonTransfer) {
        let ctx: Context = context();
        self.balance = (self.balance - msg.amount);
        require(self.balance >= 0, "JettonWallet: Not enough jettons to transfer");
        self.transferValidate(ctx, msg);
        self.transferEstimateRemainValue(ctx, msg);
        self.transferJetton(ctx, msg);
    }

    receive(msg: JettonBurn) {
        let ctx: Context = context();
        require(self.balance >= 0, "JettonWallet: Not enough balance to burn tokens");
        self.burnValidate(ctx, msg);
        self.burnTokens(ctx, msg);
    }

    receive(msg: JettonInternalTransfer) {
        let ctx: Context = context();
        self.balance = (self.balance + msg.amount);
        require(self.balance >= 0, "JettonWallet: Not allow negative balance after internal transfer");
        self.internalTransferValidate(ctx, msg);
        let remain: Int = self.internalTransferEstimateRemainValue(ctx, msg);
        if (msg.forwardTonAmount > 0) {
            self.internalTransferNotification(ctx, msg);
        }
        self.internalTransferExcesses(ctx, msg, remain);
    }

    bounced(src: bounced<JettonInternalTransfer>) {
        self.balance = (self.balance + src.amount);
    }

    bounced(src: bounced<JettonBurnNotification>) {
        self.balance = (self.balance + src.amount);
    }

    abstract inline fun calculateJettonWalletInit(ownerAddress: Address): StateInit;

    virtual inline fun transferValidate(ctx: Context, msg: JettonTransfer) {
        require(ctx.sender == self.owner, "JettonWallet: Only owner can call this function");
    }

    virtual inline fun burnValidate(ctx: Context, msg: JettonBurn) {
        require(ctx.sender == self.owner, "JettonWallet: Only owner can burn tokens");
    }

    virtual inline fun transferEstimateRemainValue(ctx: Context, msg: JettonTransfer) {
        let fwdCount: Int = 1;
        if (msg.forwardTonAmount > 0) {
            fwdCount = 2;
        }
        require(ctx.value > ((fwdCount * ctx.readForwardFee() + 2 * self.gasConsumption) + self.minTonsForStorage),
        "Not enough funds to transfer"
        );
    }

    virtual inline fun transferJetton(ctx: Context, msg: JettonTransfer) {
        let initCode: StateInit = self.calculateJettonWalletInit(msg.destination);
        send(SendParameters{
            to: contractAddress(initCode),
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: JettonInternalTransfer{
                queryId: msg.queryId,
                amount: msg.amount,
                responseAddress: msg.responseDestination,
                from: self.owner,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload
            }.toCell(),
            code: initCode.code,
            data: initCode.data
        }
        );
    }

    virtual inline fun burnTokens(ctx: Context, msg: JettonBurn) {
        self.balance = (self.balance - msg.amount);
        send(SendParameters{
            to: self.jettonMaster,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                sender: self.owner,
                responseDestination: msg.responseDestination
            }.toCell()
        }
        );
    }

    virtual inline fun internalTransferValidate(ctx: Context, msg: JettonInternalTransfer) {
        if (ctx.sender != self.jettonMaster) {
            let init: StateInit = self.calculateJettonWalletInit(msg.from);
            require(ctx.sender == contractAddress(init),
            "JettonWallet: Only Jetton master or Jetton wallet can call this function"
            );
        }
    }

    virtual inline fun internalTransferEstimateRemainValue(ctx: Context, msg: JettonInternalTransfer): Int {
        let tonBalanceBeforeMsg: Int = (myBalance() - ctx.value);
        let storageFee: Int = (self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage));
        let remain: Int = (ctx.value - (storageFee + self.gasConsumption));
        if (msg.forwardTonAmount > 0) {
            remain = (remain - (ctx.readForwardFee() + msg.forwardTonAmount));
        }
        return remain;
    }

    virtual inline fun internalTransferNotification(ctx: Context, msg: JettonInternalTransfer) {
        if (msg.forwardTonAmount > 0) {
            send(SendParameters{
                to: self.owner,
                value: msg.forwardTonAmount,
                mode: SendPayGasSeparately,
                bounce: false,
                body: JettonTransferNotification{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: msg.from,
                    forwardPayload: msg.forwardPayload
                }.toCell()
            }
            );
        }
    }

    virtual inline fun internalTransferExcesses(ctx: Context, msg: JettonInternalTransfer, remain: Int) {
        if (msg.responseAddress != null && remain > 0) {
            send(SendParameters{
                to: msg.responseAddress!!,
                value: remain,
                bounce: false,
                mode: SendIgnoreErrors,
                body: JettonExcesses{queryId: msg.queryId}.toCell()
            }
            );
        }
    }

    // ====== Get Methods ====== //
    get fun walletData(): WalletData {
        return
        WalletData{
            balance: self.balance,
            owner: self.owner,
            jetton: self.jettonMaster,
            jettonWalletCode: self.calculateJettonWalletInit(self.owner).code
        };
    }
}