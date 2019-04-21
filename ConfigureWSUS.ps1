Configuration ConfigureWSUS {
    import-dscresource -module PSDesiredStateConfiguration
    Import-DscResource -module UpdateServicesDsc
    
    
    node "localhost" {
        # installera WSUSRollen
        WindowsFeature WSUS {
            Ensure = "Present"
            Name = "UpdateServices"
            IncludeAllSubFeature = $true;


        }
    }
}
ConfigureWSUS