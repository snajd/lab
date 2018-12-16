Configuration WS2019Lab {
    <#
        Requires the following custom DSC resources:
    
            xComputerManagement: https://github.com/PowerShell/xComputerManagement
            xNetworking:         https://github.com/PowerShell/xNetworking
            xActiveDirectory:    https://github.com/PowerShell/xActiveDirectory
            xSmbShare:           https://github.com/PowerShell/xSmbShare
            xDhcpServer:         https://github.com/PowerShell/xDhcpServer
            xDnsServer:          https://github.com/PowerShell/xDnsServer
    #>
        param (
            [Parameter()] [ValidateNotNull()] [PSCredential] $Credential = (Get-Credential -Credential 'Administrator')
        )
        Import-DscResource -Module xComputerManagement, xNetworking, xActiveDirectory;
        Import-DscResource -Module xSmbShare, PSDesiredStateConfiguration;
        Import-DscResource -Module xDHCPServer, xDnsServer;
    
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
    
                xIPAddress 'PrimaryIPAddress' {
    
                    IPAddress      = $node.IPAddress;
                    InterfaceAlias = $node.InterfaceAlias;
                    # PrefixLength   = $node.PrefixLength;
                    AddressFamily  = $node.AddressFamily;
                }
    
                if (-not [System.String]::IsNullOrEmpty($node.DefaultGateway)) {
    
                    xDefaultGatewayAddress 'PrimaryDefaultGateway' {
    
                        InterfaceAlias = $node.InterfaceAlias;
                        Address        = $node.DefaultGateway;
                        AddressFamily  = $node.AddressFamily;
                    }
                }
    
                if (-not [System.String]::IsNullOrEmpty($node.DnsServerAddress)) {
    
                    xDnsServerAddress 'PrimaryDNSClient' {
    
                        Address        = $node.DnsServerAddress;
                        InterfaceAlias = $node.InterfaceAlias;
                        AddressFamily  = $node.AddressFamily;
                    }
                }
    
                if (-not [System.String]::IsNullOrEmpty($node.DnsConnectionSuffix)) {
    
                    xDnsConnectionSuffix 'PrimaryConnectionSuffix' {
    
                        InterfaceAlias           = $node.InterfaceAlias;
                        ConnectionSpecificSuffix = $node.DnsConnectionSuffix;
                    }
                }
    
            } #end if IPAddress
    
            # alla burkar ska svara på ping
            xFirewall 'FPS-ICMP4-ERQ-In' {
    
                Name        = 'FPS-ICMP4-ERQ-In';
                DisplayName = 'File and Printer Sharing (Echo Request - ICMPv4-In)';
                Description = 'Echo request messages are sent as ping requests to other nodes.';
                Direction   = 'Inbound';
                Action      = 'Allow';
                Enabled     = 'True';
                Profile     = 'Any';
            }
    
            xFirewall 'FPS-ICMP6-ERQ-In' {
    
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
            }
    
            xDhcpServerScope 'DhcpScope10_10_0_0' {
                
                ScopeId       = '10.10.0.0' 
                Name          = 'Corpnet';
                IPStartRange  = '10.10.0.150';
                IPEndRange    = '10.10.0.200';
                SubnetMask    = '255.255.255.0';
                LeaseDuration = '00:08:00';
                State         = 'Active';
                AddressFamily = 'IPv4';
                DependsOn     = '[WindowsFeature]DHCP';
            }
    
            xDhcpServerOption 'DhcpScope10_10_0_0_Option' {
    
                ScopeID            = '10.10.0.0';
                DnsDomain          = 'lab.nortonnet.se';
                DnsServerIPAddress = '10.10.0.100';
                Router             = '10.10.0.254';
                AddressFamily      = 'IPv4';
                DependsOn          = '[xDhcpServerScope]DhcpScope10_10_0_0';
            }
    
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
            # ok nu då?
    
    } #end Configuration 
    
WS2019Lab -ConfigurationData C:\GitHub\lab\2019Lab.psd1
