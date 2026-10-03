# BioShockRuntime command-line switches

Generated 2026-10-03 by `python tools/ue5/gen_ue_reference.py <outdir>` from `tools/ue5/BioShockRuntime/Source` (paths below are relative to it). Do not edit by hand.

53 switches. Pass them on the game/editor command line with a leading dash (`-bioshockscreenshot`, `-bioshockshotpath=C:/x.png`). A switch ending in `=` takes a value; `FParse::Param` switches are bare flags. capture_shot.ps1 forwards extras with `-Extra '-bioshockvmoffset=28,10,-24'`.

| switch | parsed by | where | context |
|---|---|---|---|
| `-bioshockfov=` | FParse::Value | BioShockRuntime/Private/ShockPlayer.cpp:336 | `if (FParse::Value(FCommandLine::Get(), TEXT("bioshockfov="), S, false) && !S.IsEmpty())` |
| `-bioshockmenushot=` | FParse::Value | BioShockRuntime/Private/ShockMenuGameMode.cpp:82 | `if (FParse::Value(FCommandLine::Get(), TEXT("bioshockmenushot="), ShotPath) && !ShotPath.IsEmpty())` |
| `-bioshockmovementdelay=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:3475 | `TEXT("bioshockmovementdelay="),` |
| `-bioshockmovementduration=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:1264 | `FParse::Value(FCommandLine::Get(), TEXT("bioshockmovementduration="), MovementVerifyDuration);` |
| `-bioshockmovementminz=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:1265 | `FParse::Value(FCommandLine::Get(), TEXT("bioshockmovementminz="), MovementVerifyMinZIncrease);` |
| `-bioshockmovementroute=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:1266 | `FParse::Value(FCommandLine::Get(), TEXT("bioshockmovementroute="), MovementVerifyRoute);` |
| `-bioshockmovementstart=` | FParse::Value via ParseMovementVector() | BioShockRuntime/Private/ShockGameMode.cpp:1248 | `if (ParseMovementVector(TEXT("bioshockmovementstart="), RequestedStart))` |
| `-bioshockmovementtarget=` | FParse::Value via ParseMovementVector() | BioShockRuntime/Private/ShockGameMode.cpp:1258 | `ParseMovementVector(TEXT("bioshockmovementtarget="), MovementVerifyTargetLoc);` |
| `-bioshockprobesteps=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:3718 | `FParse::Value(FCommandLine::Get(), TEXT("bioshockprobesteps="), Steps);` |
| `-bioshockragdollkeys=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:2576 | `if (FParse::Value(FCommandLine::Get(), TEXT("bioshockragdollkeys="), KeyList) && !KeyList.IsEmpty())` |
| `-bioshockscreenshot` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3495, BioShockRuntime/Private/ShockGameMode.cpp:3557 | `if (!FParse::Param(FCommandLine::Get(), TEXT("bioshockscreenshot")))` |
| `-bioshockshotabs=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:3998 | `if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotabs="), AbsStr, false))` |
| `-bioshockshotcombo` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:4104 | `const bool bForceCombo = FParse::Param(FCommandLine::Get(), TEXT("bioshockshotcombo"));` |
| `-bioshockshotdeathrespawn` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3187 | `if (FParse::Param(FCommandLine::Get(), TEXT("bioshockshotdeathrespawn")))` |
| `-bioshockshotev=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:4075 | `if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotev="), ShotEv)` |
| `-bioshockshotfire` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3890 | `if (FParse::Param(FCommandLine::Get(), TEXT("bioshockshotfire"))` |
| `-bioshockshotfireatwall` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3891, BioShockRuntime/Private/ShockGameMode.cpp:3909 | `&& !FParse::Param(FCommandLine::Get(), TEXT("bioshockshotfireatwall")))` |
| `-bioshockshotgarden` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:4103 | `const bool bForceGarden = FParse::Param(FCommandLine::Get(), TEXT("bioshockshotgarden"));` |
| `-bioshockshotgenebank` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:4101 | `const bool bForceGene = FParse::Param(FCommandLine::Get(), TEXT("bioshockshotgenebank"));` |
| `-bioshockshothack` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:4105 | `const bool bForceHack = FParse::Param(FCommandLine::Get(), TEXT("bioshockshothack"));` |
| `-bioshockshotheight=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:3960, BioShockRuntime/Private/ShockMenuGameMode.cpp:97 | `FParse::Value(FCommandLine::Get(), TEXT("bioshockshotheight="), ShotH);` |
| `-bioshockshothud` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:4094 | `if (FParse::Param(FCommandLine::Get(), TEXT("bioshockshothud")))` |
| `-bioshockshotinterval=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:3560 | `FParse::Value(FCommandLine::Get(), TEXT("bioshockshotinterval="), Interval);` |
| `-bioshockshotinvent` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:4102 | `const bool bForceInvent = FParse::Param(FCommandLine::Get(), TEXT("bioshockshotinvent"));` |
| `-bioshockshotlook=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:4009 | `if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotlook="), LookStr, false))` |
| `-bioshockshotmove=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:3971 | `if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotmove="), MoveStr, false))` |
| `-bioshockshotpath=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:3933 | `if (!FParse::Value(FCommandLine::Get(), TEXT("bioshockshotpath="), Path) \|\| Path.IsEmpty())` |
| `-bioshockshotpause` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:4099 | `const bool bForcePause = FParse::Param(FCommandLine::Get(), TEXT("bioshockshotpause"));` |
| `-bioshockshotpitch=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:4029 | `if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotpitch="), ShotPitch))` |
| `-bioshockshotradial` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:4097 | `const bool bForceRadial = FParse::Param(FCommandLine::Get(), TEXT("bioshockshotradial"));` |
| `-bioshockshotragdoll` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3333, BioShockRuntime/Private/ShockGameMode.cpp:3358 | `\|\| FParse::Param(FCommandLine::Get(), TEXT("bioshockshotragdoll"));` |
| `-bioshockshotreload` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3896 | `if (FParse::Param(FCommandLine::Get(), TEXT("bioshockshotreload")))` |
| `-bioshockshotsettle=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:3877 | `FParse::Value(FCommandLine::Get(), TEXT("bioshockshotsettle="), SettleTicks);` |
| `-bioshockshotstatus` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:4098 | `const bool bForceStatus = FParse::Param(FCommandLine::Get(), TEXT("bioshockshotstatus"));` |
| `-bioshockshotvend` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:4100 | `const bool bForceVend = FParse::Param(FCommandLine::Get(), TEXT("bioshockshotvend"));` |
| `-bioshockshotwidth=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:3959, BioShockRuntime/Private/ShockMenuGameMode.cpp:96 | `FParse::Value(FCommandLine::Get(), TEXT("bioshockshotwidth="), ShotW);` |
| `-bioshockshotyaw=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:4025 | `if (FParse::Value(FCommandLine::Get(), TEXT("bioshockshotyaw="), ShotYaw))` |
| `-bioshockstartslot=` | FParse::Value | BioShockRuntime/Private/ShockGameMode.cpp:444 | `FParse::Value(FCommandLine::Get(), TEXT("bioshockstartslot="), StartSlot);` |
| `-bioshockverifyambient` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3164, BioShockRuntime/Private/ShockGameMode.cpp:3211 | `\|\| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyambient"))` |
| `-bioshockverifyaudio` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3163, BioShockRuntime/Private/ShockGameMode.cpp:3280 | `\|\| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyaudio"))` |
| `-bioshockverifyencounter` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3166, BioShockRuntime/Private/ShockGameMode.cpp:3331, BioShockRuntime/Private/ShockGameMode.cpp:3447 | `\|\| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyencounter"))` |
| `-bioshockverifyenemies` | FParse::Param | BioShockRuntime/Private/ShockEnemySpawner.cpp:66 | `&& !FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyenemies"));` |
| `-bioshockverifyhud` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3535 | `if (FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyhud")))` |
| `-bioshockverifyinteract` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3170, BioShockRuntime/Private/ShockGameMode.cpp:3438 | `\|\| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyinteract"))))` |
| `-bioshockverifymovement` | FParse::Param | BioShockRuntime/Private/ShockEnemySpawner.cpp:65, BioShockRuntime/Private/ShockGameMode.cpp:3161, BioShockRuntime/Private/ShockGameMode.cpp:3467 | `return FParse::Param(FCommandLine::Get(), TEXT("bioshockverifymovement"))` |
| `-bioshockverifyphysics` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3135 | `if (FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyphysics")))` |
| `-bioshockverifypossess` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3165, BioShockRuntime/Private/ShockGameMode.cpp:3330, BioShockRuntime/Private/ShockGameMode.cpp:3443, BioShockRuntime/Private/ShockGameMode.cpp:3567 | `\|\| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifypossess"))` |
| `-bioshockverifyragdoll` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3167, BioShockRuntime/Private/ShockGameMode.cpp:3332, BioShockRuntime/Private/ShockGameMode.cpp:3356 | `\|\| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyragdoll"))` |
| `-bioshockverifyragdollcoverage` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3169, BioShockRuntime/Private/ShockGameMode.cpp:3433 | `\|\| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyragdollcoverage"))` |
| `-bioshockverifyweaponimpacts` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3168, BioShockRuntime/Private/ShockGameMode.cpp:3428 | `\|\| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyweaponimpacts"))` |
| `-bioshockverifyweapontrack` | FParse::Param | BioShockRuntime/Private/ShockGameMode.cpp:3162, BioShockRuntime/Private/ShockGameMode.cpp:3500 | `\|\| FParse::Param(FCommandLine::Get(), TEXT("bioshockverifyweapontrack"))` |
| `-bioshockvmoffset=` | FParse::Value via ParseTriple() | BioShockRuntime/Private/ShockPlayer.cpp:1049 | `if (ParseTriple(TEXT("bioshockvmoffset="), X, Y, Z))` |
| `-bioshockvmrot=` | FParse::Value via ParseTriple() | BioShockRuntime/Private/ShockPlayer.cpp:1053 | `if (ParseTriple(TEXT("bioshockvmrot="), X, Y, Z))` |
