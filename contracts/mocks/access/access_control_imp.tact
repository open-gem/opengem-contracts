import "../../traits/access/access_control.tact";

message GrantAdminRoleMessage{
    role:Int;
    adminRole:Int;
}

contract AccessControlImp with AccessControl {
    roles: map<Int,RoleData>;

    const INCREMENT_ROLE: Int = sha256("INCREMENT_ROLE");
    const DECREMENT_ROLE: Int = sha256("DECREMENT_ROLE");
    const INVALID_ROLE: Int = sha256("INVALID_ROLE");

    init(){
        self.initRole(self.ADMIN_ROLE);
        self.initRole(self.INCREMENT_ROLE);
        self.initRole(self.DECREMENT_ROLE);
        self.grantRole(self.ADMIN_ROLE,sender());
    }

    fun grantAdminRole(role:Int,adminRole:Int) {
        self.setRoleAdmin(role,adminRole);
    }

    receive(msg: GrantAdminRoleMessage){
        self.grantAdminRole(msg.role, msg.adminRole);
    }
}