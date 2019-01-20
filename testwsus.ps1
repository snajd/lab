configuration TestWSUS {

    Import-DscResource -ModuleName PsdesiredStateConfiguration
    Import-DscResource -ModuleName UpdateServicesDSC

    node "localhost" {

        UpdateServicesDSC TestWSUS2 {
            Ensure = "Present"
            ContentDir = "C:\testWSUS"
        }
    }
}
TestWSUS