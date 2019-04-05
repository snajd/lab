Configuration TestScriptResource {
    Script TestStartProcess {
        GetScript = {}
        SetScript = {
            $args = ""
            $process = ""
            Start-Process -FilePath $process -ArgumentList $args
        }
        TestScript = {
            return $true
        }

    }
}