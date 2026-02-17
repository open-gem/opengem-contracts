import "../../traits/access/ownable_transferable_2_step.tact";

contract OwnableTransferable2StepImp with OwnableTransferable2Step {
    owner:Address;
    pendingOwner: Address?;

    init(){
        self.owner = sender();
    }
}