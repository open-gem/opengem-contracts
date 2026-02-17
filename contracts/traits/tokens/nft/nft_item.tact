message(0x5fcc3d14) Transfer {
    queryId: Int as uint64;                    // arbitrary request number
    newOwner: Address;                         // new owner of the NFT item
    responseDestination: Address;              // address where to send a response with confirmation of a successful transfer and the rest of the incoming message coins if not empty address
    customPayload: Cell?;                      // optional custom data
    forwardAmount: Int as coins;               // the amount of nanotons to be sent to the new owner
    forwardPayload: Slice as remaining;        // optional custom data that should be sent to the new owner
}

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}

message(0xd53276db) Excesses {
    queryId: Int as uint64;
}

message(0x2fcb26a2) GetStaticData {
    queryId: Int as uint64;
}

message(0x8b771735) ReportStaticData {
    queryId: Int as uint64;
    index: Int as uint256;
    collection: Address;
}

struct NftData {
    isInitialized: Bool;         // it should be `init`, but it is a reserved keyword in tact. if not zero, then this NFT is fully initialized and ready for interaction.
    index: Int;                   // numerical index of this NFT in the collection. For collection-less NFT - arbitrary but constant value.
    collectionAddress: Address;  // address of the smart contract of the collection to which this NFT belongs. For collection-less NFT this parameter should be addr_none
    ownerAddress: Address;       // address of the current owner of this NFT
    individualContent: Cell;     // if NFT has collection - individual NFT content in any format; if NFT has no collection - NFT content in format that complies with standard TEP-64
}


trait NFTItemStandard {
    virtual const minTonsForStorage: Int = ton("0.05");
    virtual const gasConsumption: Int = ton("0.05");

    collectionAddress: Address;
    index: Int;
    owner: Address;
    individualContent: Cell;
    isInitialized: Bool;


    receive(msg: Transfer) {
        let ctx: Context = context();
        let remain: Int = self.transferEstimateRestValue(ctx);
        self.transferValidate(ctx, msg, remain);
        if (self.isInitialized == false) {
            self.mint(ctx, msg);
        } else {
            self.transfer(ctx, msg, remain);
        }
    }

    receive(msg: GetStaticData) {
        self.reportStaticData(msg);
    }

    inline fun transferEstimateRestValue(ctx: Context): Int {
        let remain: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - remain;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        return remain - (storageFee + self.gasConsumption);
    }

    virtual inline fun transferValidate(ctx: Context, msg: Transfer, remain: Int) {
        require(ctx.sender == self.owner || ctx.sender == self.collectionAddress, "NFTItemStandard: Only the owner or collection can transfer the NFT item");
    }

    virtual inline fun mint(ctx: Context, msg: Transfer) {
        require(ctx.sender == self.collectionAddress, "NFTItemStandard: Only the collection can initialize the NFT item");
        self.isInitialized = true;
        self.owner = msg.newOwner;
        send(SendParameters{
            to: msg.responseDestination,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue,
            body: Excesses { queryId: msg.queryId }.toCell()
        });
    }

    virtual inline fun transfer(ctx: Context, msg: Transfer, remain: Int) {
        self.owner = msg.newOwner;
        if (msg.forwardAmount > 0) {
            send(SendParameters{
                to: msg.newOwner,
                value: msg.forwardAmount,
                mode: SendIgnoreErrors,
                bounce: false,
                body: OwnershipAssigned{
                    queryId: msg.queryId,
                    prevOwner: ctx.sender,
                    forwardPayload: msg.forwardPayload
                }.toCell()
            });
        }
        remain = remain - ctx.readForwardFee();
        if (msg.responseDestination != newAddress(0, 0) && remain > msg.forwardAmount) {
            send(SendParameters{
                to: msg.responseDestination,
                value: remain - msg.forwardAmount,
                mode: SendPayGasSeparately,
                body: Excesses { queryId: msg.queryId }.toCell()
            });
        }
    }

    virtual inline fun reportStaticData(msg: GetStaticData) {
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ReportStaticData{
                queryId: msg.queryId,
                index: self.index,
                collection: self.collectionAddress
            }.toCell()
        });
    }

    virtual inline fun getNftData(): NftData {
        let builder: StringBuilder = beginString();
        let collectionData: String = self.individualContent.asSlice().asString();
        builder.append(collectionData);
        builder.append(self.index.toString());
        builder.append(".json");

        return NftData {
            isInitialized: self.isInitialized,
            index: self.index,
            collectionAddress: self.collectionAddress,
            ownerAddress: self.owner,
            individualContent: builder.toCell()
        };
    }

    get fun nftData(): NftData {
        return self.getNftData();
    }
}