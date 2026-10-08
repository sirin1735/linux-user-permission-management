# Linux User and Permission Management Tool

A menu-driven Bash project developed for Linux to organize common Linux administration tasks through one terminal interface.

**Project title:** Design and Implementation of a Menu-Driven User and Permission Management Tool

## Features

| Module | Purpose |
|---|---|
| User management | Create, delete and inspect local user accounts |
| Group management | Manage groups and user membership |
| File permissions and ownership | Manage access using `chmod` and `chown` |
| Access control lists | Manage additional user and group permissions |
| Sudo privilege management | Manage administrative delegation |
| Disk quota management | Configure and inspect storage limits |
| Security auditing | Review permissions, ownership and potential access risks |
| Activity logging | Record and view administrative actions |

## Main Menu

| Option | Operation |
|---|---|
| 1 | Add user |
| 2 | Delete user |
| 3 | Manage groups |
| 4 | Manage file permissions |
| 5 | Manage ACL |
| 6 | Manage sudo privileges |
| 7 | Manage disk quotas |
| 8 | Manage security auditing |
| 9 | View user |
| 10 | View activity logs |
| 0 | Exit |

## Requirements

- Kali Linux
- Bash
- Linux account and file administration utilities
- ACL tools, including `setfacl` and `getfacl`
- `sudo` and quota utilities
- Administrative privileges for operations that change protected system settings

ACL and quota functionality also depend on the target filesystem and its configuration. Installing quota utilities alone does not enable quota enforcement.

## Download

```bash
git clone https://github.com/sirin1735/linux-user-permission-management.git
cd linux-user-permission-management
```

## Run

Review the script before execution. Use an isolated Kali Linux laboratory environment with a backup or virtual machine snapshot.

Check Bash syntax:

```bash
bash -n user_management.sh
```

Start the tool:

```bash
bash user_management.sh
```

If the script requires administrative privileges for its operations:

```bash
sudo bash user_management.sh
```

Select an option from the menu and follow the terminal prompts.

The script targets Linux administration. It should not be run on macOS to perform these operations.

## Example Use Case

An employee-onboarding demonstration can connect the modules:

1. Create a laboratory employee account.
2. Create a department group and add the employee.
3. Configure ownership and permissions for a test document.
4. Grant a specific access exception through an ACL.
5. Configure and verify limited sudo privileges.
6. Assign storage limits on a quota-enabled filesystem.
7. Audit the laboratory files.
8. Review the recorded administrative actions.

This sequence is a suggested integrated demonstration, not a claim that every step has been independently verified.

## Testing Status

The author reports successful individual testing of all eight modules in Linux.

Execution screenshots and detailed test records are pending inclusion. Independent reproduction, performance measurements and a complete security review are not claimed.

A Bash syntax check confirms parsing only; it does not verify runtime behavior.

## Execution Screenshots

Actual Linux terminal screenshots will be added to document:

- Main menu
- User and group operations
- File permissions and ownership
- ACL entries and effective access
- Sudo policy validation and delegation
- Quota configuration and enforcement
- Security audit findings
- Activity logs

## Security Considerations

This is an educational administration project. Its operations can modify user accounts, file access, sudo policy and storage limits.

- Use disposable test accounts and files.
- Review targets before deleting accounts or changing permissions.
- Validate sudoers changes with `visudo`.
- Check ACL masks and effective access after modifications.
- Verify quota enforcement on the intended filesystem.
- Treat audit findings as items for review, not automatic proof of a vulnerability.
- Keep passwords, access tokens and sensitive data out of source code, screenshots and logs.

## Author

GitHub: [sirin1735](https://github.com/sirin1735)

## Academic Context

