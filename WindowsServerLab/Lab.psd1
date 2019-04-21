@{
    AllNodes = @(
        @{
            NodeName                    = '*';
            InterfaceAlias              = 'Ethernet';
            DefaultGateway              = '10.10.0.254';
            PrefixLength                = 24;
            AddressFamily               = 'IPv4';
            DnsServerAddress            = '10.10.0.100';
            DomainName                  = 'lab.nortonnet.se';
            PSDscAllowPlainTextPassword = $true;
            PSDscAllowDomainUser        = $true; # Removes 'It is not recommended to use domain credential for node X' messages
            Lability_SwitchName         = 'INTERNAL';
            Lability_ProcessorCount     = 1;
            Lability_StartupMemory      = 2GB;
            Lability_Media              = '2019_x64_DataCenter_EN_Desktop_MSDN';
}
        @{
            NodeName                = 'DC01';
            Role                    = 'DC'
            Lability_ProcessorCount = 2;
            IPAddress               = '10.10.0.100';
            DnsServerAddress        = '127.0.0.1';
            Lability_Media          = '2019_x64_Standard_EN_Core_Eval';
        }
        @{
            NodeName                = 'RDS01';
            Role                    = 'RDS'
            Lability_ProcessorCount = 2;
            Lability_Media          = '2019_x64_Standard_EN_Eval';       
        }
        @{
            NodeName                = 'WSUS01';
            Role                    = 'WSUS'
            Lability_ProcessorCount = 2;
            Lability_Media          = '2019_x64_Standard_EN_Eval';       
        }
        @{
            NodeName                = 'SRV01';
            Role                    = ''
            Lability_ProcessorCount = 2;
            Lability_Media          = '2019_x64_Standard_EN_Eval';       
        }
        @{
            NodeName                = 'CM01';
            Role                    = 'SCCM'
            Type                    = 'Site Server'
            Lability_ProcessorCount = 4;
            Lability_StartupMemory  = 8GB;
            Lability_Media          = '2019_x64_Standard_EN_Eval';
            # create empty data disk
            Lability_HardDiskDrive  = @(
                @{
                    Generation          =   "VHDX";
                    MaximumSizeBytes    =   127GB;
                }
            )       
        }
        @{
            NodeName                = 'CLIENT01';
            Role                    = 'CLIENT'
            Lability_ProcessorCount = 2;
            Lability_Media          = 'WIN10_x64_Enterprise_EN_Eval';
        }
        @{
            NodeName                = 'CLIENT02';
            Role                    = 'CLIENT'
            Lability_ProcessorCount = 2;
            Lability_Media          = 'WIN10_x64_Enterprise_EN_Eval';
        }
        @{
            NodeName                = 'CLIENT03';
            Role                    = 'CLIENT'
            Lability_ProcessorCount = 2;
            Lability_Media          = 'WIN10_x64_Enterprise_EN_Eval';
        }

    )
    
    # flyttar bort information från konfigurationsscriptet för att göra det enklare att uppdatera.
    LabADDomainConfig = @{
        DomainName = "lab.nortonnet.se"

    }

    # statiska DNS records
    #
    # Finns tå stycken resurstyper i xDnsServer: xDnsRecord och xDnsARecord (denna är flaggad för att komma tas bort i senare release)


    LabDNSRecords = @(
        @{
            Name = "test";
            Target = "10.10.0.123";
            # Zone = behöver inte hårdlödas här
            Type = "ARecord";
        }
        @{
            Name = "test-alias";
            Target = "test.lab.nortonnet.se";
            Type = "CName"
        }
    )


    LabDHCPConfig = @(
        @{
            ScopeId            = "10.10.0.0"
            Name               = "NortonLab LAN"
            IPStartRange       = '10.10.0.150';
            IPEndRange         = '10.10.0.200';
            SubnetMask         = '255.255.255.0';
            # LeaseDuration      = ((New-TimeSpan -Hours 8).ToString());
            LeaseDuration      = "08:00:00"
            State              = 'Active';
            AddressFamily      = 'IPv4';
            DnsDomain          = 'lab.nortonnet.se';
            # DnsServerAddress   = "10.10.0.100"
            # DnsServerIPAddress = '10.10.0.100';
            ScopeOptions = @(
                @{
                    Name          = "DnsServerIPAddress"
                    OptionID      = 6
                    Value         = "10.10.0.100"
                }
                @{
                    Name          = "Router"
                    OptionID      = 3
                    Value         = "10.10.0.1"
                }

            )  
        }
        @{
            ScopeId            = "10.10.1.0"
            Name               = "NortonLab LAN 2"
            IPStartRange       = '10.10.1.150';
            IPEndRange         = '10.10.1.200';
            SubnetMask         = '255.255.255.0';
            LeaseDuration      = "08:00:00"
            State              = 'Active';
            AddressFamily      = 'IPv4';
            DnsDomain          = 'lab.nortonnet.se';
            # DnsServerAddress   = "10.10.1.100"
            # DnsServerIPAddress = '10.10.1.100';
            ScopeOptions = @(
                @{
                    Name          = "DnsServerIPAddress"
                    OptionID      = 6
                    Value         = "10.10.1.100"
                }
                @{
                    Name    	  = "Router"
                    OptionID      = 3
                    Value         = "10.10.1.1"
                }
                @{
                    Name          = "BootServer"
                    OptionID      = 66
                    Value         = "testserver.com"
                }
                @{
                    Name          = "Bootfile"
                    OptionID      = 67
                    Value         = "fil.pxe"
                }
            )
            
        }   
    )
    
    NonNodeData = @{
        Lability = @{
            # se till att man kan köra VBS
            ExposeVirtualizationExtensions = $true;
            EnvironmentPrefix = 'LAB-';
            Network = @(
                @{
                    Name = 'LAB-INTERNAL';
                    Type = 'External';
                }
            ) #end Network
            DSCResource = @(
                ## Download published version from the PowerShell Gallery
                @{ Name = 'xComputerManagement'}
                ## If not specified, the provider defaults to the PSGallery.
                @{ Name = 'xSmbShare'}
                @{ Name = 'NetworkingDsc'}
                @{ Name = 'xActiveDirectory'}
                @{ Name = 'xDnsServer'}
                @{ Name = 'xDhcpServer'}
                @{ Name = 'UpdateServicesDsc'}
                @{ Name = 'SqlServerDsc'}
                ## The 'GitHub# provider can download modules directly from a GitHub repository, for example:
                ## @{ Name = 'Lability'; Provider = 'GitHub'; Owner = 'VirtualEngine'; Repository = 'Lability'; Branch = 'dev'; }
            );

        } #end Lability
    } #end NonNodeData
}
