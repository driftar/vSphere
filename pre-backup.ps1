<#
.SYNOPSIS
    This script will start a vMotion of all virtual machines on a specified datastore to a specified ESXi host. If you are working with a backup software which is licensed
    to a specific host, this will probably help you. Only recommended in smaller environments or if you have enough ressources on this host.
.DESCRIPTION
    The script loads a PSSnapin; it sets some PowerCLI options; it connects to your vCenter Server with the given credentials; it gets all your VMs in an array;
    it starts then a asynchronous Host vMotion of all the VMs in the array to a specified ESXi host.
.NOTES
    File Name      : pre-backup.ps1
    Version:       : 2.0
    Author         : Karl Widmer (info@driftar.ch)
    Prerequisite   : PowerShell V2 over Vista and upper / VMware PowerCLI 6
    Tested on:     : Windows Server 2012 R2
    with PowerCLI  : PowerCLI 6.3 Release 1 build 3737840
    with PowerShell: 4.0
    with ESXi:     : 6.0.0 Build 4510822
    Copyright 2016 - Karl Widmer / driftar's Blog (www.driftar.ch)
.LINK
    Script posted over:
    https://www.driftar.ch
#>

# Load PowerCLI cmdlets  
Add-PSSnapin VMware.VimAutomation.Core -ErrorAction "SilentlyContinue" 

# Set PowerCLI behaviour regarding invalid certificates and deprecation warnings 
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -DisplayDeprecationWarnings:$false -confirm:$false

# Define vCenter User and target Datastore  
$vcHost = 'vcenter.domain.com'  
$vcUser = 'administrator@domain.com'  
$vcPass = 'password'  
$datastore = 'your_datastore'  
$cluster = 'your_cluster'
$targethost = 'esx.domain.com'
 
# Connect to vCenter  
Connect-VIServer $vcHost -User $vcUser -Password $vcPass  

# Get VMs (pass array of VMs to $VMs, for example 'get-datastore test | get-vm')  
$VMs = Get-Datastore $datastore | get-vm

# Get Cluster information to set DRS to Manual for backup window
Set-Cluster $cluster -DrsAutomationLevel Manual -Confirm:$false

Foreach($vm in $vms) {
    Write-Host ("Start Host vMotion for VM '" + $VM.Name + "'")

    Move-VM -VM (Get-VM -Name $vm) -Destination (Get-Vmhost $targethost) -RunAsync

    Write-Host ("Waiting...")

    Write-Host ("Host vMotion for VM '" + $VM.Name + "' finished")  
}

<#
This last script step should probably be executed in a post-backup script step.
It sets the DRS automation level back to fully automated. Your VMs will then probably load-balance on your hosts.
#>

# Set DRS on cluster back to FullyAutomated after backup window
Set-Cluster $cluster -DrsAutomationLevel FullyAutomated -Confirm:$false