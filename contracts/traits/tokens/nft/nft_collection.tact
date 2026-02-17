struct CollectionData {
    nextItemIndex: Int;
    collectionContent: Cell;
    ownerAddress: Address;
}

trait NftCollection {
    virtual const NFT_COLLECTION_STANDARD_METADATA: String = "meta.json";

    nextItemIndex: Int;
    collectionContent: Cell;
    ownerAddress: Address;

    abstract inline fun getNftItemStateInit(index: Int): StateInit;

    virtual inline fun getNftContent(index: Int, individualContent: Cell): Cell {
        let builder: StringBuilder = beginString();
        let idvStr: String = individualContent.asSlice().asString();
        builder.append(idvStr);
        return builder.toCell();
    }

    virtual inline fun getCollectionData(): CollectionData {
        let builder: StringBuilder = beginString();
        let urlPrefix: String = self.collectionContent.asSlice().asString();
        builder.append(urlPrefix);
        builder.append(self.NFT_COLLECTION_STANDARD_METADATA);
        return CollectionData {
            nextItemIndex: self.nextItemIndex,
            collectionContent: builder.toCell(),
            ownerAddress: self.ownerAddress
        };
    }

    get fun collectionData(): CollectionData {
        return self.getCollectionData();
    }

    get fun nftAddressByIndex(index: Int): Address {
        let initCode: StateInit = self.getNftItemStateInit(index);
        return contractAddress(initCode);
    }

    get fun nftContent(index: Int, individualContent: Cell): Cell {
        return self.getNftContent(index, individualContent);
    }
}