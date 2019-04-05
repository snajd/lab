# Detta ska du inte läsa Jocke.

Det är mina högst privata anteckningar.

Fram till hit har jag bara typ fattat vad psd1 och ps1 gör, samt moddat Example-confen.
Men nu vill jag göra en WSUS.

börjar med att söka efter DSC-moduler för WSUS:
    Find-DscResource *wsus*
    Find-Module -name *wsus* -tag DSC
inga svar.
folk på internet har bara skrivit moduler för att konfa själva WSUS-inställningarna lokalt på maskiner.
men, det går ju att konfa WSUS med commandline.

hur gör man för att köra något custom?
about_CustomResources
[bra exempel](https://github.com/VirtualEngine/Lability/blob/dev/Examples/CustomResource.psd1)
Det är så man får in filer och binärer på sin VM! perfekt för Hydration!

ok, så postcommands kallas bootstrap
about_bootstrap
* en boostrap kan höra ihop med ett media
* default bootstrappas LocalConfiguration Manager
* i ett exempel aktiverar han administratorkontot med net use, men detta är ju inte alls det jag vill 

För att tvinga DSC att köra den laddade konfigurationen en gång till
start-dscconfiguration -UseExisting

Visar objektet och properties
Get-DscResource UpdateServicesServer -Syntax

