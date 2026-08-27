class SpeechManager extends Object implements IInterestedActorDestroyed, IInterestedPawnDied
	native
	config(Speech);

struct native atomic TaggedSpeechEvent
{
	var SpeechEvent SpeechEvent;
	var ShockPawn AI;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var private config int MaxSimultaneousEvents;
var private config float QueueDelay;
var config array<name> SpeechEventNames;
var private LevelInfo Level;
var const array<SpeechEvent> LoadedSpeechEvents;
var /*0x00000000-0x01000000*/ array<TaggedSpeechEvent> PlayingSpeechEvents;

function Construct(LevelInfo inLevel)
{
	assert(__NFUN_119__(inLevel, none));
	Level = inLevel;
	PopulateSpeechEvents();
	Level.RegisterNotifyActorDestroyed(self);
	Level.RegisterNotifyPawnDied(self);
	return;
	@NULL
	Item
	Vector
	@NULL
}

// Export USpeechManager::execPopulateSpeechEvents(FFrame&, void* const)
native function PopulateSpeechEvents();

function SpeechEvent GetSpeechEvent(name Name)
{
	//native.Name;	
	@NULL
}

function RemoveSpeechEvent(ShockPawn AI, SpeechEvent SpeechEvent)
{
	//native.AI;
	//native.SpeechEvent;	
	@NULL
	Holdable
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	RemoveAI(DeadPawn);
	return;
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	local Pawn DestroyedPawn;

	DestroyedPawn = Pawn(ActorBeingDestroyed);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3E
	/*@Error*/
	RemoveAI(DestroyedPawn);
	return;
	@NULL
	Item
	Item
	@NULL
}

// Export USpeechManager::execGetQueueDelay(FFrame&, void* const)
native final function float GetQueueDelay();

// Export USpeechManager::execGetMaxSimultaneousEvents(FFrame&, void* const)
native final function float GetMaxSimultaneousEvents();

function RemoveAI(Pawn AI)
{
	local int i;

	i = __NFUN_147__(PlayingSpeechEvents.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7A
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6C
	/*@Error*/
	PlayingSpeechEvents.Remove(i, 1);
	__NFUN_164__(i);
	// [Loop Continue]
	goto J0x17;
	return;
	@NULL
	Item
	Item
	@NULL
}

function SpeechEvent GetCurrentlyPlayingSpeechEventFor(ShockPawn AI)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x88
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7A
	/*@Error*/
	return PlayingSpeechEvents[i].SpeechEvent;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	MaxSimultaneousEvents=3
	QueueDelay=5.0000000
	SpeechEventNames[0]="Idling"
	SpeechEventNames[1]="Panicked"
	SpeechEventNames[2]="MimicWokeUp"
	SpeechEventNames[3]="HitVendingMachineSpeech"
	SpeechEventNames[4]="SummonedProtector"
	SpeechEventNames[5]="ThankedProtector"
	SpeechEventNames[6]="SummonedGatherer"
	SpeechEventNames[7]="SummonedGathererAnnoyed"
	SpeechEventNames[8]="RespondedToGatherer"
	SpeechEventNames[9]="Annoyed"
	SpeechEventNames[10]="BeganRespondingToAlarm"
	SpeechEventNames[11]="BeganInvestigating"
	SpeechEventNames[12]="CurrentlyInvestigating"
	SpeechEventNames[13]="FinishedInvestigating"
	SpeechEventNames[14]="FinishedSearching"
	SpeechEventNames[15]="TargetLost"
	SpeechEventNames[16]="FoundADAM"
	SpeechEventNames[17]="Drinking"
	SpeechEventNames[18]="VOgathererDrinking"
	SpeechEventNames[19]="Cough"
	SpeechEventNames[20]="Suicide"
	SpeechEventNames[21]="Weep"
	SpeechEventNames[22]="ProtectorWeep"
	SpeechEventNames[23]="ProtectorShrug"
	SpeechEventNames[24]="GathererCurious"
	SpeechEventNames[25]="GathererFrustrated"
	SpeechEventNames[26]="Surprised"
	SpeechEventNames[27]="Scream"
	SpeechEventNames[28]="GathererBreathing"
	SpeechEventNames[29]="PickedUpByProtector"
	SpeechEventNames[30]="DoorSpeech"
	SpeechEventNames[31]="GroundSpeech"
	SpeechEventNames[32]="GathererPukeEnd"
	SpeechEventNames[33]="GathererFallDown"
	SpeechEventNames[34]="GathererPukeA"
	SpeechEventNames[35]="GathererPukeB"
	SpeechEventNames[36]="GathererPukeC"
	SpeechEventNames[37]="GathererStunned"
	SpeechEventNames[38]="GathererCrySpeech"
	SpeechEventNames[39]="GathererThankedPlayerSpeech"
	SpeechEventNames[40]="HarvestADAMSpeech"
	SpeechEventNames[41]="ExitVentSpeech"
	SpeechEventNames[42]="PeekABooSpeech"
	SpeechEventNames[43]="EntersVentSpeech"
	SpeechEventNames[44]="GathererSaveRecoverA"
	SpeechEventNames[45]="PlayerDied"
	SpeechEventNames[46]="GathererNoSpeech"
	SpeechEventNames[47]="KilledTarget"
	SpeechEventNames[48]="SawAttackTarget"
	SpeechEventNames[49]="EscortDied"
	SpeechEventNames[50]="FriendlySpeech"
	SpeechEventNames[51]="AlarmEnded"
	SpeechEventNames[52]="Recover"
	SpeechEventNames[53]="HeadSpeech"
	SpeechEventNames[54]="GathererGaveTeddyBearA"
	SpeechEventNames[55]="GathererGaveTeddyBearB"
	SpeechEventNames[56]="GathererGaveTeddyBearC"
	SpeechEventNames[57]="GathererGaveTeddyBearD"
	SpeechEventNames[58]="GathererGaveTeddyBearE"
	SpeechEventNames[59]="AttachmentWasStolen"
	SpeechEventNames[60]="Damaged"
	SpeechEventNames[61]="DamagedCritical"
	SpeechEventNames[62]="Died"
	SpeechEventNames[63]="Healed"
	SpeechEventNames[64]="Poisoned"
	SpeechEventNames[65]="Landed"
	SpeechEventNames[66]="Jumped"
	SpeechEventNames[67]="GotUp"
	SpeechEventNames[68]="WentToHealthStation"
	SpeechEventNames[69]="HeadedToBody"
	SpeechEventNames[70]="HeadedToVent"
	SpeechEventNames[71]="RunningToWater"
	SpeechEventNames[72]="JumpingIntoWater"
	SpeechEventNames[73]="Melee"
	SpeechEventNames[74]="ProtectorMelee"
	SpeechEventNames[75]="Alerted"
	SpeechEventNames[76]="Attacking"
	SpeechEventNames[77]="Threaten"
	SpeechEventNames[78]="ChallengedPlayer"
	SpeechEventNames[79]="ChallengedProtector"
	SpeechEventNames[80]="ChallengedGatherer"
	SpeechEventNames[81]="ChallengedAggressor"
	SpeechEventNames[82]="ChallengedMachine"
	SpeechEventNames[83]="TargetFled"
	SpeechEventNames[84]="LostLOS"
	SpeechEventNames[85]="UsedHealthStationSpeech"
	SpeechEventNames[86]="ScreamSpeech"
	SpeechEventNames[87]="AtlasTeleportOut"
	SpeechEventNames[88]="AtlasCharge"
	SpeechEventNames[89]="AtlasScream"
	SpeechEventNames[90]="FledSpeech"
	SpeechEventNames[91]="Terrified"
	SpeechEventNames[92]="FledDuringAttackSpeech"
	SpeechEventNames[93]="CeilingAttackSpeech"
	SpeechEventNames[94]="badAss_speech"
	SpeechEventNames[95]="Diseased"
	SpeechEventNames[96]="Burning"
	SpeechEventNames[97]="Frozen"
	SpeechEventNames[98]="Shocked"
	SpeechEventNames[99]="Berserk"
	SpeechEventNames[100]="BeedUp"
	SpeechEventNames[101]="1_Ch_Brenda"
	SpeechEventNames[102]="1_Ch_DoneIt"
	SpeechEventNames[103]="1_Ch_LastTime"
	SpeechEventNames[104]="1_Ch_OpenUp"
	SpeechEventNames[105]="1_Ch_OpenDoor"
	SpeechEventNames[106]="1_Br_Charley"
	SpeechEventNames[107]="1_Br_MyMoney"
	SpeechEventNames[108]="1_Br_NawCharley"
	SpeechEventNames[109]="1_Br_WhereYouGone"
	SpeechEventNames[110]="1_Lf_BreathingHeavy"
	SpeechEventNames[111]="1_Lf_CeilingCrawlerExA"
	SpeechEventNames[112]="1_Lf_Climbing"
	SpeechEventNames[113]="1_Lf_EnFrancais"
	SpeechEventNames[114]="1_Lf_Exertion"
	SpeechEventNames[115]="1_Lf_Frustration"
	SpeechEventNames[116]="1_Lf_MyRose"
	SpeechEventNames[117]="1_Lf_RageShriek"
	SpeechEventNames[118]="1_Lf_VieEnRose"
	SpeechEventNames[119]="1_Lf_WrapYou"
	SpeechEventNames[120]="1_Lm_PoorDear"
	SpeechEventNames[121]="1_Lm_Weak"
	SpeechEventNames[122]="1_Lm_Yellow"
	SpeechEventNames[123]="1_Ps_QuarantineActive"
	SpeechEventNames[124]="1_Sw_LetsBug"
	SpeechEventNames[125]="1_Sw_ToeingIt"
	SpeechEventNames[126]="1_Bc_Lullaby"
	SpeechEventNames[127]="1_Jy_PleaseMister"
	SpeechEventNames[128]="1_Jy_Death"
	SpeechEventNames[129]="1_Jy_LetMeGo"
	SpeechEventNames[130]="1_Br_BigIdea"
	SpeechEventNames[131]="1_Eg_WontChange"
	SpeechEventNames[132]="1_CryingVO"
	SpeechEventNames[133]="1_Ladysmith_SeesTargetDie_06a"
	SpeechEventNames[134]="1_Drgrossman_Challenge_Common_16a"
	SpeechEventNames[135]="1_ScriptedSteinmanChallenge"
	SpeechEventNames[136]="1BabyJaneTauntMedical"
	SpeechEventNames[137]="1_DrGrosman_SeesTargetDieMedical_B"
	SpeechEventNames[138]="1_ThreatenTenenbaumGatherer"
	SpeechEventNames[139]="1_CasketGrunt"
	SpeechEventNames[140]="1_SteinmanDestroysSign"
	SpeechEventNames[141]="1_GuyInChair"
	SpeechEventNames[142]="1_SteinmanWhyTwo"
	SpeechEventNames[143]="1_Ls_LikeLean"
	SpeechEventNames[144]="1_DG_IncinerateTaunts"
	SpeechEventNames[145]="1_BJ_IncinerateTaunts"
	SpeechEventNames[146]="1_LS_IncinerateTaunts"
	SpeechEventNames[147]="1_LS_TiredInChair"
	SpeechEventNames[148]="2_WadersSettingUpTurret"
	SpeechEventNames[149]="2_DuckyAtCamera"
	SpeechEventNames[150]="2_WadersIdle"
	SpeechEventNames[151]="3_Lm_AssIntroA"
	SpeechEventNames[152]="3_Lm_AssIntroB"
	SpeechEventNames[153]="3_Lm_AssIntroC"
	SpeechEventNames[154]="3_Lm_AssIntroD"
	SpeechEventNames[155]="3_Lm_AssIntroE"
	SpeechEventNames[156]="3_Lm_AssIntroF"
	SpeechEventNames[157]="3_Lm_AssIntroG"
	SpeechEventNames[158]="DoctorCough"
	SpeechEventNames[159]="DoctorTaunt"
	SpeechEventNames[160]="LadyScream"
	SpeechEventNames[161]="3_La_SatRuin"
	SpeechEventNames[162]="3_La_RunSatB"
	SpeechEventNames[163]="3_La_RunSatShit"
	SpeechEventNames[164]="3_La_RunSatFanatics"
	SpeechEventNames[165]="3_La_SatStrangers"
	SpeechEventNames[166]="3_La_YouArePoison"
	SpeechEventNames[167]="3_La_PoisonedEarth"
	SpeechEventNames[168]="3_La_IsThePoison"
	SpeechEventNames[169]="3_La_BroughtPoison"
	SpeechEventNames[170]="3_La_Ready"
	SpeechEventNames[171]="3_La_Now"
	SpeechEventNames[172]="3_Dg_Toxic"
	SpeechEventNames[173]="3_Dg_OurPlace"
	SpeechEventNames[174]="3_Dg_Tangled"
	SpeechEventNames[175]="3_Dg_Defile"
	SpeechEventNames[176]="3_Dg_Trifle"
	SpeechEventNames[177]="3_Dg_RunSatB"
	SpeechEventNames[178]="3_Dg_SatFilthy"
	SpeechEventNames[179]="3_Dg_OurHome"
	SpeechEventNames[180]="3_Dg_KillPoison"
	SpeechEventNames[181]="3_Dg_CutOutPoison"
	SpeechEventNames[182]="3_Dg_BroughtPoison"
	SpeechEventNames[183]="3_Dg_Now"
	SpeechEventNames[184]="3_Dg_Crush"
	SpeechEventNames[185]="3_Dg_DieHere"
	SpeechEventNames[186]="3_Bw_Sacred"
	SpeechEventNames[187]="3_Bw_SmellBlood"
	SpeechEventNames[188]="3_Bw_RunSatShit"
	SpeechEventNames[189]="3_Bw_RunSatFanatics"
	SpeechEventNames[190]="3_Bw_KillPoison"
	SpeechEventNames[191]="3_Bw_YouArePoison"
	SpeechEventNames[192]="3_Bw_IsThePoison"
	SpeechEventNames[193]="3_Bw_PoisonedTrees"
	SpeechEventNames[194]="3_Bw_CmonAlready"
	SpeechEventNames[195]="3_Bw_TakingSoLong"
	SpeechEventNames[196]="3_Bw_DoIt"
	SpeechEventNames[197]="3_Bw_Crush"
	SpeechEventNames[198]="3_Bw_FixEmGood"
	SpeechEventNames[199]="4_Co_Go"
	SpeechEventNames[200]="4_Co_Done"
	SpeechEventNames[201]="4_Co_LetMeSee"
	SpeechEventNames[202]="4_Co_MyGod"
	SpeechEventNames[203]="4_Co_PathClear"
	SpeechEventNames[204]="4_Co_WhatYourself"
	SpeechEventNames[205]="5_Ga_SavePlayerA"
	SpeechEventNames[206]="5_Ga_SavePlayerB"
	SpeechEventNames[207]="5_Ga_SavePlayerC"
	SpeechEventNames[208]="6_Ga_GathColor"
	SpeechEventNames[209]="6_Sw_TimeForTasty"
	SpeechEventNames[210]="6_Ga_SafeHouseA"
	SpeechEventNames[211]="6_Ga_SafeHouseB"
	SpeechEventNames[212]="6_Ga_SafeHouseBadA"
	SpeechEventNames[213]="6_Ga_SafeHouseBadB"
	SpeechEventNames[214]="6_Ga_SafeHouseBadC"
	SpeechEventNames[215]="6_Ga_SafeHouseBadD"
	SpeechEventNames[216]="6_Ga_SafeHouseC"
	SpeechEventNames[217]="6_Ga_SafeHouseGoodA"
	SpeechEventNames[218]="6_Ga_SafeHouseGoodB"
	SpeechEventNames[219]="6_Ga_SafeHouseGoodC"
	SpeechEventNames[220]="6_Ga_SafeHouseGoodD"
	SpeechEventNames[221]="6_Ga_SafeHouseGoodE"
	SpeechEventNames[222]="6_Bw_Squatter"
	SpeechEventNames[223]="7_GauntletTaunt1a"
	SpeechEventNames[224]="7_Flee1a"
	SpeechEventNames[225]="7_Ft_PreFightTaunt1a"
	SpeechEventNames[226]="7_Ft_PreFightTaunt2a"
	SpeechEventNames[227]="7_Ft_PreFightTaunt3a"
	SpeechEventNames[228]="7_Ft_PreFightTaunt4a"
	SpeechEventNames[229]="7_Ft_PreFightTaunt5a"
	SpeechEventNames[230]="7_Ft_PreFightTaunt6a"
	SpeechEventNames[231]="7_Ft_PreFightTaunt7a"
	SpeechEventNames[232]="7_Ft_Laughing"
	SpeechEventNames[233]="7_AggProcSpeech"
	SpeechEventNames[234]="7_JokerLaugh"
	SpeechEventNames[235]="7_Ft_Recharge"
	SpeechEventNames[236]="7_GauntletPlayerLostGatherer"
	SpeechEventNames[237]="AtlasStabWithNeedle"
}