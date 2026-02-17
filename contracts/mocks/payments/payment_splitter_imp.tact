import "@stdlib/ownable";
import "../../traits/payments/payment_splitter.tact";

message AddPayee {
    payee: Address;
    shares: Int;
}

contract PaymentSplitterImp with PaymentSplitter, Ownable {
    owner: Address;
    totalShares: Int;
    totalReleased: Int as coins;
    shares: map<Address, Int>;
    released: map<Address, Int>;

    init(owner: Address) {
        self.owner = owner;
        self.totalReleased = 0;
        self.totalShares = 0;
    }

    receive(msg: AddPayee) {
        self.requireOwner();
        self.addPayee(msg.payee, msg.shares);
        self.reply("refund".asComment());
    }

    receive("release") {
        let ctx: Context = context();
        self.release(ctx.sender);
        self.reply("refund".asComment());
    }

    receive() {
    }
}