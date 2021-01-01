<#
.SYNOPSIS
   Find missing software patchs for privilege escalation (windows).

   Author: @_RastaMouse (Deprecated)
   Update: @r00t-3xp10it (v1.3)
   Tested Under: Windows 10 (18363) x64 bits
   Required Dependencies: none
   Optional Dependencies: none
   PS cmdlet Dev version: v1.3

.DESCRIPTION
   Cmdlet to find missing software patchs for privilege escalation (windows).
   This CmdLet continues @_RastaMouse (Deprecated) Module with new 2020 CVE
   entrys and a new function to find missing security KB patches by comparing
   the list of installed patches againts Sherlock KB List entrys ($dATAbASE).
   This Cmdlet also Searchs for 'Unquoted service paths' (EoP vulnerability) and
   recursive search for folders with Everyone:(F) permissions ($Env:PROGRAMFILES)

.NOTES
   CVE's to test
   -------------
   MS10-015, MS10-092, MS13-053, MS13-081
   MS14-058, MS15-051, MS15-078, MS16-016
   MS16-032, MS16-034, MS16-135

   CVE-2017-7199, CVE-2019-1215, CVE-2019-1458
   CVE-2020-005, CVE-2020-0624, CVE-2020-0642
   CVE-2020-1054, CVE-2020-5752, CVE-2020-13162
   CVE-2020-17382
   
.EXAMPLE
   PS C:\> Get-Help .\Sherlock.ps1 -full
   Access This cmdlet Comment_Based_Help

.EXAMPLE
   PS C:\> Import-Module $Env:TMP\Sherlock.ps1 -Force;Get-HotFixs
   Import module, Find missing security KB Id packages (HotFix)

.EXAMPLE
   PS C:\> Import-Module $Env:TMP\Sherlock.ps1 -Force;Get-Rotten
   Import module, Find Rotten Potato vuln privilege settings (EoP)

.EXAMPLE
   PS C:\> Import-Module $Env:TMP\Sherlock.ps1 -Force;Get-Paths
   Import module, Find Unquoted service paths (EoP vulnerability)

.EXAMPLE
   PS C:\> Import-Module $Env:TMP\Sherlock.ps1 -Force;Get-Paths ACL
   Import module, Find Unquoted service paths (EoP vulnerability) and
   search recursive in PROGRAMFILES directorys for folders with
   Everyone:(F) 'FullControl' permissions set.

.EXAMPLE
   PS C:\> Import-Module "$Env:TMP\Sherlock.ps1" -Force;Get-Paths ACL ReadAndExecute
   'ACL' 2º argument accepts the Everyone:(FileSystemRigths) value to search.

.EXAMPLE
   PS C:\> Import-Module "$Env:TMP\Sherlock.ps1" -Force;Get-Paths ACL FullControl BUILTIN\Users
   'ACL' 3º argument accepts the Group (Everyone|BUILTIN\Users|Etc) value to search.

.EXAMPLE
   PS C:\> Import-Module -Name "$Env:TMP\Sherlock.ps1" -Force;Get-RegPaths
   Find Weak Service Registry Permissions Under Everyone Group Name (EoP)

.EXAMPLE
   PS C:\> Import-Module "$Env:TMP\Sherlock.ps1" -Force;Get-RegPaths BUILTIN\Users
   'Get-RegPaths' argument accepts the Group (Everyone|BUILTIN\Users) value.

.EXAMPLE
   PS C:\> Import-Module $Env:TMP\Sherlock.ps1 -Force;Find-AllVulns
   Import module, Scan pre-defined CVE's (EoP) using Sherlock $dATAbASE

.EXAMPLE
   PS C:\> Import-Module -Name "$Env:TMP\Sherlock.ps1" -Force;Get-HotFixs;Find-AllVulns
   Import module, Find missing KB packages and scan for CVE's (EoP) vulnerabilitys.

.INPUTS
   None. You cannot pipe objects into Sherlock.ps1

.OUTPUTS
   Title      : TrackPopupMenu Win32k Null Point Dereference
   MSBulletin : MS14-058
   CVEID      : 2014-4113
   Link       : https://www.exploit-db.com/exploits/35101/
   VulnStatus : Appers Vulnerable

   Title      : Win32k Elevation of Privileges
   MSBulletin : MS13-036
   CVEID      : 2020-0624
   Link       : https://tinyurl.com/ybpz7k6y
   VulnStatus : Not Vulnerable

.LINK
    https://www.exploit-db.com/
    https://github.com/r00t-3xp10it/venom
    http://www.catalog.update.microsoft.com/
    https://packetstormsecurity.com/files/os/windows/
    https://github.com/r00t-3xp10it/venom/tree/master/aux/Sherlock.ps1
    https://github.com/r00t-3xp10it/venom/wiki/Find-missing-software-patchs%5CPaths-for-privilege-escalation-(windows)
#>


## Var declarations
$CveDataBaseId = "21"        ## 21 CVE's entrys available ($dATAbASE)
$CmdletVersion = "v1.3"      ## Sherlock CmdLet develop version number
$CVEdataBase = "01/01/2021"  ## Global $dATAbASE (CVE) last update date
$Global:ExploitTable = $null ## Global Output DataTable
$ProcessArchitecture = $env:PROCESSOR_ARCHITECTURE
$OSVersion = (Get-WmiObject Win32_OperatingSystem).version
$host.UI.RawUI.WindowTitle = "@Sherlock $CmdletVersion {SSA@RedTeam}"

function Sherlock-Banner {

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Sherlock CVE function banner
   #>

   ## Create Data Table for output
   $MajorVersion = [int]$OSVersion.split(".")[0]
   $mytable = New-Object System.Data.DataTable
   $mytable.Columns.Add("ModuleName")|Out-Null
   $mytable.Columns.Add("Entrys")|Out-Null
   $mytable.Columns.Add("OS")|Out-Null
   $mytable.Columns.Add("Arch")|Out-Null
   $mytable.Columns.Add("DataBase")|Out-Null
   $mytable.Rows.Add("Sherlock",
                     "$CveDataBaseId",
                     "W$MajorVersion",
                     "$ProcessArchitecture",
                     "$CVEdataBase")|Out-Null

   ## Display Data Table
   $mytable|Format-Table -AutoSize > $Env:TMP\MyTable.log
   Get-Content -Path "$Env:TMP\MyTable.log"
   Remove-Item -Path "$Env:TMP\MyTable.log" -Force
}

function Get-Paths {
[int]$Count = 0 ## Loop counter

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Find Unquoted service vuln paths (EoP)

   .NOTES
      This function searchs for Unquoted service vuln paths.
      Remark: Its required an 'exe-service' (msfvenom) payload
      to successfuly exploit Unquoted service paths vulnerability.

   .EXAMPLE
      Import-Module -Name "$Env:TMP\Sherlock.ps1" -Force;Get-Paths
      Find Unquoted service vulnerable paths (EoP vulnerability)

   .EXAMPLE
      Import-Module -Name "$Env:TMP\Sherlock.ps1" -Force;Get-Paths ACL
      IF the 'ACL' argument its used in this function, then Sherlock
      also recursive search for folders with Everyone:(F) permissions.

   .EXAMPLE
      Import-Module "$Env:TMP\Sherlock.ps1" -Force;Get-Paths ACL ReadAndExecute
      'ACL' 2º argument accepts the Everyone:(FileSystemRigths) value to search.

   .EXAMPLE
      Import-Module "$Env:TMP\Sherlock.ps1" -Force;Get-Paths ACL FullControl BUILTIN\Users
      'ACL' 3º argument accepts the Group Name (Everyone|BUILTIN\Users|Etc) value to search.
      REMARK: Allways use double quotes if Group Name contains any empty spaces
   #>

   ## Create Data Table for output
   $MajorVersion = [int]$OSVersion.split(".")[0]
   $mytable = New-Object System.Data.DataTable
   $mytable.Columns.Add("ModuleName")|Out-Null
   $mytable.Columns.Add("OS")|Out-Null
   $mytable.Columns.Add("Arch")|Out-Null
   $mytable.Columns.Add("SearchPaths")|Out-Null
   $mytable.Rows.Add("Sherlock",
                     "W$MajorVersion",
                     "$ProcessArchitecture",
                     "Unquoted")|Out-Null

   ## Display Data Table
   $mytable|Format-Table -AutoSize > $Env:TMP\MyTable.log
   Get-Content -Path "$Env:TMP\MyTable.log"
   Remove-Item -Path "$Env:TMP\MyTable.log" -Force


   ## Search for Unquoted service paths (StartMode = Auto)
   gwmi -class Win32_Service -Property Name,DisplayName,PathName,StartMode|Where {
         $_.StartMode -eq "Auto" -and $_.PathName -NotLike "C:\Windows*" -and $_.PathName -NotMatch '"*"'
      }|Select PathName,Name > $Env:TMP\GetPaths.log
   If(Test-Path -Path "$Env:TMP\GetPaths.log" -EA SilentlyContinue){
      Get-Content -Path "$Env:TMP\GetPaths.log"
      Remove-Item -path "$Env:TMP\GetPaths.log" -Force
   }

   $param1 = $args[0] ## User Imput => Trigger ACL tests argument
   $param2 = $args[1] ## User Imput => FileSystemRights (ReadAndExecute)
   $param3 = $args[2] ## User Imput => Group (BUILTIN\Users)
   If($param2 -ieq $null){$param2 = "FullControl"}## Default FileSystemRights value
   If($param3 -ieq $null){$param3 = "Everyone"}## Default FileSystemRights value
   If($param1 -ieq "ACL"){## List folders with Everyone:(F) Permissions (ACL)

      ## Escaping backslash's and quotes because of:
      # NT AUTHORITY\INTERACTIVE empty spaces in User Imputs
      If($param3 -Match '"' -and $param3 -Match '\\'){
         $UserGroup = $param3 -replace '\\','\\' -replace '"',''
      }ElseIf($param3 -Match '\\'){
         $UserGroup = $param3 -replace '\\','\\'
      }ElseIf($param3 -Match '"'){
         $UserGroup = $param3 -replace '"',''
      }Else{## Group Name without backslash's
         $UserGroup = $param3  
      }

      ## Create Data Table for output
      $mytable = New-Object System.Data.DataTable
      $mytable.Columns.Add("ModuleName")|Out-Null
      $mytable.Columns.Add("OS")|Out-Null
      $mytable.Columns.Add("Arch")|Out-Null
      $mytable.Columns.Add("SearchACL")|Out-Null
      $mytable.Columns.Add("Group Name")|Out-Null
      $mytable.Rows.Add("Sherlock",
                        "W$MajorVersion",
                        "$ProcessArchitecture",
                        "$param2",
                        "$param3")|Out-Null

      ## Display Data Table
      $mytable|Format-Table -AutoSize > $Env:TMP\MyTable.log
      Get-Content -Path "$Env:TMP\MyTable.log"
      Remove-Item -Path "$Env:TMP\MyTable.log" -Force

      ## Display available Groups
      $ListGroups = whoami /groups
      echo $ListGroups > $Env:TMP\Groups.log
      Get-Content -Path "$Env:TMP\Groups.log"
      Remove-Item -Path "$Env:TMP\Groups.log" -Force

      Write-Host ""
      ## Directorys to search recursive: $Env:PROGRAMFILES, ${Env:PROGRAMFILES(x86)}, $Env:LOCALAPPDATA\Programs\
      $dAtAbAsEList = Get-ChildItem  -Path "$Env:PROGRAMFILES", "${Env:PROGRAMFILES(x86)}", "$Env:LOCALAPPDATA\Programs\" -Recurse -ErrorAction SilentlyContinue -Force|Where { $_.PSIsContainer }|Select -ExpandProperty FullName
      ForEach($Token in $dAtAbAsEList){## Loop truth Get-ChildItem Itens (Paths)
         If(-not($Token -Match 'WindowsApps')){## Exclude => WindowsApps folder [UnauthorizedAccessException]
            $IsInHerit = (Get-Acl "$Token").Access.IsInherited|Select -First 1
            (Get-Acl "$Token").Access|Where {## Search for Everyone:(F) folder permissions (default)
               $CleanOutput = $_.FileSystemRights -Match "$param2" -and $_.IdentityReference -Match "$UserGroup" ## <-- In my system the IdentityReference is: 'Todos'
               If($CleanOutput){$Count++ ##  Write the Table 'IF' found any vulnerable permissions
                  Write-Host "`nVulnId            : ${Count}::ACL (Mitre T1222)"
                  Write-Host "FolderPath        : $Token" -ForegroundColor Yellow
                  Write-Host "FileSystemRights  : $param2"
                  Write-Host "IdentityReference : $UserGroup"
                  Write-Host "IsInherited       : $IsInHerit"
               }
            }## End of Get-Acl loop
         }## End of Exclude WindowsApps
      }## End of ForEach loop

      Write-Host "`n`nWeak Directorys"
      Write-Host "---------------"
      If(-not($Count -gt 0) -or $Count -ieq $null){## Weak directorys permissions report banner
         Write-Host "None directorys found with '${UserGroup}:($param2)' permissions!" -ForegroundColor Red -BackgroundColor Black
      }Else{
         Write-Host "Found $Count directorys with '${UserGroup}:($param2)' permissions!"  -ForegroundColor Green -BackgroundColor Black
      }

   }## End of List folders Permissions
   Write-Host ""
}

function Get-RegPaths {
[int]$Count = 0 ## Loop counter

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Find Weak Service Registry Permissions (EoP)

   .NOTES
      This function searchs for Weak Registry Permissions.
      https://medium.com/bugbountywriteup/privilege-escalation-in-windows-380bee3a2842

   .EXAMPLE
      Import-Module -Name "$Env:TMP\Sherlock.ps1" -Force;Get-RegPaths
      Find Weak Service Registry Permissions Under Everyone Group Name (EoP)

   .EXAMPLE
      Import-Module "$Env:TMP\Sherlock.ps1" -Force;Get-RegPaths BUILTIN\Users
      'Get-RegPaths' argument accepts the Group Name (Everyone|BUILTIN\Users).
      REMARK: Allways use double quotes if Group Name contains any empty spaces.
   #>

   ## Var declarations
   $UserImput = $args[0]
   If(-not($UserImput)){$UserImput = "Everyone"}
   ## Escaping backslash's and quotes because of:
   # NT AUTHORITY\INTERACTIVE empty spaces in User Imputs
   If($UserImput -Match '"' -and $UserImput -Match '\\'){
      $UserGroup = "$UserImput" -replace '\\','\\' -replace '"',''
   }ElseIf($UserImput -Match '\\'){
      $UserGroup = "$UserImput" -replace '\\','\\'
   }ElseIf($UserImput -Match '"'){
      $UserGroup = "$UserImput" -replace '"',''
   }Else{## Group Name without backslash's
      $UserGroup = "$UserImput"  
   }
   
   ## Create Data Table for output
   $MajorVersion = [int]$OSVersion.split(".")[0]
   $mytable = New-Object System.Data.DataTable
   $mytable.Columns.Add("ModuleName")|Out-Null
   $mytable.Columns.Add("OS")|Out-Null
   $mytable.Columns.Add("Arch")|Out-Null
   $mytable.Columns.Add("SrvRigths")|Out-Null
   $mytable.Columns.Add("Group Name")|Out-Null
   $mytable.Rows.Add("Sherlock",
                     "W$MajorVersion",
                     "$ProcessArchitecture",
                     "FullControl",
                     "$UserGroup")|Out-Null

   ## Display Data Table
   $mytable|Format-Table -AutoSize > $Env:TMP\MyTable.log
   Get-Content -Path "$Env:TMP\MyTable.log"
   Remove-Item -Path "$Env:TMP\MyTable.log" -Force

   ## Display available Groups
   $ListGroups = whoami /groups
   echo $ListGroups > $Env:TMP\Groups.log
   Get-Content -Path "$Env:TMP\Groups.log"
   Remove-Item -Path "$Env:TMP\Groups.log" -Force

   Write-Host "";Start-Sleep -Seconds 2
   ## Get ALL services under HKLM hive key
   $GetPath = (Get-Acl -Path "HKLM:\SYSTEM\CurrentControlSet\services\*" -EA SilentlyContinue).PSPath
   $ParseData = $GetPath -replace 'Microsoft.PowerShell.Core\\Registry::HKEY_LOCAL_MACHINE\\','HKLM:\'
   ForEach($Token in $ParseData){## Loop truth $ParseData services database List
      $IsInHerit = (Get-Acl -Path "$Token").Access.IsInherited|Select -First 1
      $CleanOutput = (Get-Acl -Path "$Token").Access|Where {## Search for Everyone:(F) registry service permissions (default)
         $_.IdentityReference -Match "$UserGroup" -and $_.RegistryRights -Match 'FullControl' -and $_.IsInherited -Match 'False'
      }
      If($CleanOutput){$Count++ ##  Write the Table 'IF' found any vulnerable permissions
         Write-Host "`nVulnId            : ${Count}::SRV"
         Write-Host "RegistryPath      : $Token" -ForegroundColor Yellow
         Write-Host "IdentityReference : $UserGroup"
         Write-Host "RegistryRights    : FullControl"
         Write-Host "AccessControlType : Allow"
         Write-Host "IsInherited       : $IsInHerit"
      }
   }

   Write-Host "`n`nWeak Services Registry Permissions"
   Write-Host "----------------------------------"
   If(-not($Count -gt 0) -or $Count -ieq $null){## Weak directorys permissions report banner
      Write-Host "None registry services found with '${UserGroup}:(FullControl)' permissions!" -ForegroundColor Red -BackgroundColor Black
   }Else{
      Write-Host "Found $Count registry services with '${UserGroup}:(FullControl)' permissions!" -ForegroundColor Green -BackgroundColor Black
   }
   Write-Host ""
}

function Get-Rotten {
[int]$Count = 0 ## Loop counter

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Find Rotten Potato vulnerable settings (EoP)

   .NOTES
      Rotten Potato tests can NOT run under Admin privs

   .EXAMPLE
      Import-Module "$Env:TMP\Sherlock.ps1" -Force;Get-Rotten
   #>

   Write-Host ""
   ## Create Data Table for output
   $MajorVersion = [int]$OSVersion.split(".")[0]
   $mytable = New-Object System.Data.DataTable
   $mytable.Columns.Add("ModuleName")|Out-Null
   $mytable.Columns.Add("OS")|Out-Null
   $mytable.Columns.Add("Arch")|Out-Null
   $mytable.Columns.Add("SearchFor")|Out-Null
   $mytable.Rows.Add("Sherlock",
                     "W$MajorVersion",
                     "$ProcessArchitecture",
                     "RottenPotato")|Out-Null

   ## Display Data Table
   $mytable|Format-Table -AutoSize > $Env:TMP\MyTable.log
   Get-Content -Path "$Env:TMP\MyTable.log"
   Remove-Item -Path "$Env:TMP\MyTable.log" -Force

   ## Make sure we are NOT running tests under Administrator privs
   $IsClientAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -Match "S-1-5-32-544")
   If(-not($IsClientAdmin)){## Running tests Under UserLand Privileges => OK

      $ListPrivsDb = whoami /priv
      ## Display privileges List onscreen
      echo $ListPrivsDb > "$Env:TMP\ListPrivsDb.txt"
      Get-Content -Path "$Env:TMP\ListPrivsDb.txt"
      Remove-Item -Path "$Env:TMP\ListPrivsDb.txt" -Force

      ## Search for vulnerable settings in command output to build LogFile
      # MyLocalVulnTest: whoami /priv|findstr /C:"SeChangeNotifyPrivilege" > $Env:TMP\DCprivs.log
      whoami /priv|findstr /C:"SeImpersonatePrivilege" /C:"SeAssignPrimaryPrivilege" /C:"SeTcbPrivilege" /C:"SeBackupPrivilege" /C:"SeRestorePrivilege" /C:"SeCreateTokenPrivilege" /C:"SeLoadDriverPrivilege" /C:"SeTakeOwnershipPrivilege" /C:"SeDebugPrivileges" > $Env:TMP\DCprivs.log
      $CheckVulnSet = Get-Content -Path "$Env:TMP\DCprivs.log"|findstr /I /C:"Enabled"
      ForEach($Item in $CheckVulnSet){## Id every vulnerable settings found
         $Count++
      }

      Write-Host "`n`nRotten Potato"
      Write-Host "-------------";Start-Sleep -Seconds 1
      If($CheckVulnSet){## Check if there are vulnerable settings to report them
         Write-Host "Found $Count Rotten Potato Vulnerable Setting(s)" -ForegroundColor Green -BackgroundColor Black
         Write-Host "----------------------------- --------------------------------------------- --------"
         Get-Content "$Env:TMP\DCprivs.log"|findstr /I /C:"Enabled";remove-item "$Env:TMP\DCprivs.log" -Force
      }Else{
         Write-Host "None Rotten Potato vulnerable settings found under current system!" -ForegroundColor Red -BackgroundColor Black
      }

   }Else{## Rotten Potato can NOT run under Admin privs
      Write-Host "`n`nRotten Potato"
      Write-Host "-------------";Start-Sleep -Seconds 1
      Write-Host "Rotten Potato tests can NOT run under Administrator privileges!" -ForegroundColor Red -BackgroundColor Black
   }

   ## Clean old LogFiles
   If(Test-Path -Path "$Env:TMP\DCprivs.log"){remove-item "$Env:TMP\DCprivs.log" -Force}
   Write-Host "";Start-Sleep -Seconds 2
}

function Get-HotFixs {
$KBDataEntrys = "null"
[int]$Count = 0 ## Loop counter

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Find missing KB security packages

   .NOTES
      Sherlock KB tests will compare installed KB
      Id patches againts Sherlock $dATAbASE Id list
      Special thanks to @youhacker55 (W7 x64 database)

   .EXAMPLE
      Import-Module -Name "$Env:TMP\Sherlock.ps1" -Force;Get-HotFixs
   #>

   ## Variable declarations
   $MajorVersion = [int]$OSVersion.split(".")[0]
   $CPUArchitecture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture

   ## Number of KB's entrys (db)
   If($MajorVersion -eq "vista"){
      $KBDataEntrys = "16"        ## Credits: @r00t-3xp10it (fully patch)
      $KB_dataBase = "23/12/2020" ## KB entrys database last update date
   }ElseIf($MajorVersion -eq '7' -and $CPUArchitecture -eq "64 bits"){
      $KBDataEntrys = "102"       ## Credits: @youhacker55 (fully patch)
      $KB_dataBase = "25/12/2020" ## KB entrys database last update date
   }ElseIf($MajorVersion -eq '7' -and $CPUArchitecture -eq "32 bits"){
      $KBDataEntrys = "16"        ## <-- TODO: confirm
      $KB_dataBase = "23/12/2020" ## KB entrys database last update date
   }ElseIf($MajorVersion -eq '8'){
      $KBDataEntrys = "null"      ## <-- TODO: confirm
      $KB_dataBase = "23/12/2020" ## KB entrys database last update date
   }ElseIf($MajorVersion -eq '10' -and $CPUArchitecture -eq "64 bits"){
      $KBDataEntrys = "16"        ## Credits: @r00t-3xp10it (fully patch)
      $KB_dataBase = "23/12/2020" ## KB entrys database last update date
   }

   Write-Host ""
   ## Create Data Table for output
   $mytable = New-Object System.Data.DataTable
   $mytable.Columns.Add("ModuleName")|Out-Null
   $mytable.Columns.Add("Entrys")|Out-Null
   $mytable.Columns.Add("OS")|Out-Null
   $mytable.Columns.Add("Arch")|Out-Null
   $mytable.Columns.Add("DataBase")|Out-Null
   $mytable.Rows.Add("Sherlock",
                     "$KBDataEntrys",
                     "W$MajorVersion",
                     "$ProcessArchitecture",
                     "$KB_dataBase")|Out-Null

   ## Display Data Table
   $mytable|Format-Table -AutoSize > $Env:TMP\MyTable.log
   Get-Content -Path "$Env:TMP\MyTable.log"
   Remove-Item -Path "$Env:TMP\MyTable.log" -Force

   ## Generates List of installed HotFixs
   $GetKBId = (Get-HotFix).HotFixID

   ## Sherlock $dATAbASE Lists
   # Supported versions: Windows (vista|7|8|8.1|10)
   If($MajorVersion -eq 10){## Windows 10
      If($CPUArchitecture -eq "64 bits" -or $ProcessArchitecture -eq "AMD64"){
         $dATAbASE = @(## Windows 10 x64 bits
            "KB4552931","KB4497165","KB4515383",
            "KB4516115","KB4517245","KB4521863",#"KB3245007", ## Fake KB entry for debug
            "KB4524569","KB4528759","KB4537759",
            "KB4538674","KB4541338","KB4552152",
            "KB4559309","KB4560959","KB4561600",
            "KB4560960"
         )
      }Else{## Windows 10 x32 bits
         $dATAbASE = "Not supported under W$MajorVersion ($CPUArchitecture) architecture"
         $bypassTest = "True" ## Architecture 'NOT' supported by this test
      }
   }ElseIf($MajorVersion -eq 88){## Windows (8|8.1) x32/x64
      $dATAbASE = @(
         "KB2805222","KB2805227","KB2750149",
         "KB2919355","KB2919442","KB2932046",
         "KB2959977","KB2937592","KB2938439",
         "KB2934018","STOPED-HERE","KB4552152",
         "KB4559309","KB4560959","KB4561600",
         "KB4560960"
      )
   }ElseIf($MajorVersion -eq 7){## Windows 7
      If($CPUArchitecture -eq "64 bits" -or $ProcessArchitecture -eq "AMD64"){
         $dATAbASE = @(## Windows 7 x64 bits (@youhacker55 KB List)
            "KB2479943","KB2491683","KB2506212","KB2560656","KB2564958","KB2579686",
            "KB2585542","KB2604115","KB2620704","KB2621440","KB2631813","KB2653956",
            "KB2654428","KB2656356","KB2667402","KB2685939","KB2690533","KB2698365",
            "KB2705219","KB2706045","KB2727528","KB2729452","KB2736422","KB2742599",
            "KB2758857","KB2770660","KB2789645","KB2807986","KB2813430","KB2840631",
            "KB2847927","KB2861698","KB2862330","KB2862335","KB2864202","KB2868038",
            "KB2871997","KB2884256","KB2893294","KB2894844","KB2900986","KB2911501",
            "KB2931356","KB2937610","KB2943357","KB2968294","KB2972100","KB2972211",
            "KB2973112","KB2973201","KB2977292","KB2978120","KB2978742","KB2984972",
            "KB2991963","KB2992611","KB3004375","KB3010788","KB3011780","KB3019978",
            "KB3021674","KB3023215","KB3030377","KB3031432","KB3035126","KB3037574",
            "KB3045685","KB3046017","KB3046269","KB3055642","KB3059317","KB3060716",
            "KB3067903","KB3071756","KB3072305","KB3074543","KB3075220","KB3086255",
            "KB3092601","KB3093513","KB3097989","KB3101722","KB3108371","KB3108664",
            "KB3109103","KB3109560","KB3110329","KB3115858","KB3122648","KB3124275",
            "KB3126587","KB3127220","KB3138910","KB3139398","KB3139914","KB3150220",
            "KB3155178","KB3156016","KB3159398","KB3161949","KB4474419","KB4054518"
         )
      }Else{
         $dATAbASE = @(## Windows 7 x32 bits
            "KB4033342","KB4078130","KB4074906",
            "KB3186497","KB4020513","KB4020507",
            "KB4020503","KB3216523","KB3196686",
            "KB3083186","KB3074233","KB3074230",
            "KB3037581","KB3035490","KB3023224",
            "KB2979578"
         )
      }
   }ElseIf($MajorVersion -eq "Vista"){
      $dATAbASE = @(## Windows Vista x32/x64 bits
         "KB3033890","KB3045171","KB3046002",
         "KB3050945","KB3051768","KB3055642",
         "KB3057839","KB3059317","KB3061518",
         "KB3063858","KB3065979","KB3067505",
         "KB3067903","KB3069392","KB3070102",
         "KB3072630"
      )
  }Else{
     $dATAbASE = "Not supported under W$MajorVersion ($CPUArchitecture) systems"
     $bypassTest = "True" ## Operative System Flavor 'NOT' supported by this test
  }

   ## Put Installed KB Id patches into an array list
   [System.Collections.ArrayList]$LocalKBLog = $GetKBId
   Write-Host "Id HotFixID   Status     VulnState"
   Write-Host "-- ---------  ---------  ---------"

   ## Compare the two KB Lists
   ForEach($KBkey in $dATAbASE){
      Start-Sleep -Milliseconds 500
      If(-not($LocalKBLog -Match $KBkey)){$Count++
         If($bypassTest -eq "True"){## Operative System OR Arch NOT supported output
            Write-Host "$Count  <$KBkey>" -ForeGroundColor Red -BackGroundColor Black
            Start-Sleep -Milliseconds 200
         }Else{## KB security Patch not found output (not patched)
            Write-Host "$Count  $KBkey  <Missing>  <NotFound>" -ForeGroundColor Red -BackGroundColor Black
            Start-Sleep -Milliseconds 200
         }
      }Else{## KB security Patch found output (patched)
         Write-Host "+  $KBkey  Installed  Patched" -ForeGroundColor Green
      }
   }
   Write-Host ""
}

function Get-FileVersionInfo($FilePath){
    $VersionInfo = (Get-Item $FilePath -EA SilentlyContinue).VersionInfo
    $FileVersion = ( "{0}.{1}.{2}.{3}" -f $VersionInfo.FileMajorPart, $VersionInfo.FileMinorPart, $VersionInfo.FileBuildPart, $VersionInfo.FilePrivatePart )
    return $FileVersion
}

function Get-InstalledSoftware($SoftwareName){
    $SoftwareVersion = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $SoftwareName } | Select-Object Version
    $SoftwareVersion = $SoftwareVersion.Version  # I have no idea what I'm doing
    return $SoftwareVersion
}

function Get-Architecture {
    # This is the CPU architecture.  Returns "64 bits" or "32-bit".
    $CPUArchitecture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
    # This is the process architecture, e.g. are we an x86 process running on a 64-bit system.  Retuns "AMD64" or "x86".
    $ProcessArchitecture = $env:PROCESSOR_ARCHITECTURE
    return $CPUArchitecture, $ProcessArchitecture
}

function Get-CPUCoreCount {
    $CoreCount = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
    return $CoreCount
}

function New-ExploitTable {

    ## Create the table
    $Global:ExploitTable = New-Object System.Data.DataTable

    ## Create the columns
    $Global:ExploitTable.Columns.Add("Title")
    $Global:ExploitTable.Columns.Add("MSBulletin")
    $Global:ExploitTable.Columns.Add("CVEID")
    $Global:ExploitTable.Columns.Add("Link")
    $Global:ExploitTable.Columns.Add("VulnStatus")

    ## Exploit MS10
    $Global:ExploitTable.Rows.Add("User Mode to Ring (KiTrap0D)","MS10-015","2010-0232","https://www.exploit-db.com/exploits/11199/")
    $Global:ExploitTable.Rows.Add("Task Scheduler .XML","MS10-092","2010-3338, 2010-3888","https://www.exploit-db.com/exploits/19930/")
    ## Exploit MS13
    $Global:ExploitTable.Rows.Add("NTUserMessageCall Win32k Kernel Pool Overflow","MS13-053","2013-1300","https://www.exploit-db.com/exploits/33213/")
    $Global:ExploitTable.Rows.Add("TrackPopupMenuEx Win32k NULL Page","MS13-081","2013-3881","https://www.exploit-db.com/exploits/31576/")
    ## Exploit MS14
    $Global:ExploitTable.Rows.Add("TrackPopupMenu Win32k Null Pointer Dereference","MS14-058","2014-4113","https://www.exploit-db.com/exploits/35101/")
    ## Exploit MS15
    $Global:ExploitTable.Rows.Add("ClientCopyImage Win32k","MS15-051","2015-1701, 2015-2433","https://www.exploit-db.com/exploits/37367/")
    $Global:ExploitTable.Rows.Add("Font Driver Buffer Overflow","MS15-078","2015-2426, 2015-2433","https://www.exploit-db.com/exploits/38222/")
    ## Exploit MS16
    $Global:ExploitTable.Rows.Add("'mrxdav.sys' WebDAV","MS16-016","2016-0051","https://www.exploit-db.com/exploits/40085/")
    $Global:ExploitTable.Rows.Add("Secondary Logon Handle","MS16-032","2016-0099","https://www.exploit-db.com/exploits/39719/")
    $Global:ExploitTable.Rows.Add("Windows Kernel-Mode Drivers EoP","MS16-034","2016-0093/94/95/96","https://github.com/SecWiki/windows-kernel-exploits/tree/master/MS16-034?")
    $Global:ExploitTable.Rows.Add("Win32k Elevation of Privilege","MS16-135","2016-7255","https://github.com/FuzzySecurity/PSKernel-Primitives/tree/master/Sample-Exploits/MS16-135")
    ## Miscs that aren't MS
    $Global:ExploitTable.Rows.Add("Nessus Agent 6.6.2 - 6.10.3","N/A","2017-7199","https://aspe1337.blogspot.co.uk/2017/04/writeup-of-cve-2017-7199.html")

    ## r00t-3xp10it update (v1.3)
    $Global:ExploitTable.Rows.Add("ws2ifsl.sys Use After Free Elevation of Privileges","N/A","2019-1215","https://www.exploit-db.com/exploits/47935")
    $Global:ExploitTable.Rows.Add("Win32k Uninitialized Variable Elevation of Privileges","N/A","2019-1458","https://packetstormsecurity.com/files/159569/Microsoft-Windows-Uninitialized-Variable-Local-Privilege-Escalation.html")
    $Global:ExploitTable.Rows.Add("checkmk Local Elevation of Privileges","N/A","2020-005","https://tinyurl.com/ycrgjxec")
    $Global:ExploitTable.Rows.Add("Win32k Elevation of Privileges","MS13-036","2020-0624","https://tinyurl.com/ybpz7k6y")
    $Global:ExploitTable.Rows.Add("Win32k Elevation of Privileges","N/A","2020-0642","https://packetstormsecurity.com/files/158729/Microsoft-Windows-Win32k-Privilege-Escalation.html")
    $Global:ExploitTable.Rows.Add("DrawIconEx Win32k Elevation of Privileges","N/A","2020-1054","https://packetstormsecurity.com/files/160515/Microsoft-Windows-DrawIconEx-Local-Privilege-Escalation.html")
    $Global:ExploitTable.Rows.Add("Druva inSync Local Elevation of Privileges","N/A","2020-5752","https://packetstormsecurity.com/files/160404/Druva-inSync-Windows-Client-6.6.3-Privilege-Escalation.html")
    $Global:ExploitTable.Rows.Add("Pulse Secure Client Local Elevation of Privileges","N/A","2020-13162","https://packetstormsecurity.com/files/158117/Pulse-Secure-Client-For-Windows-Local-Privilege-Escalation.html")
    $Global:ExploitTable.Rows.Add("MSI Ambient Link Driver Elevation of Privileges","N/A","2020-17382","https://www.exploit-db.com/exploits/48836")
}

function Set-ExploitTable ($MSBulletin, $VulnStatus){
    If($MSBulletin -like "MS*"){
        $Global:ExploitTable|Where-Object { $_.MSBulletin -eq $MSBulletin
        } | ForEach-Object {
            $_.VulnStatus = $VulnStatus
        }

    }Else{

        $Global:ExploitTable|Where-Object { $_.CVEID -eq $MSBulletin
        } | ForEach-Object {
            $_.VulnStatus = $VulnStatus
        }
    }
}

function Get-Results {
    Write-Host ""
    Sherlock-Banner
    $Global:ExploitTable
}

function Find-AllVulns {

   <#
   .SYNOPSIS
      Scan's for CVE's (EoP) using Sherlock $dATAbASE

   .NOTES
      Sherlock Currently looks for:
      MS10-015, MS10-092, MS13-053, MS13-081
      MS14-058, MS15-051, MS15-078, MS16-016
      MS16-032, MS16-034, MS16-135

      CVE-2017-7199, CVE-2019-1215, CVE-2019-1458
      CVE-2020-005, CVE-2020-0624, CVE-2020-0642
      CVE-2020-1054, CVE-2020-5752, CVE-2020-13162
      CVE-2020-17382

   .EXAMPLE
      Import-Module -Name "$Env:TMP\Sherlock.ps1" -Force;Find-AllVulns
   #>

    If(-not($Global:ExploitTable)){
        $null = New-ExploitTable
    }

        Find-MS10015
        Find-MS10092
        Find-MS13053
        Find-MS13081
        Find-MS14058
        Find-MS15051
        Find-MS15078
        Find-MS16016
        Find-MS16032
        Find-MS16034
        Find-MS16135
        Find-CVE20177199
        ## version 1.3 update
        Find-CVE20191215
        Find-CVE20191458
        Find-CVE20200624
        Find-CVE20200642
        Find-CVE20201054
        Find-CVE20205752
        Find-CVE202013162
        Find-CVE202017382
        Find-CVE2020005

        Get-Results
}


function Find-MS10015 {

    $MSBulletin = "MS10-015"
    $Architecture = Get-Architecture
    If($Architecture[0] -eq "64 bits"){
        $VulnStatus = "Not supported on 64 bits systems"
    }Else{
        $Path = $env:windir + "\system32\ntoskrnl.exe"
        $VersionInfo = (Get-Item $Path -EA SilentlyContinue).VersionInfo.ProductVersion
        $VersionInfo = $VersionInfo.Split(".")
        $Build = $VersionInfo[2]
        $Revision = $VersionInfo[3].Split(" ")[0]
        switch($Build){
            7600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "20591" ] }
            default { $VulnStatus = "Not Vulnerable" }
        }
    }
    Set-ExploitTable $MSBulletin $VulnStatus
}

function Find-MS10092 {

    $MSBulletin = "MS10-092"
    $Architecture = Get-Architecture
    If($Architecture[1] -eq "AMD64" -or $Architecture[0] -eq "32-bit"){
        $Path = $env:windir + "\system32\schedsvc.dll"
    }ElseIf($Architecture[0] -eq "64 bits" -and $Architecture[1] -eq "x86"){
        $Path = $env:windir + "\sysnative\schedsvc.dll"
    }

        $VersionInfo = (Get-Item $Path -EA SilentlyContinue).VersionInfo.ProductVersion
        $VersionInfo = $VersionInfo.Split(".")
        $Build = $VersionInfo[2]
        $Revision = $VersionInfo[3].Split(" ")[0]

        switch($Build){
            7600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "20830" ] }
            default { $VulnStatus = "Not Vulnerable" }
        }
    Set-ExploitTable $MSBulletin $VulnStatus
}

function Find-MS13053 {

    $MSBulletin = "MS13-053"
    $Architecture = Get-Architecture
    If($Architecture[0] -eq "64 bits"){
        $VulnStatus = "Not supported on 64 bits systems"
    }Else{
        $Path = $env:windir + "\system32\win32k.sys"
        $VersionInfo = (Get-Item $Path -EA SilentlyContinue).VersionInfo.ProductVersion
        $VersionInfo = $VersionInfo.Split(".")

        $Build = $VersionInfo[2]
        $Revision = $VersionInfo[3].Split(" ")[0]

        switch($Build){
            7600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -ge "17000" ] }
            7601 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "22348" ] }
            9200 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "20732" ] }
            default { $VulnStatus = "Not Vulnerable" }
        }
    }
    Set-ExploitTable $MSBulletin $VulnStatus
}

function Find-MS13081 {

    $MSBulletin = "MS13-081"
    $Architecture = Get-Architecture
    If($Architecture[0] -eq "64 bits"){
        $VulnStatus = "Not supported on 64 bits systems"
    }Else{

        $Path = $env:windir + "\system32\win32k.sys"
        $VersionInfo = (Get-Item $Path -EA SilentlyContinue).VersionInfo.ProductVersion
        $VersionInfo = $VersionInfo.Split(".")

        $Build = $VersionInfo[2]
        $Revision = $VersionInfo[3].Split(" ")[0]

        switch($Build){
            7600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -ge "18000" ] }
            7601 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "22435" ] }
            9200 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "20807" ] }
            default { $VulnStatus = "Not Vulnerable" }
        }
    }
    Set-ExploitTable $MSBulletin $VulnStatus
}

function Find-MS14058 {

    $MSBulletin = "MS14-058"
    $Architecture = Get-Architecture
    If($Architecture[1] -eq "AMD64" -or $Architecture[0] -eq "32-bit"){
        $Path = $env:windir + "\system32\win32k.sys"
    }ElseIf($Architecture[0] -eq "64 bits" -and $Architecture[1] -eq "x86"){
        $Path = $env:windir + "\sysnative\win32k.sys"
    }

        $VersionInfo = (Get-Item $Path -EA SilentlyContinue).VersionInfo.ProductVersion
        $VersionInfo = $VersionInfo.Split(".")

        $Build = $VersionInfo[2]
        $Revision = $VersionInfo[3].Split(" ")[0]

        switch($Build){
            7600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -ge "18000" ] }
            7601 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "22823" ] }
            9200 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "21247" ] }
            9600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "17353" ] }
            default { $VulnStatus = "Not Vulnerable" }
        }
    Set-ExploitTable $MSBulletin $VulnStatus
}

function Find-MS15051 {

    $MSBulletin = "MS15-051"
    $Architecture = Get-Architecture
    If($Architecture[1] -eq "AMD64" -or $Architecture[0] -eq "32-bit"){
        $Path = $env:windir + "\system32\win32k.sys"
    }ElseIf($Architecture[0] -eq "64 bits" -and $Architecture[1] -eq "x86"){
        $Path = $env:windir + "\sysnative\win32k.sys"
    }

        $VersionInfo = (Get-Item $Path -EA SilentlyContinue).VersionInfo.ProductVersion
        $VersionInfo = $VersionInfo.Split(".")

        $Build = $VersionInfo[2]
        $Revision = $VersionInfo[3].Split(" ")[0]

        switch($Build){
            7600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "18000" ] }
            7601 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "22823" ] }
            9200 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "21247" ] }
            9600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "17353" ] }
            default { $VulnStatus = "Not Vulnerable" }
        }
    Set-ExploitTable $MSBulletin $VulnStatus
}

function Find-MS15078 {

    $MSBulletin = "MS15-078"
    $Path = $env:windir + "\system32\atmfd.dll"
    If(Test-Path -Path "$Path" -EA SilentlyContinue){## Fucking error
       $VersionInfo = (Get-Item $Path -EA SilentlyContinue).VersionInfo.ProductVersion
       $VersionInfo = $VersionInfo.Split(" ")
       $Revision = $VersionInfo[2]
    }Else{
      $VulnStatus = "Not Vulnerable (not found)"
    }

    switch($Revision){
        243 { $VulnStatus = "Appears Vulnerable" }
        default { $VulnStatus = "Not Vulnerable" }
    }
    Set-ExploitTable $MSBulletin $VulnStatus
}

function Find-MS16016 {

    $MSBulletin = "MS16-016"
    $Architecture = Get-Architecture
    If($Architecture[0] -eq "64 bits"){
        $VulnStatus = "Not supported on 64 bits systems"
    }Else{

        $Path = $env:windir + "\system32\drivers\mrxdav.sys"
        $VersionInfo = (Get-Item $Path -EA SilentlyContinue).VersionInfo.ProductVersion
        $VersionInfo = $VersionInfo.Split(".")

        $Build = $VersionInfo[2]
        $Revision = $VersionInfo[3].Split(" ")[0]

        switch($Build){
            7600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "16000" ] }
            7601 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "23317" ] }
            9200 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "21738" ] }
            9600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "18189" ] }
            10240 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "16683" ] }
            10586 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le "103" ] }
            default { $VulnStatus = "Not Vulnerable" }
        }
    }
    Set-ExploitTable $MSBulletin $VulnStatus
}

function Find-MS16032 {

    $MSBulletin = "MS16-032"
    $CPUCount = Get-CPUCoreCount

    If($CPUCount -eq "1"){
        $VulnStatus = "Not Supported on single-core systems"
    }Else{
    
        $Architecture = Get-Architecture
        If($Architecture[1] -eq "AMD64" -or $Architecture[0] -eq "32-bit"){
            $Path = $env:windir + "\system32\seclogon.dll"
        }ElseIf($Architecture[0] -eq "64 bits" -and $Architecture[1] -eq "x86"){
            $Path = $env:windir + "\sysnative\seclogon.dll"
        } 

            $VersionInfo = (Get-Item $Path -EA SilentlyContinue).VersionInfo.ProductVersion
            $VersionInfo = $VersionInfo.Split(".")

            $Build = [int]$VersionInfo[2]
            $Revision = [int]$VersionInfo[3].Split(" ")[0]

            switch($Build){
                6002 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revison -lt 19598 -Or ( $Revision -ge 23000 -And $Revision -le 23909 ) ] }
                7600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le 19148 ] }
                7601 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 19148 -Or ( $Revision -ge 23000 -And $Revision -le 23347 ) ] }
                9200 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revison -lt 17649 -Or ( $Revision -ge 21000 -And $Revision -le 21767 ) ] }
                9600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revison -lt 18230 ] }
                10240 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 16724 ] }
                10586 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le 161 ] }
                default { $VulnStatus = "Not Vulnerable" }
            }
    }
    Set-ExploitTable $MSBulletin $VulnStatus
}

function Find-MS16034 {

    $MSBulletin = "MS16-034"
    $Architecture = Get-Architecture
    If($Architecture[1] -eq "AMD64" -or $Architecture[0] -eq "32-bit"){
        $Path = $env:windir + "\system32\win32k.sys"
    }ElseIf($Architecture[0] -eq "64 bits" -and $Architecture[1] -eq "x86"){
        $Path = $env:windir + "\sysnative\win32k.sys"
    } 

    $VersionInfo = (Get-Item $Path -EA SilentlyContinue).VersionInfo.ProductVersion
    $VersionInfo = $VersionInfo.Split(".")

    $Build = [int]$VersionInfo[2]
    $Revision = [int]$VersionInfo[3].Split(" ")[0]

    switch($Build){
        6002 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revison -lt 19597 -Or $Revision -lt 23908 ] }
        7601 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 19145 -Or $Revision -lt 23346 ] }
        9200 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revison -lt 17647 -Or $Revision -lt 21766 ] }
        9600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revison -lt 18228 ] }
        default { $VulnStatus = "Not Vulnerable" }
    }
    Set-ExploitTable $MSBulletin $VulnStatus
}

function Find-CVE20177199 {

    $CVEID = "2017-7199"
    $SoftwareVersion = Get-InstalledSoftware "Nessus Agent"
    If(-not($SoftwareVersion)){
        $VulnStatus = "Not Vulnerable"
    }Else{

        $SoftwareVersion = $SoftwareVersion.Split(".")
        $Major = [int]$SoftwareVersion[0]
        $Minor = [int]$SoftwareVersion[1]
        $Build = [int]$SoftwareVersion[2]

        switch($Major){
        6 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Minor -eq 10 -and $Build -le 3 -Or ( $Minor -eq 6 -and $Build -le 2 ) -Or ( $Minor -le 9 -and $Minor -ge 7 ) ] } # 6.6.2 - 6.10.3
        default { $VulnStatus = "Not Vulnerable" }
        }
    }
    Set-ExploitTable $CVEID $VulnStatus
}

function Find-MS16135 {

    $MSBulletin = "MS16-135"
    $Architecture = Get-Architecture
    If($Architecture[1] -eq "AMD64" -or $Architecture[0] -eq "32-bit"){
        $Path = $env:windir + "\system32\win32k.sys"
    }ElseIf($Architecture[0] -eq "64 bits" -and $Architecture[1] -eq "x86"){
        $Path = $env:windir + "\sysnative\win32k.sys"
    }

        $VersionInfo = (Get-Item $Path -EA SilentlyContinue).VersionInfo.ProductVersion
        $VersionInfo = $VersionInfo.Split(".")
        
        $Build = [int]$VersionInfo[2]
        $Revision = [int]$VersionInfo[3].Split(" ")[0]

        switch($Build){
            7601 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 23584 ] }
            9600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le 18524 ] }
            10240 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le 16384 ] }
            10586 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le 19 ] }
            14393 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le 446 ] }
            default { $VulnStatus = "Not Vulnerable" }
        }
    Set-ExploitTable $MSBulletin $VulnStatus
}


# -------------------------------------------------------------------------------------------------------

   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Sherlock version v1.3 update

   .DESCRIPTION
      The next functions are related to new 2020 EOP CVE's

   .LINK
      https://www.exploit-db.com/
      https://0day.today/platforms/windows
      https://packetstormsecurity.com/files/os/windows/
   #>

# -------------------------------------------------------------------------------------------------------


function Find-CVE2020005 {

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Checkmk Local Privilege Escalation

   .DESCRIPTION
      CVE: 2020-005
      MSBulletin: N/A
      Affected systems:
         Windows 10 (1901) x64 - 1.6.0p16
   #>

    $MSBulletin = "N/A"
    $CVEID = "2020-005"
    $Architecture = Get-Architecture
    $ArchBuildBits = $Architecture[0]
    $FilePath = ${Env:PROGRAMFILES(X86)} + "\checkmk\service\Check_mk_agent.exe"

    ## Check for OS affected version/arch (Windows 10 x64 bits)
    $MajorVersion = [int]$OSVersion.split(".")[0]
    If(-not($MajorVersion -eq 10) -and $Architecture[0] -ne "64 bits"){
        $VulnStatus = "Not supported on Windows $MajorVersion ($ArchBuildBits) systems"
    }Else{
       
       $SoftwareVersion = (Get-Item "$FilePath" -EA SilentlyContinue).VersionInfo.ProductVersion
       If(-not($SoftwareVersion)){## Check_mk_agent.exe appl not found
           $VulnStatus = "Not Vulnerable"
       }Else{

          ## Affected: =< 1.6.0p16 (Windows 10 x64 bits)
          $Major = [int]$SoftwareVersion.Split(".")[1]
          $Revision = $SoftwareVersion.Split(".")[2]

           switch($Major){
           6 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le '0p16' ] }
           default { $VulnStatus = "Not Vulnerable" }
           }
       }
    }
    Set-ExploitTable $CVEID $VulnStatus
}

function Find-CVE20191215 {

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      ws2ifsl.sys Use After Free Local Privilege Escalation

   .DESCRIPTION
      CVE: 2019-1215
      MSBulletin: N/A
      Affected systems:
         Windows 10 (1901) x64 - 10.0.18362.295
   #>

    $MSBulletin = "N/A"
    $CVEID = "2019-1215"
    $Architecture = Get-Architecture
    $ArchBuildBits = $Architecture[0]
    $FilePath = $Env:WINDIR + "\System32\ntoskrnl.exe"

    ## Check for OS affected version/arch (Windows 10 x64 bits)
    $MajorVersion = [int]$OSVersion.split(".")[0]
    If(-not($MajorVersion -eq 10) -and $Architecture[0] -ne "64 bits"){
        $VulnStatus = "Not supported on Windows $MajorVersion ($ArchBuildBits) systems"
    }Else{
       
       $SoftwareVersion = (Get-Item "$FilePath" -EA SilentlyContinue).VersionInfo.ProductVersion
       If(-not($SoftwareVersion)){## ntoskrnl.exe appl not found
           $VulnStatus = "Not Vulnerable"
       }Else{

          ## Affected: =< 10.0.18362.295 (Windows 10 x64 bits)
          $Major = [int]$SoftwareVersion.Split(".")[2]
          $Revision = [int]$SoftwareVersion.Split(".")[3]

           switch($Major){
           18362 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le 295 ] }
           default { $VulnStatus = "Not Vulnerable" }
           }
       }
    }
    Set-ExploitTable $CVEID $VulnStatus
}

function Find-CVE20191458 {

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Win32k Uninitialized Variable Elevation of Privileges

   .DESCRIPTION
      CVE: 2019-1458
      MSBulletin: N/A
      Affected systems:
         Windows 7 and Windows Server 2008 R2   - 6.1.7601.24540
         Windows 8.1 and Windows Server 2012 R2 - 6.3.9600.19574
         Windows 10 v1507                       - 10.0.10240.18427
         Windows 10 v1511                       - 10.0.10586.99999
         Windows 10 v1607                       - 10.0.14393.3383
   #>

    $MSBulletin = "N/A"
    $CVEID = "2019-1458"
    $Architecture = Get-Architecture
    $ArchBuildBits = $Architecture[0]
    $FilePath = $Env:WINDIR + "\System32\Win32k.sys"

    ## Check for OS affected version/arch (Windows 10 x64)
    $MajorVersion = [int]$OSVersion.split(".")[0]
    If(-not($MajorVersion -eq 7 -or $MajorVersion -eq 8 -or $MajorVersion -eq 10) -and $Architecture[0] -ne "64 bits"){
        $VulnStatus = "Not supported on Windows $MajorVersion ($ArchBuildBits) systems"
    }Else{
       
       $SoftwareVersion = (Get-Item "$FilePath" -EA SilentlyContinue).VersionInfo.ProductVersion
       If(-not($SoftwareVersion)){## Win32k appl not found
           $VulnStatus = "Not Vulnerable"
       }Else{

          ## Affected: < 10.0.14393.3383 (Windows 10)
          $Major = [int]$SoftwareVersion.Split(".")[2]
          $Revision = [int]$SoftwareVersion.Split(".")[3]

           switch($Major){
           7601 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 24540 ] }
           9600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 19574 ] }
           10240 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 18427 ] }
           10586 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 99999 ] }
           14393 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 3383 ] }
           default { $VulnStatus = "Not Vulnerable" }
           }
       }
    }
    Set-ExploitTable $CVEID $VulnStatus
}

function Find-CVE20200624 {

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Win32k.sys Local Privilege Escalation

   .DESCRIPTION
      CVE: 2020-0624
      MSBulletin: MS13-036
      Affected systems:
         Windows 10 (1903)
         Windows 10 (1909)
         Windows Server Version 1909 (Core)
   #>

    $CVEID = "2020-0624"
    $MSBulletin = "MS13-036"
    $FilePath = $Env:WINDIR + "\System32\Win32k.sys"

    ## Check for OS affected version (Windows 10)
    $MajorVersion = [int]$OSVersion.split(".")[0]
    If($MajorVersion -ne 10){## Affected version number (Windows)
        $VulnStatus = "Not supported on Windows $MajorVersion systems"
    }Else{

       $SoftwareVersion = (Get-Item "$FilePath" -EA SilentlyContinue).VersionInfo.ProductVersion
       If(-not($SoftwareVersion)){## Win32k.sys driver not found
           $VulnStatus = "Not Vulnerable"
       }Else{

          $Major = [int]$SoftwareVersion.split(".")[2]
          $Revision = [int]$SoftwareVersion.Split(".")[3]

           switch($Major){
           18362 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 900 ] }
           default { $VulnStatus = "Not Vulnerable" }
           }
       }
    }
    Set-ExploitTable $CVEID $VulnStatus
}

function Find-CVE20200642 {

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Win32k.sys Local Privilege Escalation

   .DESCRIPTION
      CVE: 2020-0642
      MSBulletin: N/A
      Affected systems:
         Windows 10 (1909)
         Windows Server Version 1909 (Core)
   #>

    $CVEID = "2020-0642"
    $MSBulletin = "N/A"
    $FilePath = $Env:WINDIR + "\System32\Win32k.sys"

    ## Check for OS affected version (Windows Server|10)
    $MajorVersion = [int]$OSVersion.split(".")[0]
    If($MajorVersion -ne 10){## Affected version number (Windows)
        $VulnStatus = "Not supported on Windows $MajorVersion systems"
    }Else{

       $SoftwareVersion = (Get-Item "$FilePath" -EA SilentlyContinue).VersionInfo.ProductVersion
       If(-not($SoftwareVersion)){## Win32k.sys driver not found
           $VulnStatus = "Not Vulnerable"
       }Else{

          ## Vuln: =< 5.1.2600.1330
          $Major = [int]$SoftwareVersion.split(".")[2]
          $Revision = [int]$SoftwareVersion.Split(".")[3]

           switch($Major){
           2600 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le 1329 ] }
           default { $VulnStatus = "Not Vulnerable" }
           }
       }
    }
    Set-ExploitTable $CVEID $VulnStatus
}



function Find-CVE20201054 {

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      DrawIconEx Win32k.sys Local Privilege Escalation

   .DESCRIPTION
      CVE: 2020-1054
      MSBulletin: N/A
      Affected systems:
         Windows 7 SP1
   #>

    $CVEID = "2020-1054"
    $MSBulletin = "N/A"
    $FilePath = $Env:WINDIR + "\System32\Win32k.sys"

    ## Check for OS affected version (Windows 7 SP1)
    $MajorVersion = [int]$OSVersion.split(".")[0]
    If($MajorVersion -ne 7){## Affected version number (Windows)
        $VulnStatus = "Not supported on Windows $MajorVersion systems"
    }Else{

       $SoftwareVersion = (Get-Item "$FilePath" -EA SilentlyContinue).VersionInfo.ProductVersion
       If(-not($SoftwareVersion)){## Win32k.sys driver not found
           $VulnStatus = "Not Vulnerable"
       }Else{

          ## Affected: 6.1.7601.24553 (SP1) | 6.1.7601.24542
          $Major = [int]$SoftwareVersion.split(".")[2]
          $Revision = [int]$SoftwareVersion.Split(".")[3]

           switch($Major){
           7601 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le 24553 ] } # Windows 7 SP1
           default { $VulnStatus = "Not Vulnerable" }
           }
       }
    }
    Set-ExploitTable $CVEID $VulnStatus
}

function Find-CVE20205752 {

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Druva inSync Local Privilege Escalation

   .DESCRIPTION
      CVE: 2020-5752
      MSBulletin: N/A
      Affected systems:
         Windows 10 (x64)
   #>

    $MSBulletin = "N/A"
    $CVEID = "2020-5752"
    $Architecture = Get-Architecture
    $ArchBuildBits = $Architecture[0]

    ## Check for OS affected version/arch (Windows 10 x64)
    $MajorVersion = [int]$OSVersion.split(".")[0]
    If(-not($MajorVersion -eq 10 -and $Architecture[0] -eq "64 bits")){
        $VulnStatus = "Not supported on Windows $MajorVersion ($ArchBuildBits) systems"
    }Else{

       ## Find druva.exe absoluct install path
       # Default Path: ${Env:PROGRAMFILES(x86)}\Druva\inSync4\druva.exe
       $SearchFilePath = (Get-ChildItem -Path ${Env:PROGRAMFILES(x86)}\Druva\, $Env:PROGRAMFILES\Druva\, $Env:LOCALAPPDATA\Programs\Druva\ -Filter druva.exe -Recurse -ErrorAction SilentlyContinue -Force).fullname
       If(-not($SearchFilepath)){## Add value to $FilePath or else 'Get-Item' pops up an error if $null
          $FilePath = ${Env:PROGRAMFILES(x86)} + "\Druva\inSync4\druva.exe"
       }Else{
          $FilePath = $SearchFilePath[0]
       }
       
       $SoftwareVersion = (Get-Item "$FilePath" -EA SilentlyContinue).VersionInfo.ProductVersion
       If(-not($SoftwareVersion)){## druva.exe appl not found
           $VulnStatus = "Not Vulnerable"
       }Else{

          ## Affected: < 6.6.3 (Windows 10 x64)
          $Major = [int]$SoftwareVersion.split(".")[1]
          $Revision = [int]$SoftwareVersion.Split(".")[2]

           switch($Major){
           6 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 3 ] }
           default { $VulnStatus = "Not Vulnerable" }
           }
       }
    }
    Set-ExploitTable $CVEID $VulnStatus
}

function Find-CVE202013162 {

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      Pulse Secure Client Local Elevation of Privileges

   .DESCRIPTION
      CVE: 2020-13162
      MSBulletin: N/A
      Affected systems:
         windows 8.1
         Windows 10 (1909)
   #>

    $MSBulletin = "N/A"
    $CVEID = "2020-13162"
    $Architecture = Get-Architecture
    $ArchBuildBits = $Architecture[0]

    ## Check for OS affected version/arch
    $MajorVersion = [int]$OSVersion.split(".")[0]
    If(-not($MajorVersion -eq 8 -or $MajorVersion -eq 10)){
        $VulnStatus = "Not supported on Windows $MajorVersion systems"
    }Else{

       ## Find PulseSecureService.exe absoluct install path
       # Default Path: ${Env:PROGRAMFILES(x86)}\Common Files\Pulse Secure\JUNS\PulseSecureService.exe
       $SearchFilePath = (Get-ChildItem -Path "${Env:PROGRAMFILES(x86)}\Common Files\", "$Env:PROGRAMFILES\Common Files\", "$Env:LOCALAPPDATA\Programs\Common Files\" -Filter PulseSecureService.exe -Recurse -ErrorAction SilentlyContinue -Force).fullname
       If(-not($SearchFilepath)){## Add value to $FilePath or else 'Get-Item' pops up an error if $null
          $FilePath = ${Env:PROGRAMFILES(x86)} + "\Common Files\Pulse Secure\JUNS\PulseSecureService.exe"
       }Else{
          $FilePath = $SearchFilePath
       }
       
       $SoftwareVersion = (Get-Item "$FilePath" -EA SilentlyContinue).VersionInfo.ProductVersion
       If(-not($SoftwareVersion)){## PulseSecureService.exe appl not found
           $VulnStatus = "Not Vulnerable"
       }Else{

          ## Affected: < 9.1.6 (Windows 8|10)
          $Major = [int]$SoftwareVersion.split(",")[1]
          $Revision = [int]$SoftwareVersion.Split(",")[2]

           switch($Major){
           1 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -lt 6 ] }
           default { $VulnStatus = "Not Vulnerable" }
           }
       }
    }
    Set-ExploitTable $CVEID $VulnStatus
}

function Find-CVE202017382 {

   <#
   .SYNOPSIS
      Author: r00t-3xp10it
      MSI Ambient Link Driver Elevation of Privileges

   .DESCRIPTION
      CVE: 2020-17382
      MSBulletin: N/A
      Affected systems:
         Windows 10 x64 bits (1709)
   #>

    $MSBulletin = "N/A"
    $CVEID = "2020-17382"
    $Architecture = Get-Architecture
    $ArchBuildBits = $Architecture[0]
    $FilePath = ${Env:PROGRAMFILES(x86)} + "\MSI\AmbientLink\Ambient_Link\msio64.sys"

    ## Check for OS affected version/arch
    $MajorVersion = [int]$OSVersion.split(".")[0]
    If(-not($MajorVersion -eq 10 -and $Architecture[0] -eq "64 bits")){
        $VulnStatus = "Not supported on Windows $MajorVersion ($ArchBuildBits) systems"
    }Else{
       
       $SoftwareVersion = (Get-Item "$FilePath" -EA SilentlyContinue).VersionInfo.ProductVersion
       If(-not($SoftwareVersion)){## msio64.sys driver not found
           $VulnStatus = "Not Vulnerable"
       }Else{

          ## Affected: < 1.0.0.8 (Windows 10 x64 bits)
          $Major = [int]$SoftwareVersion.split(".")[0]
          $Revision = [int]$SoftwareVersion.Split(".")[3]

           switch($Major){
           1 { $VulnStatus = @("Not Vulnerable","Appears Vulnerable")[ $Revision -le 8 ] }
           default { $VulnStatus = "Not Vulnerable" }
           }
       }
    }
    Set-ExploitTable $CVEID $VulnStatus
}
