#!/bin/bash

# Linux User and Permission Management Tool
# Case Study - Linux Programming

# ------------------------------------------
# FUNCTION: Validate Username
# ------------------------------------------

valid_username() {
    [[ "$1" =~ ^[a-z_][a-z0-9_-]*$ ]] &&
    [[ ${#1} -le 32 ]]
}

# ------------------------------------------
# FUNCTION: Add New User
# ------------------------------------------

add_user() {
    echo "========== ADD NEW USER =========="

    read -rp "Enter new username: " username

    if ! valid_username "$username"; then
        echo "Error: Invalid username!"
        return
    fi

    if getent passwd "$username" > /dev/null; then
        echo "Error: User already exists!"
        return
    fi

    if sudo useradd -m -- "$username"; then
        echo "User '$username' created successfully!"

        echo "Set password for $username:"
        sudo passwd "$username"
    else
        echo "Error: Failed to create user!"
    fi
}

# ------------------------------------------
# FUNCTION: Delete User
# ------------------------------------------

delete_user() {
    echo "========== DELETE USER =========="

    read -rp "Enter username to delete: " username

    if ! getent passwd "$username" > /dev/null; then
        echo "Error: User does not exist!"
        return
    fi

    if [[ "$username" == "$(id -un)" ||
          "$username" == "root" ||
          "$username" == "kali" ]]; then
        echo "Error: Protected account!"
        return
    fi

    uid=$(id -u "$username")

    if (( uid < 1000 )); then
        echo "Error: System accounts cannot be deleted!"
        return
    fi

    echo "WARNING: This will delete user '$username'."
    echo "The user's home directory will be preserved."

    read -rp "Type DELETE to confirm: " confirm

    if [[ "$confirm" != "DELETE" ]]; then
        echo "Deletion cancelled."
        return
    fi

    if sudo userdel -- "$username"; then
        echo "User '$username' deleted successfully!"
    else
        echo "Error: Failed to delete user!"
    fi
}

# ------------------------------------------
# FUNCTION: View User Information
# ------------------------------------------

view_user() {
    echo "========== USER INFORMATION =========="

    read -rp "Enter username: " username

    if getent passwd "$username" > /dev/null; then
        echo ""
        echo "Account details:"
        getent passwd "$username"

        echo ""
        echo "User ID and group information:"
        id "$username"

        echo ""
        echo "Group memberships:"
        groups "$username"
    else
        echo "User does not exist!"
    fi
}

# ==================================================
# MODULE 2: GROUP MANAGEMENT
# ==================================================

# Validate group names
valid_groupname() {
    [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]] &&
    [[ ${#1} -le 32 ]]
}

# ------------------------------------------
# Create New Group
# ------------------------------------------

create_group() {
    echo "========== CREATE GROUP =========="

    read -rp "Enter group name: " groupname

    if ! valid_groupname "$groupname"; then
        echo "Error: Invalid group name!"
        return
    fi

    if getent group "$groupname" > /dev/null; then
        echo "Error: Group already exists!"
        return
    fi

    if sudo groupadd -- "$groupname"; then
    echo "Group '$groupname' created successfully!"
    log_action "GROUP_CREATED" "$groupname" "SUCCESS"
    else
    echo "Error: Failed to create group!"
    log_action "GROUP_CREATED" "$groupname" "FAILED"
    fi
}

# ------------------------------------------
# Add User to Group
# ------------------------------------------

add_user_to_group() {
    echo "========== ADD USER TO GROUP =========="

    read -rp "Enter username: " username
    read -rp "Enter group name: " groupname

    if ! getent passwd "$username" > /dev/null; then
        echo "Error: User does not exist!"
        return
    fi

    if ! getent group "$groupname" > /dev/null; then
        echo "Error: Group does not exist!"
        return
    fi

    if id -nG "$username" | tr ' ' '\n' |
       grep -Fxq -- "$groupname"; then
        echo "User is already a member of this group!"
        return
    fi

    if sudo usermod -aG "$groupname" "$username"; then
        echo "User '$username' added to '$groupname'!"
        echo "A new login session may be required."
    else
        echo "Error: Failed to add user to group!"
    fi
}

# ------------------------------------------
# Remove User from Group
# ------------------------------------------

remove_user_from_group() {
    echo "========== REMOVE USER FROM GROUP =========="

    read -rp "Enter username: " username
    read -rp "Enter group name: " groupname

    if ! getent passwd "$username" > /dev/null; then
        echo "Error: User does not exist!"
        return
    fi

    if ! getent group "$groupname" > /dev/null; then
        echo "Error: Group does not exist!"
        return
    fi

    # Do not remove the user's primary group.
    primary_group=$(id -gn "$username")

    if [[ "$groupname" == "$primary_group" ]]; then
        echo "Error: Cannot remove the primary group!"
        return
    fi

    # Prevent accidental changes to administrative groups.
    case "$groupname" in
        sudo|root|adm|shadow)
            echo "Error: Protected administrative group!"
            return
            ;;
    esac

    if ! id -nG "$username" | tr ' ' '\n' |
         grep -Fxq -- "$groupname"; then
        echo "Error: User is not a member of this group!"
        return
    fi

    read -rp "Remove membership? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Operation cancelled."
        return
    fi

    if sudo gpasswd -d "$username" "$groupname"; then
        echo "User removed from group successfully!"
        echo "Existing login sessions may retain old privileges."
    else
        echo "Error: Failed to remove user from group!"
    fi
}

# ------------------------------------------
# View Group Information
# ------------------------------------------

view_group() {
    echo "========== VIEW GROUP INFORMATION =========="

    read -rp "Enter group name: " groupname

    if ! getent group "$groupname" > /dev/null; then
        echo "Error: Group does not exist!"
        return
    fi

    echo ""
    echo "Group details:"
    getent group "$groupname"

    echo ""
    echo "Users belonging to this group:"

    # Includes primary and supplementary memberships.
    local found=0
    local account

    while IFS=: read -r account _; do
        if id -nG "$account" 2>/dev/null |
           tr ' ' '\n' | grep -Fxq -- "$groupname"; then
            echo " - $account"
            found=1
        fi
    done < <(getent passwd)

    if (( found == 0 )); then
        echo "No users found."
    fi
}

# ------------------------------------------
# Delete Group
# ------------------------------------------

delete_group() {
    echo "========== DELETE GROUP =========="

    read -rp "Enter group name: " groupname

    if ! valid_groupname "$groupname"; then
        echo "Error: Invalid group name!"
        return
    fi

    if ! getent group "$groupname" > /dev/null; then
        echo "Error: Group does not exist!"
        return
    fi

    echo "WARNING: Group '$groupname' will be deleted."
    echo "Check file ownership and ACLs before proceeding."

    read -rp "Type DELETE to confirm: " confirm

    if [[ "$confirm" != "DELETE" ]]; then
        echo "Deletion cancelled."
        return
    fi

    if sudo groupdel -- "$groupname"; then
        echo "Group '$groupname' deleted successfully!"
    else
        echo "Group deletion failed."
        echo "The group may be a user's primary group."
    fi
}

# ------------------------------------------
# Group Management Submenu
# ------------------------------------------

manage_groups() {
    local option

    while true; do
        echo ""
        echo "=========================================="
        echo "             GROUP MANAGEMENT"
        echo "=========================================="
        echo "1. Create Group"
        echo "2. Add User to Group"
        echo "3. Remove User from Group"
        echo "4. View Group Information"
        echo "5. Delete Group"
        echo "0. Return to Main Menu"
        echo "=========================================="

        read -rp "Enter choice: " option

        case "$option" in
            1) create_group ;;
            2) add_user_to_group ;;
            3) remove_user_from_group ;;
            4) view_group ;;
            5) delete_group ;;
            0) return ;;
            *) echo "Invalid choice!" ;;
        esac

        echo ""
        read -rp "Press Enter to continue..."
    done
}

# ==================================================
# MODULE 3: FILE PERMISSION MANAGEMENT
# ==================================================

# Restrict operations to our dedicated test directory.
PERMISSION_LAB="$(realpath "$HOME/LinuxCaseStudy/permission_lab")"

# ------------------------------------------
# Validate File Path
# ------------------------------------------

validate_file_path() {
    local input_path="$1"
    local resolved_path

    if [[ ! -e "$input_path" ]]; then
        echo "Error: File or directory does not exist!"
        return 1
    fi

    resolved_path=$(realpath -e -- "$input_path") || return 1

    # Reject the lab root itself and paths outside the lab.
    case "$resolved_path" in
        "$PERMISSION_LAB"/*)
            VALIDATED_PATH="$resolved_path"
            return 0
            ;;
        *)
            echo "Error: Only files inside permission_lab are allowed!"
            return 1
            ;;
    esac
}

# ------------------------------------------
# View File Permissions
# ------------------------------------------

view_file_permissions() {
    echo "========== VIEW FILE PERMISSIONS =========="

    read -rp "Enter file path: " filepath

    if ! validate_file_path "$filepath"; then
        return
    fi

    echo ""
    echo "File permissions:"
    ls -ld -- "$VALIDATED_PATH"

    echo ""
    echo "Detailed information:"
    stat -c 'Owner: %U
Group: %G
Permissions: %A
Numeric Mode: %a' -- "$VALIDATED_PATH"
}

# ------------------------------------------
# Change File Permissions
# ------------------------------------------

change_file_permissions() {
    echo "========== CHANGE FILE PERMISSIONS =========="

    read -rp "Enter file path: " filepath

    if ! validate_file_path "$filepath"; then
        return
    fi

    read -rp "Enter permissions (e.g., 640, 750): " mode

    # Accept only three-digit standard octal permissions.
    if [[ ! "$mode" =~ ^[0-7]{3}$ ]]; then
        echo "Error: Enter a valid three-digit octal mode!"
        return
    fi

    echo ""
    echo "Current permissions:"
    ls -ld -- "$VALIDATED_PATH"

    echo ""
    echo "New permissions: $mode"

    read -rp "Apply changes? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Operation cancelled."
        return
    fi

    if sudo chmod -- "$mode" "$VALIDATED_PATH"; then
        echo "Permissions updated successfully!"
        ls -ld -- "$VALIDATED_PATH"
    else
        echo "Error: Failed to change permissions!"
    fi
}

# ------------------------------------------
# Change File Owner
# ------------------------------------------

change_file_owner() {
    echo "========== CHANGE FILE OWNER =========="

    read -rp "Enter file path: " filepath

    if ! validate_file_path "$filepath"; then
        return
    fi

    read -rp "Enter new owner username: " username

    if ! getent passwd "$username" > /dev/null; then
        echo "Error: User does not exist!"
        return
    fi

    echo "Current file information:"
    ls -ld -- "$VALIDATED_PATH"

    read -rp "Change ownership to '$username'? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Operation cancelled."
        return
    fi

    if sudo chown -- "$username" "$VALIDATED_PATH"; then
        echo "File owner updated successfully!"
        ls -ld -- "$VALIDATED_PATH"
    else
        echo "Error: Failed to change owner!"
    fi
}

# ------------------------------------------
# Change File Group
# ------------------------------------------

change_file_group() {
    echo "========== CHANGE FILE GROUP =========="

    read -rp "Enter file path: " filepath

    if ! validate_file_path "$filepath"; then
        return
    fi

    read -rp "Enter new group name: " groupname

    if ! getent group "$groupname" > /dev/null; then
        echo "Error: Group does not exist!"
        return
    fi

    read -rp "Change group to '$groupname'? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Operation cancelled."
        return
    fi

    if sudo chgrp -- "$groupname" "$VALIDATED_PATH"; then
        echo "File group updated successfully!"
        ls -ld -- "$VALIDATED_PATH"
    else
        echo "Error: Failed to change group!"
    fi
}

# ------------------------------------------
# Check File Access for a User
# ------------------------------------------

check_file_access() {
    echo "========== CHECK FILE ACCESS =========="

    read -rp "Enter file path: " filepath

    if ! validate_file_path "$filepath"; then
        return
    fi

    read -rp "Enter username: " username

    if ! getent passwd "$username" > /dev/null; then
        echo "Error: User does not exist!"
        return
    fi

    echo ""
    echo "Checking effective access for '$username'..."

    local perm result

    for perm in r w x; do
        case "$perm" in
            r) result="Read" ;;
            w) result="Write" ;;
            x) result="Execute/Traverse" ;;
        esac

        if sudo -u "$username" test "-$perm" "$VALIDATED_PATH"; then
            echo "$result: Allowed"
        else
            echo "$result: Denied"
        fi
    done

    echo ""
    echo "Note: These are access checks, not file-content tests."
}

# ------------------------------------------
# File Permission Management Menu
# ------------------------------------------

manage_file_permissions() {
    local option

    while true; do
        echo ""
        echo "=========================================="
        echo "         FILE PERMISSION MANAGEMENT"
        echo "=========================================="
        echo "1. View File Permissions"
        echo "2. Change File Permissions (chmod)"
        echo "3. Change File Owner (chown)"
        echo "4. Change File Group (chgrp)"
        echo "5. Check User File Access"
        echo "0. Return to Main Menu"
        echo "=========================================="

        read -rp "Enter choice: " option

        case "$option" in
            1) view_file_permissions ;;
            2) change_file_permissions ;;
            3) change_file_owner ;;
            4) change_file_group ;;
            5) check_file_access ;;
            0) return ;;
            *) echo "Invalid choice!" ;;
        esac

        echo ""
        read -rp "Press Enter to continue..."
    done
}

# ==================================================
# MODULE 4: ACCESS CONTROL LIST (ACL) MANAGEMENT
# ==================================================

# ------------------------------------------
# View ACL Permissions
# ------------------------------------------

view_acl() {
    echo "========== VIEW ACL =========="

    read -rp "Enter file/directory path: " filepath

    if ! validate_file_path "$filepath"; then
        return
    fi

    echo ""
    echo "Current Access Control List:"
    getfacl -- "$VALIDATED_PATH"
}

# ------------------------------------------
# Grant ACL Permission to User
# ------------------------------------------

grant_user_acl() {
    echo "========== GRANT USER ACL =========="

    read -rp "Enter file/directory path: " filepath

    if ! validate_file_path "$filepath"; then
        return
    fi

    read -rp "Enter username: " username

    if ! valid_username "$username"; then
        echo "Error: Invalid username!"
        return
    fi

    if ! getent passwd "$username" > /dev/null; then
        echo "Error: User does not exist!"
        return
    fi

    read -rp "Enter permissions (r, w, rw, rx, rwx): " perms

    case "$perms" in
        r|w|rw|rx|rwx)
            ;;
        *)
            echo "Error: Invalid permissions!"
            return
            ;;
    esac

    echo ""
    echo "Current ACL:"
    getfacl -- "$VALIDATED_PATH"

    echo ""
    echo "Granting '$perms' permission to '$username'."

    read -rp "Continue? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Operation cancelled."
        return
    fi

    if sudo setfacl -m "u:${username}:${perms}" \
        -- "$VALIDATED_PATH"; then

        echo "ACL permission granted successfully!"

        echo ""
        echo "Updated ACL:"
        getfacl -- "$VALIDATED_PATH"
    else
        echo "Error: Failed to set ACL!"
    fi
}

# ------------------------------------------
# Grant ACL Permission to Group
# ------------------------------------------

grant_group_acl() {
    echo "========== GRANT GROUP ACL =========="

    read -rp "Enter file/directory path: " filepath

    if ! validate_file_path "$filepath"; then
        return
    fi

    read -rp "Enter group name: " groupname

    if ! valid_groupname "$groupname"; then
        echo "Error: Invalid group name!"
        return
    fi

    if ! getent group "$groupname" > /dev/null; then
        echo "Error: Group does not exist!"
        return
    fi

    read -rp "Enter permissions (r, w, rw, rx, rwx): " perms

    case "$perms" in
        r|w|rw|rx|rwx)
            ;;
        *)
            echo "Error: Invalid permissions!"
            return
            ;;
    esac

    read -rp "Apply group ACL? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Operation cancelled."
        return
    fi

    if sudo setfacl -m "g:${groupname}:${perms}" \
        -- "$VALIDATED_PATH"; then

        echo "Group ACL updated successfully!"

        getfacl -- "$VALIDATED_PATH"
    else
        echo "Error: Failed to update group ACL!"
    fi
}

# ------------------------------------------
# Remove User ACL
# ------------------------------------------

remove_user_acl() {
    echo "========== REMOVE USER ACL =========="

    read -rp "Enter file/directory path: " filepath

    if ! validate_file_path "$filepath"; then
        return
    fi

    read -rp "Enter username: " username

    if ! valid_username "$username"; then
        echo "Error: Invalid username!"
        return
    fi

    if ! getent passwd "$username" > /dev/null; then
        echo "Error: User does not exist!"
        return
    fi

    echo ""
    echo "Current ACL:"
    getfacl -- "$VALIDATED_PATH"

    read -rp "Remove ACL entry for '$username'? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Operation cancelled."
        return
    fi

    if sudo setfacl -x "u:${username}" \
        -- "$VALIDATED_PATH"; then

        echo "User ACL entry removed!"

        getfacl -- "$VALIDATED_PATH"
    else
        echo "Error: Failed to remove ACL!"
    fi
}

# ------------------------------------------
# Remove Extended ACL Entries
# ------------------------------------------

remove_extended_acl() {
    echo "========== REMOVE EXTENDED ACL =========="

    read -rp "Enter file/directory path: " filepath

    if ! validate_file_path "$filepath"; then
        return
    fi

    echo ""
    echo "WARNING: This removes extended access ACL entries."
    echo "Basic owner, group and others permissions remain."
    echo "Default ACLs on directories are not removed."

    echo ""
    getfacl -- "$VALIDATED_PATH"

    read -rp "Type REMOVE to confirm: " confirm

    if [[ "$confirm" != "REMOVE" ]]; then
        echo "Operation cancelled."
        return
    fi

    if sudo setfacl -b -- "$VALIDATED_PATH"; then
        echo "Extended ACL entries removed!"

        getfacl -- "$VALIDATED_PATH"
    else
        echo "Error: Failed to remove extended ACL!"
    fi
}

# ------------------------------------------
# ACL Management Submenu
# ------------------------------------------

manage_acl() {
    local option

    while true; do
        echo ""
        echo "=========================================="
        echo "            ACL MANAGEMENT"
        echo "=========================================="
        echo "1. View ACL Permissions"
        echo "2. Grant ACL to User"
        echo "3. Grant ACL to Group"
        echo "4. Remove User ACL"
        echo "5. Remove Extended ACL Entries"
        echo "0. Return to Main Menu"
        echo "=========================================="

        read -rp "Enter choice: " option

        case "$option" in
            1) view_acl ;;
            2) grant_user_acl ;;
            3) grant_group_acl ;;
            4) remove_user_acl ;;
            5) remove_extended_acl ;;
            0) return ;;
            *) echo "Invalid choice!" ;;
        esac

        echo ""
        read -rp "Press Enter to continue..."
    done
}

# ==================================================
# MODULE 5: SUDO PRIVILEGE MANAGEMENT
# ==================================================

# Dedicated directory for managed sudo policies
SUDO_POLICY_DIR="/etc/sudoers.d"
SUDO_POLICY_PREFIX="lab_upm_"

# Approved command for the educational demonstration
APPROVED_SUDO_COMMAND="/usr/bin/id"

# ------------------------------------------
# Validate Test Account
# ------------------------------------------

validate_sudo_user() {
    local username="$1"
    local uid

    if ! valid_username "$username"; then
        echo "Error: Invalid username!"
        return 1
    fi

    # Restrict this module to dedicated lab accounts.
    if [[ "$username" != lab_* ]]; then
        echo "Error: Only lab_ accounts are supported!"
        return 1
    fi

    if ! getent passwd "$username" >/dev/null; then
        echo "Error: User does not exist!"
        return 1
    fi

    uid=$(id -u "$username") || return 1

    if (( uid < 1000 )); then
        echo "Error: System accounts are not allowed!"
        return 1
    fi

    if [[ "$username" == "$(id -un)" ]]; then
        echo "Error: Cannot modify the current account!"
        return 1
    fi

    return 0
}

# ------------------------------------------
# Get Managed Policy Path
# ------------------------------------------

get_sudo_policy_path() {
    local username="$1"

    SUDO_POLICY_PATH="${SUDO_POLICY_DIR}/${SUDO_POLICY_PREFIX}${username}"
}

# ------------------------------------------
# View User Sudo Privileges
# ------------------------------------------

view_sudo_privileges() {
    local username

    echo "========== VIEW SUDO PRIVILEGES =========="

    read -rp "Enter username: " username

    if ! getent passwd "$username" >/dev/null; then
        echo "Error: User does not exist!"
        return
    fi

    echo ""
    echo "Sudo privileges for $username:"
    echo ""

    sudo -l -U "$username"
}

# ------------------------------------------
# Grant Limited Sudo Privilege
# ------------------------------------------

grant_sudo_privilege() {
    local username
    local confirm
    local temp_policy

    echo "========== GRANT SUDO PRIVILEGE =========="

    read -rp "Enter test username: " username

    if ! validate_sudo_user "$username"; then
        return
    fi

    get_sudo_policy_path "$username"

    if [[ -e "$SUDO_POLICY_PATH" ]]; then
        echo "Error: Managed policy already exists!"
        return
    fi

    echo ""
    echo "User: $username"
    echo "Approved command: $APPROVED_SUDO_COMMAND"
    echo "Arguments: None"
    echo "Run as: root"
    echo ""
    echo "This does NOT grant full administrator access."
    echo "The user must authenticate as required by sudo."

    read -rp "Type GRANT to confirm: " confirm

    if [[ "$confirm" != "GRANT" ]]; then
        echo "Operation cancelled."
        return
    fi

    # First validate the current system configuration.
    if ! sudo visudo -c; then
        echo "Error: Existing sudoers configuration is invalid!"
        return
    fi

    # Create a temporary policy file.
    temp_policy=$(mktemp) || {
        echo "Error: Could not create temporary file!"
        return
    }

    # Permit exactly /usr/bin/id with no arguments.
    printf '%s ALL=(root) %s ""\n' \
        "$username" \
        "$APPROVED_SUDO_COMMAND" > "$temp_policy"

    chmod 600 "$temp_policy"

    echo ""
    echo "Validating proposed policy..."

    if ! sudo visudo -cf "$temp_policy"; then
        echo "Error: Invalid sudoers policy!"
        rm -f -- "$temp_policy"
        return
    fi

    # Install only after syntax validation.
    # Refuse to overwrite any existing managed policy.
    if sudo test -e "$SUDO_POLICY_PATH"; then
        echo "Error: Policy already exists!"
        rm -f -- "$temp_policy"
        return
    fi

    if sudo install -o root -g root -m 0440 \
        "$temp_policy" "$SUDO_POLICY_PATH"; then

        echo "Policy installed."
    else
        echo "Error: Failed to install policy!"
        rm -f -- "$temp_policy"
        return
    fi

    rm -f -- "$temp_policy"

    echo ""
    echo "Validating complete sudoers configuration..."

    if sudo visudo -c; then
        echo ""
        echo "Limited sudo privilege granted successfully!"
        echo "Allowed command: sudo $APPROVED_SUDO_COMMAND"
    else
        echo "Validation failed! Removing newly installed policy."
        sudo rm -f -- "$SUDO_POLICY_PATH"
        echo "Check sudoers configuration manually."
    fi
}

# ------------------------------------------
# Revoke Limited Sudo Privilege
# ------------------------------------------

revoke_sudo_privilege() {
    local username
    local confirm
    local expected_policy
    local actual_policy

    echo "========== REVOKE SUDO PRIVILEGE =========="

    read -rp "Enter test username: " username

    if ! validate_sudo_user "$username"; then
        return
    fi

    get_sudo_policy_path "$username"

    if ! sudo test -f "$SUDO_POLICY_PATH"; then
        echo "No managed policy found for this user!"
        return
    fi

    # Do not delete a policy modified outside our tool.
    expected_policy=$(printf '%s ALL=(root) %s ""' \
        "$username" "$APPROVED_SUDO_COMMAND")

    actual_policy=$(sudo cat -- "$SUDO_POLICY_PATH") || {
        echo "Error: Cannot read policy!"
        return
    }

    if [[ "$actual_policy" != "$expected_policy" ]]; then
        echo "Error: Policy differs from our approved template!"
        echo "Manual administrator review is required."
        return
    fi

    echo ""
    echo "Policy to revoke:"
    echo "$actual_policy"

    read -rp "Type REVOKE to confirm: " confirm

    if [[ "$confirm" != "REVOKE" ]]; then
        echo "Operation cancelled."
        return
    fi

    if sudo rm -- "$SUDO_POLICY_PATH"; then
        echo "Managed sudo privilege revoked successfully!"
        echo "Other existing sudo permissions are unaffected."
    else
        echo "Error: Failed to revoke privilege!"
    fi
}

# ------------------------------------------
# Validate Sudoers Configuration
# ------------------------------------------

validate_sudoers() {
    echo "========== VALIDATE SUDOERS =========="

    if sudo visudo -c; then
        echo ""
        echo "Sudoers syntax validation passed!"
    else
        echo ""
        echo "WARNING: Sudoers validation failed!"
    fi
}

# ------------------------------------------
# View Managed Policies
# ------------------------------------------

view_managed_sudo_policies() {
    local found=0
    local file

    echo "========== MANAGED SUDO POLICIES =========="

    echo ""
    echo "Policies created by this application:"
    echo ""

    for file in "$SUDO_POLICY_DIR"/lab_upm_*; do

        if ! sudo test -f "$file"; then
            continue
        fi

        found=1

        echo "----------------------------------"
        echo "Policy: $file"

        sudo cat -- "$file"
    done

    if (( found == 0 )); then
        echo "No managed sudo policies found."
    fi
}

# ------------------------------------------
# Sudo Privilege Management Submenu
# ------------------------------------------

manage_sudo_privileges() {
    local option

    while true; do

        echo ""
        echo "=========================================="
        echo "        SUDO PRIVILEGE MANAGEMENT"
        echo "=========================================="
        echo "1. View User Sudo Privileges"
        echo "2. Grant Limited Sudo Privilege"
        echo "3. Revoke Limited Sudo Privilege"
        echo "4. Validate Sudoers Configuration"
        echo "5. View Managed Sudo Policies"
        echo "0. Return to Main Menu"
        echo "=========================================="

        read -rp "Enter choice: " option

        case "$option" in
            1) view_sudo_privileges ;;
            2) grant_sudo_privilege ;;
            3) revoke_sudo_privilege ;;
            4) validate_sudoers ;;
            5) view_managed_sudo_policies ;;
            0) return ;;
            *) echo "Invalid choice!" ;;
        esac

        echo ""
        read -rp "Press Enter to continue..."
    done
}

# ==================================================
# MODULE 6: DISK QUOTA MANAGEMENT
# ==================================================

QUOTA_MOUNT="/mnt/quota_lab"

# ------------------------------------------
# Check Quota Filesystem
# ------------------------------------------

check_quota_filesystem() {
    local source
    local fstype
    local status

    if ! mountpoint -q "$QUOTA_MOUNT"; then
        echo "Error: Quota lab filesystem is not mounted!"
        return 1
    fi

    source=$(findmnt -n -o SOURCE --target "$QUOTA_MOUNT")
    fstype=$(findmnt -n -o FSTYPE --target "$QUOTA_MOUNT")

    if [[ "$fstype" != "ext4" || "$source" != /dev/loop* ]]; then
        echo "Error: Unexpected quota filesystem!"
        echo "Expected an ext4 loop-mounted filesystem."
        return 1
    fi

    status=$(sudo quotaon -p -u "$QUOTA_MOUNT" 2>&1)

    if [[ "$status" != *"is on"* ]]; then
        echo "Error: User quotas are not enabled!"
        echo "$status"
        return 1
    fi

    return 0
}

# ------------------------------------------
# Validate Quota User
# ------------------------------------------

validate_quota_user() {
    local username="$1"
    local uid

    if ! valid_username "$username"; then
        echo "Error: Invalid username!"
        return 1
    fi

    if [[ "$username" != lab_* ]]; then
        echo "Error: Only lab_ accounts are allowed!"
        return 1
    fi

    if ! getent passwd "$username" >/dev/null; then
        echo "Error: User does not exist!"
        return 1
    fi

    uid=$(id -u "$username") || return 1

    if (( uid < 1000 )); then
        echo "Error: System accounts cannot be modified!"
        return 1
    fi

    return 0
}

# ------------------------------------------
# View User Disk Quota
# ------------------------------------------

view_user_quota() {
    local username

    echo "========== VIEW USER DISK QUOTA =========="

    if ! check_quota_filesystem; then
        return
    fi

    read -rp "Enter username: " username

    if ! validate_quota_user "$username"; then
        return
    fi

    echo ""
    echo "Disk quota for $username:"
    sudo quota -u "$username"
}

# ------------------------------------------
# Set or Modify Disk Quota
# ------------------------------------------

configure_user_quota() {
    local username
    local soft_mb
    local hard_mb
    local soft_kib
    local hard_kib
    local confirm

    echo "========== CONFIGURE USER QUOTA =========="

    if ! check_quota_filesystem; then
        return
    fi

    read -rp "Enter username: " username

    if ! validate_quota_user "$username"; then
        return
    fi

    read -rp "Enter soft limit (MiB): " soft_mb
    read -rp "Enter hard limit (MiB): " hard_mb

    if [[ ! "$soft_mb" =~ ^[0-9]+$ ||
          ! "$hard_mb" =~ ^[0-9]+$ ]]; then
        echo "Error: Limits must be positive integers!"
        return
    fi

    # Reject zero and unnecessarily large lab quotas.
    if (( 10#$soft_mb < 1 || 10#$hard_mb < 1 )); then
        echo "Error: Limits must be greater than zero!"
        return
    fi

    # Strip leading zeros before arithmetic.
    soft_mb=$((10#$soft_mb))
    hard_mb=$((10#$hard_mb))

    if (( soft_mb > hard_mb )); then
        echo "Error: Soft limit cannot exceed hard limit!"
        return
    fi

    if (( hard_mb > 200 )); then
        echo "Error: Maximum permitted lab quota is 200 MiB!"
        return
    fi

    soft_kib=$((soft_mb * 1024))
    hard_kib=$((hard_mb * 1024))

    echo ""
    echo "----------------------------------"
    echo "Username   : $username"
    echo "Filesystem : $QUOTA_MOUNT"
    echo "Soft limit : $soft_mb MiB"
    echo "Hard limit : $hard_mb MiB"
    echo "----------------------------------"

    echo ""
    echo "Current quota:"
    sudo quota -u "$username"

    read -rp "Apply quota changes? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Operation cancelled."
        return
    fi

    if sudo setquota -u "$username" \
        "$soft_kib" "$hard_kib" 0 0 "$QUOTA_MOUNT"; then

        echo ""
        echo "Disk quota updated successfully!"

        echo ""
        echo "Updated quota:"
        sudo quota -u "$username"
    else
        echo "Error: Failed to configure disk quota!"
    fi
}

# ------------------------------------------
# Remove User Quota Limits
# ------------------------------------------

remove_user_quota() {
    local username
    local confirm

    echo "========== REMOVE USER QUOTA =========="

    if ! check_quota_filesystem; then
        return
    fi

    read -rp "Enter username: " username

    if ! validate_quota_user "$username"; then
        return
    fi

    echo ""
    echo "Current quota:"
    sudo quota -u "$username"

    echo ""
    echo "WARNING: This will remove block and inode limits."
    echo "It will NOT delete the user's files."

    read -rp "Type REMOVE to confirm: " confirm

    if [[ "$confirm" != "REMOVE" ]]; then
        echo "Operation cancelled."
        return
    fi

    if sudo setquota -u "$username" 0 0 0 0 "$QUOTA_MOUNT"; then
        echo ""
        echo "Quota limits removed successfully!"
        sudo quota -u "$username"
    else
        echo "Error: Failed to remove quota limits!"
    fi
}

# ------------------------------------------
# View Filesystem Quota Report
# ------------------------------------------

view_quota_report() {
    echo "========== FILESYSTEM QUOTA REPORT =========="

    if ! check_quota_filesystem; then
        return
    fi

    sudo repquota -u "$QUOTA_MOUNT"
}

# ------------------------------------------
# Check Quota Status
# ------------------------------------------

check_quota_status() {
    echo "========== QUOTA STATUS =========="

    echo ""
    echo "Mount information:"
    findmnt "$QUOTA_MOUNT"

    echo ""
    echo "User quota status:"

    if check_quota_filesystem; then
        sudo quotaon -p -u "$QUOTA_MOUNT"
        echo ""
        echo "Quota filesystem is ready!"
    fi
}

# ------------------------------------------
# Disk Quota Management Submenu
# ------------------------------------------

manage_disk_quotas() {
    local option

    while true; do
        echo ""
        echo "=========================================="
        echo "          DISK QUOTA MANAGEMENT"
        echo "=========================================="
        echo "1. View User Disk Quota"
        echo "2. Set User Disk Quota"
        echo "3. Modify Existing Quota"
        echo "4. Remove User Quota Limits"
        echo "5. View Filesystem Quota Report"
        echo "6. Check Quota Status"
        echo "0. Return to Main Menu"
        echo "=========================================="

        read -rp "Enter choice: " option

        case "$option" in
            1) view_user_quota ;;
            2) configure_user_quota ;;
            3) configure_user_quota ;;
            4) remove_user_quota ;;
            5) view_quota_report ;;
            6) check_quota_status ;;
            0) return ;;
            *) echo "Invalid choice!" ;;
        esac

        echo ""
        read -rp "Press Enter to continue..."
    done
}

# ==================================================
# MODULE 7: SECURITY AUDITING
# ==================================================

AUDIT_LAB="$HOME/LinuxCaseStudy/permission_lab"
AUDIT_REPORT_DIR="$HOME/LinuxCaseStudy/audit_reports"

# ------------------------------------------
# Validate Audit Environment
# ------------------------------------------

check_audit_environment() {
    if [[ ! -d "$AUDIT_LAB" || -L "$AUDIT_LAB" ]]; then
        echo "Error: Permission lab directory not found!"
        return 1
    fi

    # Confirm that the audit target is the expected lab.
    if [[ "$(realpath -e "$AUDIT_LAB")" != \
          "$(realpath -e "$HOME/LinuxCaseStudy")/permission_lab" ]]; then
        echo "Error: Invalid audit directory!"
        return 1
    fi

    return 0
}

# ------------------------------------------
# Scan World-Writable Files
# ------------------------------------------

scan_world_writable() {
    echo "========== WORLD-WRITABLE FILE AUDIT =========="

    check_audit_environment || return

    echo ""
    echo "Scanning for files writable by others..."
    echo ""

    sudo find "$AUDIT_LAB" -xdev -type f \
        -perm -0002 -printf '%m %u:%g %p\n'

    echo ""
    echo "Audit completed."
    echo "Review whether these permissions are necessary."
}

# ------------------------------------------
# Scan World-Readable Files
# ------------------------------------------

scan_world_readable() {
    echo "========== WORLD-READABLE FILE AUDIT =========="

    check_audit_environment || return

    echo ""
    echo "Scanning for files readable by others..."
    echo ""

    sudo find "$AUDIT_LAB" -xdev -type f \
        -perm -0004 -printf '%m %u:%g %p\n'

    echo ""
    echo "Audit completed."
    echo "World-readable files are not always insecure."
}

# ------------------------------------------
# Scan SUID and SGID Files
# ------------------------------------------

scan_special_permissions() {
    echo "========== SUID/SGID AUDIT =========="

    check_audit_environment || return

    echo ""
    echo "Scanning for special privilege bits..."
    echo ""

    sudo find "$AUDIT_LAB" -xdev -type f \
        -perm /6000 -printf '%m %u:%g %p\n'

    echo ""
    echo "Audit completed."
}

# ------------------------------------------
# Audit ACL Permissions
# ------------------------------------------

audit_acl_permissions() {
    local filepath
    local acl_data
    local found=0

    echo "========== ACL SECURITY AUDIT =========="

    check_audit_environment || return

    echo ""
    echo "Scanning for extended ACL entries..."
    echo ""

    while IFS= read -r -d '' filepath; do

        acl_data=$(sudo getfacl -cp -- "$filepath" 2>/dev/null)

        # Named user/group and named default ACL entries.
        if printf '%s\n' "$acl_data" |
           grep -Eq '^(user|group):[^:]+:|^default:(user|group):[^:]+:'; then

            echo "----------------------------------"
            echo "File: $filepath"
            echo "$acl_data"

            found=1
        fi

    done < <(sudo find "$AUDIT_LAB" -xdev \
        \( -type f -o -type d \) -print0)

    if (( found == 0 )); then
        echo "No named ACL entries found."
    fi

    echo ""
    echo "ACL audit completed."
}

# ------------------------------------------
# Check File Ownership
# ------------------------------------------

audit_file_ownership() {
    local expected_owner

    echo "========== FILE OWNERSHIP AUDIT =========="

    check_audit_environment || return

    expected_owner=$(id -un)

    echo ""
    echo "Expected owner: $expected_owner"
    echo "Files owned by other users:"
    echo ""

    sudo find "$AUDIT_LAB" -xdev -type f \
        ! -user "$expected_owner" \
        -printf '%u:%g %m %p\n'

    echo ""
    echo "Different ownership is not automatically unsafe."
    echo "Review findings against intended file ownership."
}

# ------------------------------------------
# Generate Full Security Audit Report
# ------------------------------------------

generate_security_report() {
    local report_file
    local timestamp

    echo "========== GENERATE SECURITY REPORT =========="

    check_audit_environment || return

    if ! mkdir -p -- "$AUDIT_REPORT_DIR"; then
        echo "Error: Cannot create report directory!"
        return
    fi

    chmod 700 -- "$AUDIT_REPORT_DIR" || return

    timestamp=$(date +"%Y%m%d_%H%M%S")
    report_file="$AUDIT_REPORT_DIR/security_audit_${timestamp}_$$.txt"

    # Ensure the report is private.
    (
        umask 077

        {
            echo "=========================================="
            echo "      LINUX SECURITY AUDIT REPORT"
            echo "=========================================="
            echo "Date: $(date)"
            echo "Auditor: $(id -un)"
            echo "Target: $AUDIT_LAB"
            echo ""

            echo "========== WORLD-WRITABLE FILES =========="
            sudo find "$AUDIT_LAB" -xdev -type f \
                -perm -0002 -printf '%m %u:%g %p\n'
            echo ""

            echo "========== WORLD-READABLE FILES =========="
            sudo find "$AUDIT_LAB" -xdev -type f \
                -perm -0004 -printf '%m %u:%g %p\n'
            echo ""

            echo "========== SUID/SGID FILES =========="
            sudo find "$AUDIT_LAB" -xdev -type f \
                -perm /6000 -printf '%m %u:%g %p\n'
            echo ""

            echo "========== OWNERSHIP REVIEW =========="
            sudo find "$AUDIT_LAB" -xdev -type f \
                ! -user "$(id -un)" \
                -printf '%u:%g %m %p\n'
            echo ""

            echo "========== EXTENDED ACL REVIEW =========="
            sudo find "$AUDIT_LAB" -xdev \
                \( -type f -o -type d \) -print0 |
            while IFS= read -r -d '' filepath; do

                acl_data=$(sudo getfacl -cp -- "$filepath" 2>/dev/null)

                if printf '%s\n' "$acl_data" |
                   grep -Eq '^(user|group):[^:]+:|^default:(user|group):[^:]+:'; then
                    echo "File: $filepath"
                    echo "$acl_data"
                    echo ""
                fi
            done

            echo ""
            echo "========== RECOMMENDATIONS =========="
            echo "1. Review unnecessary world-write permissions."
            echo "2. Classify world-readable files by sensitivity."
            echo "3. Investigate unexpected SUID/SGID settings."
            echo "4. Review named ACL entries and effective rights."
            echo "5. Verify file owners against approved policy."
            echo ""
            echo "END OF REPORT"

        } > "$report_file"
    )

    if [[ -f "$report_file" ]]; then
        chmod 600 -- "$report_file"

        echo ""
        echo "Report generated:"
        echo "$report_file"
    else
        echo "Error: Report generation failed!"
    fi
}

# ------------------------------------------
# View Previous Audit Reports
# ------------------------------------------

view_audit_reports() {
    local report_file
    local -a reports=()
    local option
    local i

    echo "========== PREVIOUS AUDIT REPORTS =========="

    if [[ ! -d "$AUDIT_REPORT_DIR" ]]; then
        echo "No audit reports available."
        return
    fi

    shopt -s nullglob
    reports=("$AUDIT_REPORT_DIR"/security_audit_*.txt)
    shopt -u nullglob

    if (( ${#reports[@]} == 0 )); then
        echo "No audit reports found."
        return
    fi

    echo ""

    for i in "${!reports[@]}"; do
        echo "$((i + 1)). $(basename "${reports[$i]}")"
    done

    echo ""
    read -rp "Enter report number (0 to cancel): " option

    if [[ "$option" == "0" ]]; then
        return
    fi

    if [[ ! "$option" =~ ^[0-9]+$ ]]; then
        echo "Invalid selection!"
        return
    fi

    if (( 10#$option < 1 ||
          10#$option > ${#reports[@]} )); then
        echo "Invalid report number!"
        return
    fi

    report_file="${reports[$((10#$option - 1))]}"

    echo ""
    less -- "$report_file"
}

# ------------------------------------------
# Security Auditing Submenu
# ------------------------------------------

manage_security_audit() {
    local option

    while true; do
        echo ""
        echo "=========================================="
        echo "           SECURITY AUDITING"
        echo "=========================================="
        echo "1. Scan World-Writable Files"
        echo "2. Scan World-Readable Files"
        echo "3. Scan SUID/SGID Files"
        echo "4. Audit ACL Permissions"
        echo "5. Check File Ownership"
        echo "6. Generate Full Security Report"
        echo "7. View Previous Audit Reports"
        echo "0. Return to Main Menu"
        echo "=========================================="

        read -rp "Enter choice: " option

        case "$option" in
            1) scan_world_writable ;;
            2) scan_world_readable ;;
            3) scan_special_permissions ;;
            4) audit_acl_permissions ;;
            5) audit_file_ownership ;;
            6) generate_security_report ;;
            7) view_audit_reports ;;
            0) return ;;
            *) echo "Invalid choice!" ;;
        esac

        echo ""
        read -rp "Press Enter to continue..."
    done
}


# ==========================================
# ACTIVITY LOGGING MODULE
# ==========================================

LOG_DIR="$HOME/LinuxCaseStudy/logs"
LOG_FILE="$LOG_DIR/activity.log"

mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"

touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

log_action() {
    local action="$1"
    local target="$2"
    local status="$3"

    printf '[%s] ADMIN=%s | ACTION=%s | TARGET=%s | STATUS=%s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$(id -un)" \
        "$action" \
        "$target" \
        "$status" >> "$LOG_FILE"
}

view_activity_logs() {
    echo "========== ACTIVITY LOGS =========="

    if [[ -s "$LOG_FILE" ]]; then
        less -- "$LOG_FILE"
    else
        echo "No activity logs available."
    fi
}


while true
do
    clear

    echo "============================================"
    echo "    USER AND PERMISSION MANAGEMENT TOOL"
    echo "============================================"
    echo " 1. Add New User"
    echo " 2. Delete User"
    echo " 3. Manage Groups"
    echo " 4. Modify File Permissions"
    echo " 5. Configure ACL"
    echo " 6. Manage Sudo Privileges"
    echo " 7. Manage Disk Quotas"
    echo " 8. Security Audit"
    echo " 9. View System Users"
    echo "10. View Activity Logs"
    echo " 0. Exit"
    echo "============================================"

    read -rp "Enter your choice: " choice

    case "$choice" in
        1) add_user ;;
        2) delete_user ;;
        3) manage_groups ;;
        4) manage_file_permissions ;;
        5) manage_acl ;;
        6) manage_sudo_privileges	 ;;
        7) manage_disk_quotas ;;
        8) manage_security_audit ;;
        9) view_user ;;
        10) view_activity_logs ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice!"
            ;;
    esac

    echo ""
    read -rp "Press Enter to continue..."
done
