message GrantRoleMessage {
    role: Int;
    account: Address;
}

message RevokeRoleMessage {
    role: Int;
    account: Address;
}

message RenounceRoleMessage {
    role: Int;
    account: Address;
}

message GrantRoleEvent {
    role: Int;
    account: Address;
}

message RevokeRoleEvent {
    role: Int;
    account: Address;
}

message RenounceRoleEvent {
    role: Int;
    account: Address;
}

struct RoleData {
    hasRole: map<Address, Bool>;
    adminRole: Int;
}

trait AccessControl {
    roles: map<Int, RoleData>;

    const ADMIN_ROLE: Int = sha256("ADMIN_ROLE");

    fun initRole(role: Int): Bool {
        if (self.roles.get(role) == null) {
            self.roles.set(role, RoleData{
                hasRole: emptyMap(),
                adminRole: self.ADMIN_ROLE
            });
            return true;
        }
        return false;
    }

    fun setRoleAdmin(role: Int, adminRole: Int) {
        let r: RoleData = self.roles.get(role)!!;
        r.adminRole = adminRole;
        self.roles.set(role, r);
    }

    fun grantRole(role: Int, account: Address) {
        if (!self.hasRole(role, account)) {
            let currentRole: RoleData = self.roles.get(role)!!;
            let updatedMap: map<Address, Bool> = currentRole.hasRole;
            updatedMap.set(account, true);
            self.roles.set(role, RoleData{
                hasRole: updatedMap,
                adminRole: currentRole.adminRole
            });
            emit(GrantRoleEvent{role: role, account: account}.toCell());
        }
    }

    fun revokeRole(role: Int, account: Address) {
        if (self.hasRole(role, account)) {
            let currentRole: RoleData = self.roles.get(role)!!;
            let updatedMap: map<Address, Bool> = currentRole.hasRole;
            updatedMap.set(account, false);
            self.roles.set(role, RoleData{
                hasRole: updatedMap,
                adminRole: currentRole.adminRole
            });
            emit(RevokeRoleEvent{role: role, account: account}.toCell());
        }
    }

    fun checkRole(role: Int, account: Address) {
        nativeThrowUnless(132, self.hasRole(role, account));
    }

    fun checkSenderRole(role: Int) {
        self.checkRole(role, sender());
    }

    virtual fun renounceRole(role: Int, account: Address) {
        nativeThrowUnless(777, account == sender());
        self.revokeRole(role, account);
        emit(RenounceRoleEvent{role: role, account: account}.toCell());
    }

    virtual fun revokeRoleExternal(role: Int, account: Address) {
        self.checkSenderRole(self.adminRole(role));
        self.revokeRole(role, account);
    }

    virtual fun grantRoleExternal(role: Int, account: Address) {
        self.checkSenderRole(self.adminRole(role));
        self.grantRole(role, account);
    }

    get fun hasRole(role: Int, account: Address): Bool {
        let r: RoleData? = self.roles.get(role);
        if (r == null) { return false; }
        let hasAccount: Bool? = r!!.hasRole.get(account);
        return hasAccount == true; // null или false вернут false
    }

    get fun adminRole(role: Int): Int {
        let r: RoleData? = self.roles.get(role);
        if (r == null) { nativeThrow(666); }
        return r!!.adminRole;
    }

    receive(msg: GrantRoleMessage) {
        self.grantRoleExternal(msg.role, msg.account);
    }

    receive(msg: RevokeRoleMessage) {
        self.revokeRoleExternal(msg.role, msg.account);
    }

    receive(msg: RenounceRoleMessage) {
        self.renounceRole(msg.role, msg.account);
    }
}