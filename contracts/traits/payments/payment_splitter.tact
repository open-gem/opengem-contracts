trait PaymentSplitter {
    totalShares: Int;
    totalReleased: Int;
    shares: map<Address, Int>;
    released: map<Address, Int>;

    fun addPayee(account: Address, sharesAmount: Int) {
        require(sharesAmount > 0, "PaymentSplitter: shares are 0");
        require(self.shares.get(account) == null || self.shares.get(account) == 0,
        "PaymentSplitter: account already has shares"
        );
        self.shares.set(account, sharesAmount);
        self.totalShares += sharesAmount;
    }

    fun release(account: Address) {
        require(self.shares.get(account) != null || self.shares.get(account) != 0,
        "PaymentSplitter: account has no shares"
        );
        let accountShares: Int = self.shares.get(account)!!;
        let accountReleased: Int = 0;

        let releasedAmount: Int? = self.released.get(account);
        if (releasedAmount != null) {
            accountReleased = self.released.get(account)!!;
        }

        let totalReceived: Int = (myBalance() + self.totalReleased);
        let payment: Int = (totalReceived * accountShares / self.totalShares - accountReleased);

        send(SendParameters{to: account, bounce: true, value: payment, mode: (SendRemainingValue + SendIgnoreErrors)});

        self.released.set(account, (accountReleased + payment));
        self.totalReleased = (self.totalReleased + payment);
    }

    get fun getReleased(account: Address): Int? {
        return self.released.get(account);
    }

    get fun getShares(account: Address): Int? {
        return self.shares.get(account);
    }

    get fun getTotalReleased(): Int {
        return self.totalReleased;
    }

    get fun getTotalShares(): Int {
        return self.totalShares;
    }
}