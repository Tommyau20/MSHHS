Function Install-ArmTtkModule {
    if(get-module arm-ttk){
        write-host 'Arm TTK is installed'
    }
    else{
        import-module bitstransfer
        Start-BitsTransfer -Source 'https://aka.ms/arm-ttk-latest' -destination "$env:temp\arm-ttk.zip"
        Expand-Archive -Path "$env:temp\arm-ttk.zip" -DestinationPath "~\Documents\PowerShell\Modules\"
        Push-Location "~\Documents\Powershell\Modules\arm-ttk"
        Get-ChildItem *.ps1, *.psd1, *.ps1xml, *.psm1 -Recurse | Unblock-File
        Import-module arm-ttk
        Pop-Location
    }
}