class QuestManager extends DeletableObject
	native
	config(Quests);

var travel ShockPlayer PlayerOwner;
var config travel array<name> QuestNames;
var travel array<Quest> TimedQuests;
var travel array<Quest> TopLevelQuests;
var travel Quest ActiveQuest;
var travel float NextHintReminderLevelTime;
var travel bool HintReminded;
var private native const noexport travel TMap_Padding QuestMap;

function bool InitiateQuest(name QuestName, bool PlayGivenQuestEffect)
{
	//native.QuestName;
	//native.PlayGivenQuestEffect;	
	@NULL
	@NULL
}

function ToggleQuestVisibility(name QuestName)
{
	//native.QuestName;	
	@NULL
}

function OnCompletedQuestObjective(name QuestName, int NumberCompleted, bool PlayGivenQuestEffect)
{
	//native.QuestName;
	//native.NumberCompleted;
	//native.PlayGivenQuestEffect;	
	@NULL
	@NULL
	return default.@NULL;
}

function OnUnCompletedQuestObjective(name QuestName, bool PlayGivenQuestEffect)
{
	//native.QuestName;
	//native.PlayGivenQuestEffect;	
	@NULL
	@NULL
}

function CompleteQuest(name QuestName, bool PlayGivenQuestEffect)
{
	//native.QuestName;
	//native.PlayGivenQuestEffect;	
	@NULL
	@NULL
}

function FailQuest(name QuestName, bool PlayGivenQuestEffect)
{
	//native.QuestName;
	//native.PlayGivenQuestEffect;	
	@NULL
	@NULL
}

function Quest GetQuest(name QuestName)
{
	//native.QuestName;	
	@NULL
}

function ReplaceQuest(name QuestName, name ReplacementName, bool CopyObjectivesCompleted, bool PlayGivenQuestEffect)
{
	//native.QuestName;
	//native.ReplacementName;
	//native.CopyObjectivesCompleted;
	//native.PlayGivenQuestEffect;	
	@NULL
	@NULL
	return default.@NULL;
}

function SetQuestActive(name QuestName, bool Active)
{
	//native.QuestName;
	//native.Active;	
	@NULL
	@NULL
}

function DumpQuests(optional bool bShowHidden, optional bool bShowCompleted)
{
	local int i;

	log(,, "********************************************************");
	log(,, "*** Dumping Quest System ***");
	log(,, "");
	i = 0;
	// End:0xF9
	if(__NFUN_150__(i, TopLevelQuests.Length))
	{
		TopLevelQuests[i].DumpQuest(PlayerOwner.Level.TimeSeconds, 0, bShowHidden, bShowCompleted);
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x7A;
		log(,, "********************************************************");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	QuestNames[0]="Deck6AllLittleOnes"
	QuestNames[1]="Deck6FindAllPlasmids"
	QuestNames[2]="Deck5AllLittleOnes"
	QuestNames[3]="Deck5FindAllPlasmids"
	QuestNames[4]="Deck2AllLittleOnes"
	QuestNames[5]="Deck2FindAllPlasmids"
	QuestNames[6]="ListenAtlas"
	QuestNames[7]="FindWeapon"
	QuestNames[8]="KeepMoving"
	QuestNames[9]="EscapeTunnel"
	QuestNames[10]="GetRadio"
	QuestNames[11]="GettoHigherGround"
	QuestNames[12]="RemoveDebris"
	QuestNames[13]="OverrideDoor"
	QuestNames[14]="GoToMedical"
	QuestNames[15]="GoToTheater"
	QuestNames[16]="BathroomWall"
	QuestNames[17]="UseCredits"
	QuestNames[18]="ShootTheLock"
	QuestNames[19]="MeetSurvivorsDeck_1"
	QuestNames[20]="LiftQuarantineA"
	QuestNames[21]="QuarantineKey"
	QuestNames[22]="LiftLocalQuarantine"
	QuestNames[23]="DestroySteinmanDebris"
	QuestNames[24]="FindTelekinesis"
	QuestNames[25]="ReturnToSteinmanDebris"
	QuestNames[26]="LiftQuarantineUpdate"
	QuestNames[27]="GoToFontaineFisheries"
	QuestNames[28]="GetTheCamera"
	QuestNames[29]="ResearchSplicers"
	QuestNames[30]="DeliverPhotos"
	QuestNames[31]="FindPassage"
	QuestNames[32]="OpenSubDoors"
	QuestNames[33]="GoToTheSub"
	QuestNames[34]="GoToDeck_3"
	QuestNames[35]="RunToSubmarine"
	QuestNames[36]="GiveWeapons"
	QuestNames[37]="GoToDeck_4"
	QuestNames[38]="FindLangford"
	QuestNames[39]="GetRoseForLangford"
	QuestNames[40]="BringRoseToLangford"
	QuestNames[41]="BringRoseToLangfordUpdateA"
	QuestNames[42]="MeetLangford"
	QuestNames[43]="FindMPRFormula"
	QuestNames[44]="GoToMarket"
	QuestNames[45]="CraftMPR"
	QuestNames[46]="CraftMPRUpdateA"
	QuestNames[47]="GatherWater"
	QuestNames[48]="GatherWaterUpdateA"
	QuestNames[49]="GatherChloro"
	QuestNames[50]="GatherChloroUpdateA"
	QuestNames[51]="GatherEnzymes"
	QuestNames[52]="GatherEnzymesUpdateA"
	QuestNames[53]="UseMPR"
	QuestNames[54]="ReturnToArcadia"
	QuestNames[55]="ReleaseMPR"
	QuestNames[56]="ReleaseMPRUpdateA"
	QuestNames[57]="ReleaseMPRUpdateB"
	QuestNames[58]="ReleaseMPRUpdateC"
	QuestNames[59]="SealAmbushDoor"
	QuestNames[60]="DefendMPRAmbush"
	QuestNames[61]="GoToDeck_5"
	QuestNames[62]="FindCohen"
	QuestNames[63]="GoToFleetHall"
	QuestNames[64]="TakeFirstPhoto"
	QuestNames[65]="ReplaceFirstPhoto"
	QuestNames[66]="ReplaceThreeMorePhotos"
	QuestNames[67]="KillCobb"
	QuestNames[68]="KillCobbUpdateA"
	QuestNames[69]="KillCobbUpdateB"
	QuestNames[70]="KillFinnegan"
	QuestNames[71]="KillFinneganUpdateA"
	QuestNames[72]="KillFinneganUpdateB"
	QuestNames[73]="KillRodriguez"
	QuestNames[74]="KillRodriguezA"
	QuestNames[75]="KillRodriguezUpdateA"
	QuestNames[76]="KillRodriguezUpdateB"
	QuestNames[77]="SurviveOutburst"
	QuestNames[78]="LeaveRec"
	QuestNames[79]="GoToCentralControl"
	QuestNames[80]="GoToHeatLoss"
	QuestNames[81]="OverloadGenerator"
	QuestNames[82]="HeatLossMonitoring"
	QuestNames[83]="GoToWorkshops"
	QuestNames[84]="FindEMPBomb"
	QuestNames[85]="FindEMPBombUpdate"
	QuestNames[86]="AssembleBomb"
	QuestNames[87]="FindIonicGel"
	QuestNames[88]="InstallIonicGel"
	QuestNames[89]="FindNitroglycerin"
	QuestNames[90]="InstallNitroglycerin"
	QuestNames[91]="FindR34Wires"
	QuestNames[92]="FindR34WiresUpdate"
	QuestNames[93]="InstallR34Wires"
	QuestNames[94]="PickupBomb"
	QuestNames[95]="PlaceBomb"
	QuestNames[96]="RedirectSteam"
	QuestNames[97]="ReturnToRyan"
	QuestNames[98]="KillRyan"
	QuestNames[99]="Escape"
	QuestNames[100]="SaveYourself"
	QuestNames[101]="SearchSuChong"
	QuestNames[102]="Get1stDose"
	QuestNames[103]="Get1stDoseUpdated"
	QuestNames[104]="UsePlasmidMachine"
	QuestNames[105]="Get2ndDoseAtLab"
	QuestNames[106]="Get2ndDoseAtTen"
	QuestNames[107]="Get2ndDoseAtTenUpdated"
	QuestNames[108]="FindFontaine"
	QuestNames[109]="GoToBathysphere"
	QuestNames[110]="PursueAtlas"
	QuestNames[111]="SearchProtector"
	QuestNames[112]="BecomeAProtector"
	QuestNames[113]="ProtectorSmell"
	QuestNames[114]="ProtectorSpeech"
	QuestNames[115]="ProtectorSuit"
	QuestNames[116]="FindPheremoneSamples"
	QuestNames[117]="UseVoiceboxMachine"
	QuestNames[118]="GetHelmet"
	QuestNames[119]="GetBodysuit"
	QuestNames[120]="GetBoots"
	QuestNames[121]="GetBoots_2"
	QuestNames[122]="ReturnToTesting"
	QuestNames[123]="GetAGatherer"
	QuestNames[124]="EscortGathererToEnd"
	QuestNames[125]="GetGathererTool"
	QuestNames[126]="ElevatorToBoss"
	QuestNames[127]="DefeatAtlas"
	QuestNames[128]="CRCSister"
	QuestNames[129]="CRCSister_2"
	QuestNames[130]="CRCRoses"
	QuestNames[131]="CRDSister"
	QuestNames[132]="CRDRoses"
	QuestNames[133]="CREShocks"
	QuestNames[134]="CRERoses"
	QuestNames[135]="CRESister"
	QuestNames[136]="CRESisterUpdate"
	QuestNames[137]="CREEntry"
}