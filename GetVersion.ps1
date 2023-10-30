---
# Install the Logging Transfer Solution 
- name: Get PowerShell version
  gather_facts: false
  hosts: all
  tasks:
  
    # Get PowerShell version
    - name: Get PowerShell version
      win_shell: $($PSVersionTable.PSVersion.Major)
      register: ps_version

    # Output information
    - debug:
        msg: "Powershell version: {{ ps_version.std_out }}"
