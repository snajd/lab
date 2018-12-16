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
            Lability_Media          = '2019_x64_Standard_EN_MSDN';
        }
        @{
            NodeName                = 'RDS01';
            Role                    = 'RDS'
            Lability_ProcessorCount = 2;
            Lability_Media          = '2019_x64_DataCenter_EN_Desktop_MSDN';       
        }
        @{
            NodeName                = 'WSUS01';
            Role                    = 'WSUS'
            Lability_ProcessorCount = 2;
            Lability_Media          = '2019_x64_DataCenter_EN_Desktop_MSDN';       
        }
        @{
            NodeName                = 'CLIENT01';
            Role                    = 'CLIENT'
            Lability_ProcessorCount = 2;
            Lability_Media          = 'WIN10_1809_x64_Enterprise_EN_MSDN';
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
                @{ Name = 'xNetworking'}
                @{ Name = 'xActiveDirectory'}
                @{ Name = 'xDnsServer'}
                @{ Name = 'xDhcpServer'}
                ## The 'GitHub# provider can download modules directly from a GitHub repository, for example:
                ## @{ Name = 'Lability'; Provider = 'GitHub'; Owner = 'VirtualEngine'; Repository = 'Lability'; Branch = 'dev'; }
            );

        } #end Lability
    } #end NonNodeData
}
