import "@stdlib/ownable";

/**
 * @dev This extension of the {Ownable} contract includes a two-step mechanism to transfer
 * ownership, where the new owner must send {AcceptOwnership2Step} message in order to replace the
 * old one. This can help prevent common mistakes, such as transfers of ownership to
 * incorrect accounts, or to contracts that are unable to interact with the
 * permission system.
 *
 * The initial owner is specified at deployment time for `Ownable`. This
 * can later be changed with {ChangeOwner2Step} and {AcceptOwnership2Step} message.
 */

message ChangeOwner2Step {
    pendingOwner: Address;
}

message ChangeOwner2StepOk {
    pendingOwner: Address;
}

message AcceptOwnership2StepOk {
    newOwner: Address;
}

message AcceptOwnership2Step {
}

//
trait OwnableTransferable2Step with Ownable {
    owner: Address;
    pendingOwner: Address?;

/**
 * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
 * Can only be called by the current owner.
 */
    receive(msg: ChangeOwner2Step) {
        // Check if the sender is the owner
        self.requireOwner();
        // Update pendingOwner
        self.pendingOwner = msg.pendingOwner;
        // Reply result
        emit(ChangeOwner2StepOk{pendingOwner: msg.pendingOwner}.toCell());
    }

/**
 * @dev The new owner accepts the ownership transfer.
 */
    receive(msg: AcceptOwnership2Step) {
        // Check if the sender is the pendingOwner
        self.requirePendingOwner();
        // Update owner and delete pendingOwner
        self.transferOwnership(sender());
        // Reply result
        emit(AcceptOwnership2StepOk{newOwner: self.owner}.toCell());
    }

    fun requirePendingOwner() {
        nativeThrowUnless(132, sender() == self.pendingOwner);
    }

/**
 * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
 * Internal function without access restriction.
 */
    fun transferOwnership(newOwner: Address) {
        self.owner = newOwner;
        self.pendingOwner = null;
    }

/**
 * @dev Returns the address of the pending owner.
 */
    get fun getPendingOwner(): Address? {
        return self.pendingOwner;
    }
}