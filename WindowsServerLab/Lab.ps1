Configuration Lab {
    <#
        Requires the following custom DSC resources:
    
            xComputerManagement: https://github.com/PowerShell/xComputerManagement
            xNetworking:         https://github.com/PowerShell/xNetworking
            xActiveDirectory:    https://github.com/PowerShell/xActiveDirectory
            xSmbShare:           https://github.com/PowerShell/xSmbShare
            xDhcpServer:         https://github.com/PowerShell/xDhcpServer
            xDnsServer:          https://github.com/PowerShell/xDnsServer
            UpdateServicesDsc:   https://github.com/PowerShell/UpdateServerDsc
            SqlServerDsc:        https://github.com/PowerShell/SqlServerDsc

        #>
        param (
            [Parameter()] [ValidateNotNull()] [PSCredential] $Credential = (Get-Credential -Credential 'Administrator')
        )
        Import-DscResource -Module xComputerManagement, NetworkingDsc, xActiveDirectory;
        Import-DscResource -Module xSmbShare, PSDesiredStateConfiguration;
        Import-DscResource -Module xDHCPServer, xDnsServer, UpdateServicesDsc;
        Import-DscResource -Module SqlServerDsc;
    
        # detta gäller för alla noder:
        node $AllNodes.Where({$true}).NodeName {
    
            LocalConfigurationManager {
    
                RebootNodeIfNeeded   = $true;
                AllowModuleOverwrite = $true;
                ConfigurationMode    = 'ApplyOnly';
                CertificateID        = $node.Thumbprint;
            }
    
            # om en IP inställningar är specificerade:
            if (-not [System.String]::IsNullOrEmpty($node.IPAddress)) {
    
                IPAddress 'PrimaryIPAddress' {
    
                    IPAddress      = $node.IPAddress;
                    InterfaceAlias = $node.InterfaceAlias;
                    # PrefixLength   = $node.PrefixLength;
                    AddressFamily  = $node.AddressFamily;
                }
    
                if (-not [System.String]::IsNullOrEmpty($node.DefaultGateway)) {
    
                    DefaultGatewayAddress 'PrimaryDefaultGateway' {
    
                        InterfaceAlias = $node.InterfaceAlias;
                        Address        = $node.DefaultGateway;
                        AddressFamily  = $node.AddressFamily;
                    }
                }
    
                if (-not [System.String]::IsNullOrEmpty($node.DnsServerAddress)) {
    
                    DnsServerAddress 'PrimaryDNSClient' {
    
                        Address        = $node.DnsServerAddress;
                        InterfaceAlias = $node.InterfaceAlias;
                        AddressFamily  = $node.AddressFamily;
                    }
                }
    
                if (-not [System.String]::IsNullOrEmpty($node.DnsConnectionSuffix)) {
    
                    DnsConnectionSuffix 'PrimaryConnectionSuffix' {
    
                        InterfaceAlias           = $node.InterfaceAlias;
                        ConnectionSpecificSuffix = $node.DnsConnectionSuffix;
                    }
                }
    
            } #end if IPAddress
    
            # alla burkar ska svara på ping
            Firewall 'FPS-ICMP4-ERQ-In' {
    
                Name        = 'FPS-ICMP4-ERQ-In';
                DisplayName = 'File and Printer Sharing (Echo Request - ICMPv4-In)';
                Description = 'Echo request messages are sent as ping requests to other nodes.';
                Direction   = 'Inbound';
                Action      = 'Allow';
                Enabled     = 'True';
                Profile     = 'Any';
            }
    
            Firewall 'FPS-ICMP6-ERQ-In' {
    
                Name        = 'FPS-ICMP6-ERQ-In';
                DisplayName = 'File and Printer Sharing (Echo Request - ICMPv6-In)';
                Description = 'Echo request messages are sent as ping requests to other nodes.';
                Direction   = 'Inbound';
                Action      = 'Allow';
                Enabled     = 'True';
                Profile     = 'Any';
            }
        } #end nodes ALL
    
        node $AllNodes.Where({$_.Role -in 'DC'}).NodeName {
    
            ## Flip credential into username@domain.com
            $domainCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("$($Credential.UserName)@$($node.DomainName)", $Credential.Password);
    
            xComputer 'Hostname' {
    
                Name = $node.NodeName;
            }
    
            ## Hack to fix DependsOn with hypens "bug" :(
            foreach ($feature in @(
                    'AD-Domain-Services',
                    'GPMC',
                    'RSAT-AD-Tools',
                    'DHCP',
                    'RSAT-DHCP'
                )) {
                WindowsFeature $feature.Replace('-','') {
    
                    Ensure               = 'Present';
                    Name                 = $feature;
                    IncludeAllSubFeature = $true;
                }
            }
    
            xADDomain 'ADDomain' {
    
                DomainName                    = $node.DomainName;
                SafemodeAdministratorPassword = $Credential;
                DomainAdministratorCredential = $Credential;
                DependsOn                     = '[WindowsFeature]ADDomainServices';
            }
    
            xDhcpServerAuthorization 'DhcpServerAuthorization' {
    
                Ensure    = 'Present';
                DependsOn = '[WindowsFeature]DHCP','[xADDomain]ADDomain';
                #PsDscRunAsCredential = Get-Credential
            }
            
            # för varje scope.
            foreach ($DHCPScope in $ConfigurationData.LabDHCPConfig) {

                #döp scope till ScopeID och ersätt punkter med underscore
                xDhcpServerScope $DHCPScope.ScopeId.Replace(".","_") {
                    ScopeId       = $DHCPScope.ScopeID;
                    Name          = $DHCPScope.Name;
                    IPStartRange  = $DHCPScope.IPStartRange;
                    IPEndRange    = $DHCPScope.IPEndRange;
                    SubnetMask    = $DHCPScope.SubnetMask;
                    LeaseDuration = $DHCPScope.LeaseDuration;
                    State         = $DHCPScope.State;
                    AddressFamily = $DHCPScope.AddressFamily;
                    DependsOn     = '[WindowsFeature]DHCP';
                }
                #if ($DHCP.ScopeOptions) {
                    foreach ($ScopeOption in $DHCPScope.ScopeOptions) {
                        #$number = 1
                        DhcpScopeOptionValue ($ScopeOption.Name + "-" + $DHCPScope.ScopeID){
                            ScopeId         = $DHCPScope.ScopeID;
                            OptionId        = $ScopeOption.OptionId;
                            Value           = $ScopeOption.Value;
                            AddressFamily   = "IPv4";
                            Ensure          = "Present";       
                            #VendorClass     = $ScopeOption.VendorClass;
                            VendorClass     = "";  
                            #UserClass       = $ScopeOption.UserClass;
                            UserClass       = "";
                        } 
                        #$number++
                    
                    }
                #}   
            } # end DHCPScope
        
        <#
        # DNS Zone (behöver definieras för att xDnsRecord kräver en zon)
        xDnsServerAdZone ADintegratedDNSZone {
            Name = $ConfigurationData.LabADDomainConfig.DomainName
            Ensure = "Present"

        }#>

        
        # DNS records
        foreach ($DNSRecord in $ConfigurationData.LabDNSRecords) {
            xDnsRecord $DNSRecord.Target.Replace(".","_") {
                Name        = $DNSRecord.Name;
                Target      = $DNSRecord.Target;
                Type        = $DNSRecord.Type;
                Zone        = $ConfigurationData.LabADDomainConfig.DomainName # samma som domännamnet borde väl vara safe.
            }
        }


 <#         
            xDhcpServerScope 'LabDHCPScope' {
                
                ScopeId       = $ConfigurationData.LabDHCPConfig.ScopeID;
                Name          = $ConfigurationData.LabDHCPConfig.Name;
                IPStartRange  = $ConfigurationData.LabDHCPConfig.IPStartRange;
                IPEndRange    = $ConfigurationData.LabDHCPConfig.IPEndRange;
                SubnetMask    = $ConfigurationData.LabDHCPConfig.SubnetMask;
                LeaseDuration = $ConfigurationData.LabDHCPConfig.LeaseDuration;
                State         = $ConfigurationData.LabDHCPConfig.State;
                AddressFamily = $ConfigurationData.LabDHCPConfig.AddressFamily;
                DependsOn     = '[WindowsFeature]DHCP';
            }
    
            # sätt alla scope options för alla definierade scopes.
            xDhcpScopeOption 'DhcpScopeLabDHCPScopeOption' {
    
                ScopeID            = $ConfigurationData.LabDHCPConfig.ScopeID;
                DnsDomain          = $ConfigurationData.LabDHCPConfig.DnsDomain;
                DnsServerIPAddress = $ConfigurationData.LabDHCPConfig.DnsServerAddress;
                Router             = $ConfigurationData.LabDHCPConfig.Router;
                AddressFamily      = $ConfigurationData.LabDHCPConfig.AddressFamily;
                DependsOn          = '[xDhcpServerScope]LabDHCPScope';
            }
 #>    
            # Detta borde ersättas med nån json-grej
            xADUser User1 {
    
                DomainName  = $node.DomainName;
                UserName    = 'Admin';
                Description = 'Lab Admin';
                Password    = $Credential;
                Ensure      = 'Present';
                DependsOn   = '[xADDomain]ADDomain';
            }

            xADUser User2 {
    
                DomainName  = $node.DomainName;
                UserName    = 'Nicklas';
                Description = 'En normal användare';
                Password    = $Credential;
                Ensure      = 'Present';
                DependsOn   = '[xADDomain]ADDomain';
            }
            xADUser User3 {
    
                DomainName  = $node.DomainName;
                UserName    = 'Martin';
                Description = 'En ond användare';
                Password    = $Credential;
                Ensure      = 'Present';
                DependsOn   = '[xADDomain]ADDomain';
            }
    
            xADGroup DomainAdmins {
    
                GroupName        = 'Domain Admins';
                MembersToInclude = 'Admin';
                DependsOn        = '[xADUser]User1';
            }
    
            xADGroup EnterpriseAdmins {
    
                GroupName        = 'Enterprise Admins';
                GroupScope       = 'Universal';
                MembersToInclude = 'Admin';
                DependsOn        = '[xADUser]User1';
            }
    
        } #end nodes DC
    
        ## om man inte är en DC
        node $AllNodes.Where({$_.Role -notin 'DC'}).NodeName {
    
            ## Flip credential into username@domain.com
            $upn = '{0}@{1}' -f $Credential.UserName, $node.DomainName;
            $domainCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($upn, $Credential.Password);
    
            xComputer 'DomainMembership' {
    
                Name       = $node.NodeName;
                DomainName = $node.DomainName;
                Credential = $domainCredential;
            }
        } #end nodes DomainJoined
    
        node $AllNodes.Where({$_.Role -in 'WSUS'}).NodeName {  
            WindowsFeature WSUS {
                Name = "UpdateServices";
                Ensure = "Present";
            }         
            UpdateServicesServer WSUSInstall {
                
                Ensure     = 'Present'
                ContentDir = "C:\WSUS";
                UpdateImprovementProgram = $false;
              
            }
        }

        # START SCCM CONFIG
        node $Allnodes.Where({$_Role -in 'SCCM'}).NodeName {

            # kolla om Profile är Site Server, i så fall installera SQL
            # sql



        }
    
    } #end Configuration 
    
Lab -ConfigurationData .\Lab.psd1
Copy-Item .\Lab\*.mof C:\Lability\Configurations
