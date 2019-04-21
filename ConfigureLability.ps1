# The easiest way to install Lability is to leverage PowerShellGet
Find-Module -Name Lability | Install-Module


Update-Module -Name Lability


$LabDefaultVMParameters = @{
    InputLocale = 'sv-SE'
    SystemLocale = 'sv-SE'
    ProcessorCount = '2'
    StartupMemory = '2147483648'
    RegisteredOwner = 'snajd'
    RegisteredOrganization = 'LABLABLAB'
    TimeZone = 'W. Europe Standard Time'
    SwitchName = 'INTERNAL'
}

Set-LabVMDefault @LabDefaultVMParameters

# If necessary, create a new virtual switch. This is an example of creating an Internal switch which uses NAT for external VM connectivity:

#New-VMSwitch -Name 'INTERNAL' -SwitchType Internal

$NICAlias = (Get-NetAdapter 'vEthernet (Lab-NAT)').Name
New-NetIPAddress -IPAddress 10.1.1.0 -PrefixLength 24 -InterfaceAlias $NICAlias
New-NetNAT -Name NATNetwork -InternalIPInterfaceAddressPrefix 10.1.1.0/24

# use OSBuilder pre patched media

# register Windows 2019 Lab Media from MSDN
Register-LabMedia -Id 2019_x64_Standard_EN_MSDN -MediaType ISO -ImageName "Windows Server 2019 Standard" -Description "Windows Server 2019 Standard" -Filename "en_windows_server_2019_x64_dvd_4cb967d8.iso" -Architecture x64 -uri "file://c:/iso/en_windows_server_2019_x64_dvd_4cb967d8.iso"
Register-LabMedia -id 2019_x64_Standard_EN_Desktop_MSDN -MediaType ISO -ImageName "Windows Server 2019 Standard (Desktop Experience)" -Description "Windows Server 2019 Standard (Desktop Experience)" -Filename "en_windows_server_2019_x64_dvd_4cb967d8.iso" -Architecture x64 -uri "file://c:/iso/en_windows_server_2019_x64_dvd_4cb967d8.iso"
Register-LabMedia -id 2019_x64_DataCenter_EN_MSDN -MediaType ISO -ImageName "Windows Server 2019 Datacenter" -Description "Windows Server 2019 Datacenter" -Filename "en_windows_server_2019_x64_dvd_4cb967d8.iso" -Architecture x64 -uri "file://c:/iso/en_windows_server_2019_x64_dvd_4cb967d8.iso"
Register-LabMedia -id 2019_x64_DataCenter_EN_Desktop_MSDN -MediaType ISO -ImageName "Windows Server 2019 Datacenter (Desktop Experience)" -Description "Windows Server 2019 Datacenter (Desktop Experience)" -Filename "en_windows_server_2019_x64_dvd_4cb967d8.iso" -Architecture x64 -uri "file://c:/iso/en_windows_server_2019_x64_dvd_4cb967d8.iso"-Force

# set Windows 2019 Standard as default VM Media
Set-LabVMDefault -Media 2019_x64_Standard_EN_Desktop_MSDN

# register Windows 10 Lab Media from MSDN

Register-LabMedia -id WIN10_1809_x64_Enterprise_EN_MSDN -MediaType ISO -imagename "Windows 10 Enterprise" -Description "Windows 10 Enterprise" -Filename "en_windows_10_business_edition_version_1809_updated_sept_2018_x64_dvd_f0b7dc68.iso" -Architecture x64 -uri "file://c:/iso/en_windows_10_business_edition_version_1809_updated_sept_2018_x64_dvd_f0b7dc68.iso"


Start-LabHostConfiguration

# tanka alla DSC-moduler 
#Invoke-LabResourceDownload -ConfigurationData C:\github\lab\2019Lab.psd1 -DSCResources
#C:\programdata\Lability\Modules> dir | foreach {Expand-Archive $_}
#C:\programdata\Lability\Modules> move * -Destination "C:\Program Files\WindowsPowerShell\Modules\"
install-module xComputerManagement,xNetworking,xActiveDirectory,xSmbShare,xDHCPServer,xDNSServer
