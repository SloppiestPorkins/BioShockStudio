class ShockCheatManager extends CheatManager within PlayerController
	native
	config(ShockCheat);

var config array<string> WeaponName;
var config array<string> ItemName;
var config array<name> PlasmidName;
var bool bHideHUD;
var string InputContextListString;

function runScript(name Label)
{
	local Script S;

	// End:0x87
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'runScript', but that command is disabled in the CENSORED version.");
		goto J0x138;
		S = Script(Outer.findByLabel(Class'Scripting.Script', Label));
	}
	// End:0x100
	if(__NFUN_114__(S, none))
	{
		log(,, __NFUN_112__(__NFUN_112__("Script ", string(Label)), " not found"));
		goto J0x138;
		S.executeFromExec();
		log(,, __NFUN_112__("Ran script ", string(Label)));
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function StartInputDebugging()
{
	InputContextListString = Outer.Level.GetLocalPlayerController().ConsoleCommand("GETINPUTCONTEXTSTACK");
	log(,, "========== Starting Input Context Debugging ===========");
	log(,, "*** Current Input Context Stack ***");
	Outer.Level.GetLocalPlayerController().ConsoleCommand("DUMPINPUTCONTEXTSTACK");
	log(,, "=======================================================");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function StopInputDebugging()
{
	local string CurrentInputContextListString;

	CurrentInputContextListString = Outer.Level.GetLocalPlayerController().ConsoleCommand("GETINPUTCONTEXTSTACK");
	// End:0x125
	if(__NFUN_122__(CurrentInputContextListString, InputContextListString))
	{
		log(,, "========== Input Context Debugging SUCCESSFUL ============");
		log(,, "*** Current Input Context Stack ***");
		Outer.Level.GetLocalPlayerController().ConsoleCommand("DUMPINPUTCONTEXTSTACK");
		goto J0x2F2;
		log(,, "========== Input Context Debugging FAILED ============");
	}
	log(,, "*** OLD Input Context Stack ***");
	Outer.Level.GetLocalPlayerController().ConsoleCommand(__NFUN_112__("SETINPUTCONTEXTSTACK ", InputContextListString));
	Outer.Level.GetLocalPlayerController().ConsoleCommand("DUMPINPUTCONTEXTSTACK");
	log(,, "*** NEW Input Context Stack ***");
	Outer.Level.GetLocalPlayerController().ConsoleCommand(__NFUN_112__("SETINPUTCONTEXTSTACK ", CurrentInputContextListString));
	Outer.Level.GetLocalPlayerController().ConsoleCommand("DUMPINPUTCONTEXTSTACK");
	log(,, "=======================================================");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DefaultTrigger()
{
	Outer.Level.GetLocalPlayerController().ConsoleCommand("SETINPUTCONTEXTSTACK Default");
	ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn).ImmediateFireOfPendingWeaponEnabled = false;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TriggerSwap()
{
	Outer.Level.GetLocalPlayerController().ConsoleCommand("SETINPUTCONTEXTSTACK triggerswap");
	return;
	@NULL
	Item
	default.Item
}

function TriggerSwapImmediateFire()
{
	Outer.Level.GetLocalPlayerController().ConsoleCommand("SETINPUTCONTEXTSTACK triggerswap");
	ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn).ImmediateFireOfPendingWeaponEnabled = true;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TriggerSwapHold()
{
	Outer.Level.GetLocalPlayerController().ConsoleCommand("SETINPUTCONTEXTSTACK triggerswaphold");
	return;
	@NULL
	Item
	default.Item
}

function TriggerSwapAlt()
{
	Outer.Level.GetLocalPlayerController().ConsoleCommand("SETINPUTCONTEXTSTACK triggerswapalt");
	return;
	@NULL
	Item
	default.Item
}

function TriggerSwapHoldAlt()
{
	Outer.Level.GetLocalPlayerController().ConsoleCommand("SETINPUTCONTEXTSTACK triggerswapholdalt");
	return;
	@NULL
	Item
	default.Item
}

function AddOverlayEffect(name ActorLabel, string MaterialName)
{
	local Actor theActor;
	local Material TheMaterial;

	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Executing AddOverlayEffect(", string(ActorLabel)), ", "), MaterialName), ")"));
	theActor = Outer.Level.findByLabel(Class'Engine.Actor', ActorLabel);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x181
	/*@Error*/
	TheMaterial = Material(DynamicFindObject(MaterialName, Class'Engine.Material'));
	// End:0xE7
	if(__NFUN_114__(TheMaterial, none))
	{
		TheMaterial = Texture'ShockGame.Engine_res.DefaultTexture';
		log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("Applying temporary overlay: Actor = ", string(theActor.Name)), " Material = "), string(TheMaterial.Name)));
	}
	theActor.AddTemporaryOverlayMaterial(TheMaterial, 3.0000000, 0);
	goto J0x1BF;
	log(,, __NFUN_112__(__NFUN_112__("Couldn't find an actor with Label '", string(ActorLabel)), "'"));
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ShowAllManualTopics()
{
	local ShockPlayer Player;

	// End:0x91
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'ShowAllManualTopics', but that command is disabled in the CENSORED version.");
		goto J0xFB;
		Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xFB
	/*@Error*/
	Player.ShowAllManualTopics();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function EnableVision(optional Class<BaseShockAI> OptionalAIClass)
{
	local Class<BaseShockAI> AIClass;
	local Actor AI;

	// End:0x8A
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'EnableVision', but that command is disabled in the CENSORED version.");
		goto J0x173;
		// End:0xAF
		if(__NFUN_114__(OptionalAIClass, none))
		{
		}
		AIClass = Class'ShockGame.BaseShockAI';
		goto J0xC2;
		AIClass = OptionalAIClass;
		// End:0x109
		foreach Outer.__NFUN_313__(AIClass, AI)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x0A6! */
		BaseShockAI(AI).SetVisionState(true);				
		Outer.Level.GetLocalPlayerController().ClientMessage(__NFUN_168__("Vision now enabled for all:", string(AIClass.Name)));
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x000! */
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DisableVision(optional Class<BaseShockAI> OptionalAIClass)
{
	local Class<BaseShockAI> AIClass;
	local Actor AI;

	// End:0x8B
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'DisableVision', but that command is disabled in the CENSORED version.");
		goto J0x161;
		// End:0xB0
		if(__NFUN_114__(OptionalAIClass, none))
		{
		}
		AIClass = Class'ShockGame.BaseShockAI';
		goto J0xC3;
		AIClass = OptionalAIClass;
		// End:0x10A
		foreach Outer.__NFUN_313__(AIClass, AI)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x0A7! */
		BaseShockAI(AI).SetVisionState(false);				
		Outer.ClientMessage(__NFUN_168__("CHEAT: Vision now disabled for all:", string(AIClass.Name)));
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x000! */
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function MakeAIGod(optional Class<BaseShockAI> OptionalAIClass)
{
	// End:0x87
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'MakeAIGod', but that command is disabled in the CENSORED version.");
		goto J0x9A;
		MakeAIsGod(OptionalAIClass);
	}
	return;
	@NULL
	Item
	J0x9A:

	default.Item
}

function MakeAIsGod(optional Class<BaseShockAI> OptionalAIClass)
{
	local Class<BaseShockAI> AIClass;
	local Actor AI;

	// End:0x88
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'MakeAIsGod', but that command is disabled in the CENSORED version.");
		goto J0x1C4;
		// End:0xAD
		if(__NFUN_114__(OptionalAIClass, none))
		{
		}
		AIClass = Class'ShockGame.BaseShockAI';
		goto J0xC0;
		AIClass = OptionalAIClass;
		// End:0x168
		foreach Outer.__NFUN_313__(AIClass, AI)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x0A4! */
		// End:0x167
		if(__NFUN_119__(BaseShockAI(AI).Controller, none))
		{
			BaseShockAI(AI).Controller.bGodMode = __NFUN_129__(BaseShockAI(AI).Controller.bGodMode);						
			Outer.Level.GetLocalPlayerController().ClientMessage(__NFUN_168__("Made god all:", string(AIClass.Name)));
			return;
			@NULL
			Item
		}
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x000! */
	default.Item
	@NULL
}

function Suicide()
{
	local ShockPlayer Player;
	local PlayerController PC;

	// End:0x85
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'Suicide', but that command is disabled in the CENSORED version.");
		goto J0x1A0;
		PC = Outer.Level.GetLocalPlayerController();
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A0
	/*@Error*/
	Player = ShockPlayer(PC.Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A0
	/*@Error*/
	Player.TakeSimpleDamage(36, __NFUN_171__(100.0000000, Player.GetMaxHealth()), 1.0000000, Player);
	Player.SetLowHealthInvulnerabilityLevelTime(0.0000000);
	Player.TakeSimpleDamage(36, __NFUN_171__(100.0000000, Player.GetMaxHealth()), 1.0000000, Player);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function SpawnSecurityBot(optional int NumBotsToSpawn)
{
	local Pawn Player;

	// End:0x8E
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'SpawnSecurityBot', but that command is disabled in the CENSORED version.");
		goto J0x12F;
		// End:0xA8
		if(__NFUN_154__(NumBotsToSpawn, 0))
		{
		}
		NumBotsToSpawn = 1;
		Player = Outer.Level.GetLocalPlayerController().Pawn;
	}
	SpawningManagerBase(Outer.Level.SpawningManager).SpawnSecurityBot(NumBotsToSpawn, Player);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function SpawnTestBot()
{
	// End:0x8A
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'SpawnTestBot', but that command is disabled in the CENSORED version.");
		goto J0xD2;
		ShockGameInfo(Outer.Level.Game).GetSecurityManager().SpawnTestBot();
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function StartSecurityAlarm()
{
	local Class<ShockPawn> BotClass;
	local ShockPawn Player;

	// End:0x90
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'StartSecurityAlarm', but that command is disabled in the CENSORED version.");
		goto J0x17A;
		Player = ShockPawn(Outer.Level.GetLocalPlayerController().Pawn);
	}
	BotClass = Class<ShockPawn>(DynamicLoadObject("ShockAI.MediumSecurityBot", Class'Core.Class'));
	ShockGameInfo(Outer.Level.Game).GetSecurityManager().StartAlarm(Player, Player, BotClass, 3);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function StopSecurityAlarm()
{
	// End:0x8F
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'StopSecurityAlarm', but that command is disabled in the CENSORED version.");
		goto J0xD7;
		ShockGameInfo(Outer.Level.Game).GetSecurityManager().StopAlarm();
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function HackSecuritySystem(float TimeOut)
{
	// End:0x90
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'HackSecuritySystem', but that command is disabled in the CENSORED version.");
		goto J0xE1;
		ShockGameInfo(Outer.Level.Game).GetSecurityManager().HackSecuritySystem(TimeOut);
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TestPlasmiNow()
{
	local ShockPlayer Player;

	// End:0x8B
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'TestPlasmiNow', but that command is disabled in the CENSORED version.");
		goto J0xF0;
		Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	}
	Player.LaunchPlasmiNowScreen('Telekinesis', 1);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ToggleAIDebug()
{
	ShockGameInfo(Outer.Level.Game).bDisplayDebugInfoOnAIs = __NFUN_129__(ShockGameInfo(Outer.Level.Game).bDisplayDebugInfoOnAIs);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DebugAISpeech()
{
	ShockGameInfo(Outer.Level.Game).bDebugAISpeech = __NFUN_129__(ShockGameInfo(Outer.Level.Game).bDebugAISpeech);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DebugPathfinding()
{
	ShockGameInfo(Outer.Level.Game).bDisplayPathfindingInfo = __NFUN_129__(ShockGameInfo(Outer.Level.Game).bDisplayPathfindingInfo);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DebugCollisionAvoidance()
{
	ShockGameInfo(Outer.Level.Game).bDebugCollisionAvoidance = __NFUN_129__(ShockGameInfo(Outer.Level.Game).bDebugCollisionAvoidance);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ShowHeadTracking()
{
	ShockGameInfo(Outer.Level.Game).bDebugHeadTracking = __NFUN_129__(ShockGameInfo(Outer.Level.Game).bDebugHeadTracking);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ToggleViewTriggerDebug()
{
	ShockGameInfo(Outer.Level.Game).bDebugViewTriggers = __NFUN_129__(ShockGameInfo(Outer.Level.Game).bDebugViewTriggers);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TogglePlayerInvisible()
{
	// End:0xC5
	if(ShockGameInfo(Outer.Level.Game).bPlayerInvisible)
	{
		ShockGameInfo(Outer.Level.Game).bPlayerInvisible = false;
		Outer.Level.GetLocalPlayerController().ClientMessage("Player is now visible");
		goto J0x14C;
		ShockGameInfo(Outer.Level.Game).bPlayerInvisible = true;
		Outer.Level.GetLocalPlayerController().ClientMessage("Player is now invisible");
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ToggleIlluminationAffectingVision()
{
	// End:0xCF
	if(ShockGameInfo(Outer.Level.Game).bDisableIlluminationAffectingVision)
	{
		ShockGameInfo(Outer.Level.Game).bDisableIlluminationAffectingVision = false;
		Outer.Level.GetLocalPlayerController().ClientMessage("Illumination will affect vision");
		goto J0x162;
		ShockGameInfo(Outer.Level.Game).bDisableIlluminationAffectingVision = true;
		Outer.Level.GetLocalPlayerController().ClientMessage("Illumination will not affect vision");
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ToggleDebugPlayerIllumination()
{
	// End:0xE0
	if(ShockGameInfo(Outer.Level.Game).bDebugIlluminationAffectingVision)
	{
		ShockGameInfo(Outer.Level.Game).bDebugIlluminationAffectingVision = false;
		Outer.Level.GetLocalPlayerController().ClientMessage("Illumination values on the player are now hidden");
		goto J0x183;
		ShockGameInfo(Outer.Level.Game).bDebugIlluminationAffectingVision = true;
		Outer.Level.GetLocalPlayerController().ClientMessage("Now showing (raw) Illumination values on the player");
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function Actor GetDebugLocomotionActor(name ActorName)
{
	local Actor DebugLocomotionActor, ActorIter;

	// End:0x88
	if(__NFUN_255__(ActorName, 'None'))
	{
		// End:0x84
		foreach Outer.Level.__NFUN_304__(Class'Engine.Actor', ActorIter)
		{
			// End:0x83
			if(__NFUN_254__(ActorIter.Name, ActorName))
			{
				DebugLocomotionActor = ActorIter;
				// End:0x84
				break;								
				goto J0xC3;
				DebugLocomotionActor = Outer.Level.GetLocalPlayerController().ViewTarget;
			}
		}
		return DebugLocomotionActor;
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function DebugLocomotion(optional name ActorName)
{
	DebugLocomotionNative(GetDebugLocomotionActor(ActorName));
	return;
	@NULL
}

function DebugLocomotionNative(Actor Actor)
{
	//native.Actor;	
	@NULL
}

function DebugLocomotionLines(optional name ActorName)
{
	DebugLocomotionLinesNative(GetDebugLocomotionActor(ActorName));
	return;
	@NULL
}

function DebugLocomotionLinesNative(Actor Actor)
{
	//native.Actor;	
	@NULL
}

function DebugLocomotionInfo(optional name ActorName)
{
	DebugLocomotionInfoNative(GetDebugLocomotionActor(ActorName));
	return;
	@NULL
}

function DebugLocomotionInfoNative(Actor Actor)
{
	//native.Actor;	
	@NULL
}

function Actor GetDebugAimPosesActor(name ActorName)
{
	local Actor DebugAimPosesActor, ActorIter;

	// End:0x88
	if(__NFUN_255__(ActorName, 'None'))
	{
		// End:0x84
		foreach Outer.Level.__NFUN_304__(Class'Engine.Actor', ActorIter)
		{
			// End:0x83
			if(__NFUN_254__(ActorIter.Name, ActorName))
			{
				DebugAimPosesActor = ActorIter;
				// End:0x84
				break;								
				goto J0xC3;
				DebugAimPosesActor = Outer.Level.GetLocalPlayerController().ViewTarget;
			}
		}
		return DebugAimPosesActor;
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function DebugAimPoses(optional name ActorName)
{
	DebugAimPosesNative(GetDebugAimPosesActor(ActorName));
	return;
	@NULL
}

function DebugAimPosesNative(Actor Actor)
{
	//native.Actor;	
	@NULL
}

function Actor GetDebugFootIKActor(name ActorName)
{
	local Actor DebugFootIKActor, ActorIter;

	// End:0x88
	if(__NFUN_255__(ActorName, 'None'))
	{
		// End:0x84
		foreach Outer.Level.__NFUN_304__(Class'Engine.Actor', ActorIter)
		{
			// End:0x83
			if(__NFUN_254__(ActorIter.Name, ActorName))
			{
				DebugFootIKActor = ActorIter;
				// End:0x84
				break;								
				goto J0xC3;
				DebugFootIKActor = Outer.Level.GetLocalPlayerController().ViewTarget;
			}
		}
		return DebugFootIKActor;
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function DebugFootIK(optional name ActorName)
{
	DebugFootIKNative(GetDebugFootIKActor(ActorName));
	return;
	@NULL
}

function DebugFootIKNative(Actor Actor)
{
	//native.Actor;	
	@NULL
}

exec function ClearStayingLines()
{
	ClearStayingLinesNative();
	return;
}

// Export UShockCheatManager::execClearStayingLinesNative(FFrame&, void* const)
native function ClearStayingLinesNative();

function DisplayPlayingAnimations()
{
	ShockGameInfo(Outer.Level.Game).bDisplayAnimationInfo = __NFUN_129__(ShockGameInfo(Outer.Level.Game).bDisplayAnimationInfo);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ShowVC()
{
	Outer.Level.GetLocalPlayerController().ClientMessage("Now showing doubt and certainty vision cones");
	ShockGameInfo(Outer.Level.Game).bShowDoubtVisionCones = true;
	ShockGameInfo(Outer.Level.Game).bShowCertaintyVisionCones = true;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function HideVC()
{
	Outer.Level.GetLocalPlayerController().ClientMessage("Doubt and certainty vision cones are now hidden");
	ShockGameInfo(Outer.Level.Game).bShowDoubtVisionCones = false;
	ShockGameInfo(Outer.Level.Game).bShowCertaintyVisionCones = false;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ToggleDoubtVC()
{
	// End:0xD1
	if(ShockGameInfo(Outer.Level.Game).bShowDoubtVisionCones)
	{
		ShockGameInfo(Outer.Level.Game).bShowDoubtVisionCones = false;
		Outer.Level.GetLocalPlayerController().ClientMessage("Doubt vision cones are now hidden");
		goto J0x15F;
		ShockGameInfo(Outer.Level.Game).bShowDoubtVisionCones = true;
		Outer.Level.GetLocalPlayerController().ClientMessage("Now showing doubt vision cones");
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ToggleCertaintyVC()
{
	// End:0xD5
	if(ShockGameInfo(Outer.Level.Game).bShowCertaintyVisionCones)
	{
		ShockGameInfo(Outer.Level.Game).bShowCertaintyVisionCones = false;
		Outer.Level.GetLocalPlayerController().ClientMessage("Certainty vision cones are now hidden");
		goto J0x167;
		ShockGameInfo(Outer.Level.Game).bShowCertaintyVisionCones = true;
		Outer.Level.GetLocalPlayerController().ClientMessage("Now showing certainty vision cones");
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DebugVC()
{
	// End:0xED
	if(ShockGameInfo(Outer.Level.Game).bDebugVisionCones)
	{
		ShockGameInfo(Outer.Level.Game).bDebugVisionCones = false;
		Outer.Level.GetLocalPlayerController().ClientMessage("Now showing the vision cones that the AI sees the player with");
		goto J0x187;
		ShockGameInfo(Outer.Level.Game).bDebugVisionCones = true;
		Outer.Level.GetLocalPlayerController().ClientMessage("The AI sees the player with are now hidden");
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function SpawnProtector(int NumProtectorsToSpawn)
{
	local Pawn Player;

	// End:0x8C
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'SpawnProtector', but that command is disabled in the CENSORED version.");
		goto J0x113;
		Player = Outer.Level.GetLocalPlayerController().Pawn;
	}
	SpawningManagerBase(Outer.Level.SpawningManager).SpawnProtector(NumProtectorsToSpawn, Player);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function IGdqd()
{
	// End:0x83
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'IGdqd', but that command is disabled in the CENSORED version.");
		goto J0x8D;
		God();
	}
	return;
	@NULL
	Item
}

function IGkfa()
{
	// End:0x83
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'IGkfa', but that command is disabled in the CENSORED version.");
		goto J0x97;
		GiveAll();
	}
	GiveAllPlasmids();
	return;
	@NULL
	Item
}

function IGBigBucks()
{
	local ShockPlayer Player;

	// End:0x88
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'IGBigBucks', but that command is disabled in the CENSORED version.");
		goto J0xFB;
		Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	}
	Player.GiveItem(1000, "ShockGame.Credits");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function IGReallyBigBucks()
{
	local ShockPlayer Player;

	// End:0x8E
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'IGReallyBigBucks', but that command is disabled in the CENSORED version.");
		goto J0x101;
		Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	}
	Player.GiveItem(1000000, "ShockGame.Credits");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function LoadNewGamePlusData()
{
	local ShockPlayer Player;

	Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	Player.LoadGamePlusData();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function SaveNewGamePlusData()
{
	local ShockPlayer Player;

	Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	Player.SaveGamePlusData();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function GiveAll()
{
	local int i;
	local bool OldDisableInventoryWarnings;
	local ShockPlayer Player;

	// End:0x85
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'GiveAll', but that command is disabled in the CENSORED version.");
		goto J0x255;
		Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	}
	OldDisableInventoryWarnings = Player.disableInventoryWarnings;
	Player.disableInventoryWarnings = true;
	i = 0;
	// End:0x15F
	if(__NFUN_150__(i, WeaponName.Length))
	{
		Player.GiveWeapon(WeaponName[i]);
		__NFUN_165__(i);		
		Player.UnlockInventorySlots(40);
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1D8
		/*@Error*/
		Player.GiveItem(999, ItemName[i]);
		__NFUN_165__(i);
	}
	goto J0x183;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x233
	/*@Error*/
	Player.TestAddAvailablePlasmid(PlasmidName[i]);
	__NFUN_165__(i);
	goto J0x1E3;
	Player.disableInventoryWarnings = OldDisableInventoryWarnings;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function GiveLoadout(string loadout)
{
	// End:0x89
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'GiveLoadout', but that command is disabled in the CENSORED version.");
		goto J0x10F;
		Outer.Level.GetLocalPlayerController().ConsoleCommand(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("exec ", string(Outer.Level.Outer.Name)), "_"), loadout), ".ini"));
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function GiveAllPlasmids()
{
	local bool OldDisableInventoryWarnings;
	local ShockPlayer Player;

	// End:0x8D
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'GiveAllPlasmids', but that command is disabled in the CENSORED version.");
		goto J0x177;
		Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	}
	OldDisableInventoryWarnings = Player.disableInventoryWarnings;
	Player.disableInventoryWarnings = true;
	Outer.Level.GetLocalPlayerController().ConsoleCommand("exec AllPlasmids.ini");
	Player.disableInventoryWarnings = OldDisableInventoryWarnings;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ToggleHud()
{
	// End:0x1A
	if(bHideHUD)
	{
		ShowHud();
		goto J0x24;
		HideHud();
	}
	return;
	@NULL
}

function ShowHud()
{
	local ShockPlayerController PlayerController;

	PlayerController = ShockPlayerController(Outer.Level.GetLocalPlayerController());
	bHideHUD = false;
	Outer.Level.GetFlashGUIController().HideFlashMovies = false;
	PlayerController.ConsoleCommand("set hands bhidden false");
	PlayerController.ConsoleCommand("set shockhud DontRenderHud false");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function HideHud()
{
	local ShockPlayerController PlayerController;

	PlayerController = ShockPlayerController(Outer.Level.GetLocalPlayerController());
	bHideHUD = true;
	Outer.Level.GetFlashGUIController().HideFlashMovies = true;
	PlayerController.ConsoleCommand("set hands bhidden true");
	PlayerController.ConsoleCommand("set shockhud DontRenderHud true");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function GotoLocation(string Coords)
{
	local ShockPlayer Player;
	local Vector V;
	local array<string> coordArr;

	Split(Coords, ",", coordArr);
	V.X = float(coordArr[0]);
	V.Y = float(coordArr[1]);
	V.Z = float(coordArr[2]);
	// End:0x122
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'GotoLocation', but that command is disabled in the CENSORED version.");
		goto J0x1E8;
		Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
		Ghost();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1DE
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1BC
		/*@Error*/
	}
	else
	{
		log(,, "Cannot set location");
		goto J0x1DE;
		log(,, __NFUN_168__("GotoLocation", string(V)));
		Walk();
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function GotoActor(name Name)
{
	local bool ActorFound;
	local Actor CurrentActor;
	local ShockPlayer Player;

	// End:0x87
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'GotoActor', but that command is disabled in the CENSORED version.");
		goto J0x1D3;
		ActorFound = false;
	}
	Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D3
	/*@Error*/
	// End:0x13F
	foreach Player.__NFUN_304__(Class'Engine.Actor', CurrentActor)
	{
		// End:0x13E
		if(__NFUN_254__(CurrentActor.Name, Name))
		{
			ActorFound = true;
			// End:0x13F
			break;						
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x19F
			/*@Error*/
			Ghost();
			Player.__NFUN_267__(CurrentActor.Location);
			log(,, __NFUN_168__("GotoActor", string(Name)));
		}
	}
	goto J0x1D3;
	log(,, __NFUN_168__(__NFUN_168__("GotoActor", string(Name)), "- Actor not found"));
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function GotoLabel(name Label)
{
	local bool ActorFound;
	local Actor CurrentActor;
	local ShockPlayer Player;

	// End:0x87
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'GotoLabel', but that command is disabled in the CENSORED version.");
		goto J0x1D3;
		ActorFound = false;
	}
	Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D3
	/*@Error*/
	// End:0x13F
	foreach Player.__NFUN_304__(Class'Engine.Actor', CurrentActor)
	{
		// End:0x13E
		if(__NFUN_254__(CurrentActor.Label, Label))
		{
			ActorFound = true;
			// End:0x13F
			break;						
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x19F
			/*@Error*/
			Ghost();
			Player.__NFUN_267__(CurrentActor.Location);
			log(,, __NFUN_168__("GotoLabel", string(Label)));
		}
	}
	goto J0x1D3;
	log(,, __NFUN_168__(__NFUN_168__("GotoLabel", string(Label)), "- Actor not found"));
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function GotoMap(name MapName)
{
	local bool PathNodeFound, MapFound;
	local PathNode CurrentPathNode;
	local ShockPlayer Player;
	local ZoneInfo CurrentZone;

	// End:0x85
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'GotoMap', but that command is disabled in the CENSORED version.");
		goto J0x243;
		MapFound = false;
	}
	Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x243
	/*@Error*/
	// End:0x13D
	foreach Player.__NFUN_304__(Class'Engine.ZoneInfo', CurrentZone)
	{
		// End:0x13C
		if(__NFUN_254__(CurrentZone.MapUIRegion, MapName))
		{
			MapFound = true;
			// End:0x13D
			break;						
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x212
			/*@Error*/
			Ghost();
			PathNodeFound = false;
			// End:0x1BC
			foreach CurrentZone.__NFUN_308__(Class'Engine.PathNode', CurrentPathNode)
			{
				PathNodeFound = true;
				Player.__NFUN_267__(CurrentPathNode.Location);
			}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x115! */
		}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x0D5! */
		goto J0x1BC;				
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1F2
		/*@Error*/
		Player.__NFUN_267__(CurrentZone.Location);
		log(,, __NFUN_168__("GotoMap", string(MapName)));
		goto J0x243;
		Outer.ClientMessage("Can't find requested map");
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function SetObjectPooling(bool Value)
{
	Outer.Level.ObjectPool.SetObjectPooling(Value);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DumpObjectPoolInfo()
{
	Outer.Level.ObjectPool.DumpObjectPoolInfo();
	return;
	@NULL
	Item
	default.Item
}

function DumpAllContainers(optional Class<Actor> OptionalContainerOwnerClass, optional LootReport LootReport)
{
	local Actor TestActor;
	local Class<Actor> ContainerOwnerClass;
	local Container theContainer;

	log(,, "-----------------------------------------------------------");
	log(,, "-----------------Dumping All Containers--------------------");
	log(,, "-----------------------------------------------------------");
	log(,, "");
	// End:0xFA
	if(__NFUN_114__(OptionalContainerOwnerClass, none))
	{
		ContainerOwnerClass = Class'Engine.Actor';
		goto J0x10D;
		ContainerOwnerClass = OptionalContainerOwnerClass;
		// End:0x247
		foreach Outer.__NFUN_304__(ContainerOwnerClass, TestActor)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x0F9! */
		else
		{
			// End:0x246
			if(__NFUN_119__(IHaveAContainer(TestActor), none))
			{
				theContainer = IHaveAContainer(TestActor).GetContainer();
				// End:0x246
				if(__NFUN_119__(theContainer, none))
				{
					log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("******Dumping Container '", string(theContainer)), "' held by '"), string(TestActor)), "'******"));
					theContainer.DumpContainer(LootReport);
					log(,, "***********************************************************");
					log(,, "");										
					log(,, "-----------------------------------------------------------");
					log(,, "-----------------------------------------------------------");
				}
			}
		}
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x0D5! */
	log(,, "-----------------------------------------------------------");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DumpModsOnPawn(name pawnName)
{
	local ShockPawn TestPawn;

	// End:0x13C
	foreach Outer.__NFUN_304__(Class'ShockGame.ShockPawn', TestPawn)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x13B
		/*@Error*/
		log(,, "-----------------------------------------------------------");
		log(,, __NFUN_112__(__NFUN_112__("-----------------Dumping Mods for ", string(pawnName)), "-----------------------"));
		log(,, "-----------------------------------------------------------");
		TestPawn.DumpMods();				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function DumpAllPickups(optional Class<Actor> OptionalPickupClass, optional LootReport LootReport)
{
	local Actor TestActor;
	local Class<Actor> PickupClass;
	local Pickup thePickup;

	log(,, "-----------------------------------------------------------");
	log(,, "-----------------Dumping All Pickups-----------------------");
	log(,, "-----------------------------------------------------------");
	log(,, "");
	// End:0xFA
	if(__NFUN_114__(OptionalPickupClass, none))
	{
		PickupClass = Class'ShockGame.Pickup';
		goto J0x10D;
		PickupClass = OptionalPickupClass;
		// End:0x20B
		foreach Outer.__NFUN_304__(PickupClass, TestActor)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x0F9! */
		else
		{
			// End:0x20A
			if(__NFUN_119__(Pickup(TestActor), none))
			{
				thePickup = Pickup(TestActor);
				log(,, __NFUN_112__(__NFUN_112__("******Dumping Pickup '", string(thePickup)), "'******"));
				thePickup.DumpPickup(LootReport);
				log(,, "***********************************************************");
				log(,, "");								
				log(,, "-----------------------------------------------------------");
			}
		}
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x0D5! */
	log(,, "-----------------------------------------------------------");
	log(,, "-----------------------------------------------------------");
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ReportLoot()
{
	local LootReport LootReport;

	LootReport = Class'ShockGame.LootReport'.static.Allocate(self).;
	Construct_Void();
	DumpAllContainers(, LootReport);
	DumpAllPickups(, LootReport);
	LootReport.ReportLoot();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function GEP(name PlasmidName)
{
	local bool OldDisableInventoryWarnings;
	local ShockPlayer Player;
	local int EquippedPlasmids;
	local Plasmid.ePlasmidTrack Track;

	// End:0x81
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'GEP', but that command is disabled in the CENSORED version.");
		goto J0x2FC;
		Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	}
	OldDisableInventoryWarnings = Player.disableInventoryWarnings;
	Player.disableInventoryWarnings = true;
	Player.AddAvailablePlasmid(PlasmidName);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x289
	/*@Error*/
	Track = Player.GetTrackForPlasmid(PlasmidName);
	EquippedPlasmids = Player.NumEquippedPlasmids(Track);
	// End:0x211
	if(__NFUN_130__(__NFUN_150__(Player.GetNumTrackSlots(Track), 6), __NFUN_152__(Player.GetNumTrackSlots(Track), EquippedPlasmids)))
	{
		Player.UnlockTrackSlot(Track);
		goto J0x197;
		// End:0x25D
		if(__NFUN_154__(Player.GetNumTrackSlots(Track), 6))
		{
			Player.EquipPlasmid(PlasmidName, 5);
			goto J0x286;
			Player.EquipPlasmid(PlasmidName, EquippedPlasmids);
			goto J0x2DA;
			log(,, __NFUN_112__(__NFUN_112__("GEP command failed because AddAvailablePlasmid(", string(PlasmidName)), ") failed"));
		}
		Player.disableInventoryWarnings = OldDisableInventoryWarnings;
		return;
		@NULL
	}
	Item
	default.Item
	@NULL
}

function FillPlasmids()
{
	local int i, j, numAvailable;
	local name currentPlasmidName;
	local ShockPlayer Player;

	Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	Player.HasReplacedActiveTrack = true;
	Player.HasReceivedActiveTrack = true;
	Player.HasReceivedPhysicalTrack = true;
	Player.HasReceivedEngineeringTrack = true;
	Player.HasReceivedCombatTrack = true;
	Player.HasUnlockedActiveTrack = true;
	Player.HasUnlockedPhysicalTrack = true;
	Player.HasUnlockedEngineeringTrack = true;
	Player.HasUnlockedCombatTrack = true;
	numAvailable = Player.GetNumAvailablePlasmids();
	i = 1;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2A8
	/*@Error*/
	j = 100;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x29A
	/*@Error*/
	currentPlasmidName = Player.GetAvailablePlasmidNameByIndex(__NFUN_167__(numAvailable));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x28C
	/*@Error*/
	Player.EquipPlasmid(currentPlasmidName, Player.NumEquippedPlasmids(byte(i)));
	__NFUN_166__(j);
	// [Loop Continue]
	goto J0x16D;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x151;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function PlayAIAnim(name AnimationName)
{
	local BaseShockAI A;

	// End:0x48
	foreach Outer.__NFUN_313__(Class'ShockGame.BaseShockAI', A)
	{
		A.PlayAnimationOnChannel(5, AnimationName);				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function ToggleShowAIs()
{
	local BaseShockAI A;
	local Actor Attached;
	local int i;

	// End:0x153
	foreach Outer.__NFUN_313__(Class'ShockGame.BaseShockAI', A)
	{
		// End:0x64
		if(__NFUN_180__(A.DrawScale, 0.1000000))
		{
			A.SetDrawScale(1.0000000);
			goto J0x80;
			A.SetDrawScale(0.1000000);
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x152
			/*@Error*/
		}
		Attached = A.Attached[i];
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x144
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x128
		/*@Error*/
		Attached.SetDrawScale(1.0000000);
		goto J0x144;
		Attached.SetDrawScale(0.1000000);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x8B;				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function MGS()
{
	local BaseShockAI Iter;

	// End:0x81
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'MGS', but that command is disabled in the CENSORED version.");
		goto J0x10F;
		// End:0x10E
		foreach Outer.__NFUN_313__(Class'ShockGame.BaseShockAI', Iter)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x079! */
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x10D
		/*@Error*/
		// End:0xF6
		if(Iter.IsStunned())
		{
			Iter.BecomeSaved();
			goto J0x10D;
			Iter.BecomeStunned();						
			return;
			@NULL
			Item
		}
		default.Item
		@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x000! */
}

function MaxAIHealth()
{
	local BaseShockAI Iter;

	// End:0x89
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'MaxAIHealth', but that command is disabled in the CENSORED version.");
		goto J0x145;
		// End:0x10A
		foreach Outer.__NFUN_313__(Class'ShockGame.BaseShockAI', Iter)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x081! */
		// End:0x109
		if(Class'Engine.Pawn'.static.checkAlive(Iter))
		{
			Iter.Health = 1000000.0000000;
			Iter.MaxHealth = 1000000.0000000;						
			SpawningManagerBase(Outer.Level.SpawningManager).MaxOutAIHealth();
			return;
			@NULL
		}
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x000! */
	Item
	default.Item
	@NULL
}

function GiveBioAmmo()
{
	local ShockPlayer Player;

	// End:0x89
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'GiveBioAmmo', but that command is disabled in the CENSORED version.");
		goto J0x114;
		Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	}
	Player.AddBioAmmo(__NFUN_175__(Player.GetMaxBioAmmo(), Player.GetBioAmmo()));
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function GiveHealth()
{
	local ShockPlayer Player;

	// End:0x88
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'GiveHealth', but that command is disabled in the CENSORED version.");
		goto J0x113;
		Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	}
	Player.AddHealth(__NFUN_175__(Player.GetMaxHealth(), Player.GetHealth()));
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TestMeleeHitCamera()
{
	ShockPlayerController(Outer.Level.GetLocalPlayerController()).ReactToDamage('None', none);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function TestPush()
{
	ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn).OnPushed('None', none);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DisableLogQueue()
{
	SoundEffectsSubsystem(EffectsSystem(Outer.Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).DisableCriticalMessagesQueue();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function EnableLogQueue()
{
	SoundEffectsSubsystem(EffectsSystem(Outer.Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).EnableCriticalMessagesQueue();
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function DisableAllFluidVolumes(optional bool DoNotRemoveAllActors)
{
	local FluidVolume CurrentFluidVolume;

	log(,, "Disabling fluid volumes...");
	// End:0x8C
	foreach Outer.__NFUN_304__(Class'Engine.FluidVolume', CurrentFluidVolume)
	{
		log(,, __NFUN_112__("Disabling ", string(CurrentFluidVolume)));
		CurrentFluidVolume.DisableFluidVolume(__NFUN_129__(DoNotRemoveAllActors));				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function EnableAllFluidVolumes()
{
	local FluidVolume CurrentFluidVolume;

	log(,, "Enabling fluid volumes...");
	// End:0x7E
	foreach Outer.__NFUN_304__(Class'Engine.FluidVolume', CurrentFluidVolume)
	{
		log(,, __NFUN_112__("Enabling ", string(CurrentFluidVolume)));
		CurrentFluidVolume.EnableFluidVolume();				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function float GetEyeHeight()
{
	local float EyeHeight;
	local string msg;

	EyeHeight = ShockPlayer(Outer.Pawn).BaseEyeHeight;
	msg = __NFUN_112__("Current eyeheight is ", string(EyeHeight));
	Outer.ClientMessage(msg);
	log(,, msg);
	return EyeHeight;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function SetEyeHeight(float NewEyeHeight)
{
	local string msg;

	// End:0x8A
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'SetEyeHeight', but that command is disabled in the CENSORED version.");
		goto J0x136;
		msg = __NFUN_112__(__NFUN_112__(__NFUN_112__("Eyeheight changed from ", string(GetEyeHeight())), " to "), string(NewEyeHeight));
	}
	Outer.ClientMessage(msg);
	log(,, msg);
	ShockPlayer(Outer.Pawn).BaseEyeHeight = NewEyeHeight;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ResetEyeHeight()
{
	SetEyeHeight(ShockPlayer(Outer.Pawn).default.BaseEyeHeight);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function float GetFOV()
{
	local float FOV;
	local string msg;

	FOV = ShockPlayerController(Outer.Level.GetLocalPlayerController()).DesiredFOV;
	msg = __NFUN_112__("Current FOV is ", string(FOV));
	Outer.ClientMessage(msg);
	log(,, msg);
	return FOV;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function SetFOV(float newFOV)
{
	local string msg;

	// End:0x84
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'SetFOV', but that command is disabled in the CENSORED version.");
		goto J0x138;
		msg = __NFUN_112__(__NFUN_112__(__NFUN_112__("FOV changed from ", string(GetFOV())), " to "), string(newFOV));
	}
	Outer.ClientMessage(msg);
	log(,, msg);
	ShockPlayerController(Outer.Level.GetLocalPlayerController()).DesiredFOV = newFOV;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ResetFOV()
{
	SetFOV(ShockPlayerController(Outer.Level.GetLocalPlayerController()).default.DefaultFOV);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ToggleVisualEffects()
{
	local VisualEffectsSubsystem Subsystem;
	local string EnabledString;

	// End:0xE3
	foreach Outer.__NFUN_304__(Class'IGVisualEffectsSubsystem.VisualEffectsSubsystem', Subsystem)
	{
		Subsystem.DisableTriggering = __NFUN_129__(Subsystem.DisableTriggering);
		// End:0x87
		if(Subsystem.DisableTriggering)
		{
			EnabledString = "DISABLED";
			goto J0x9A;
			EnabledString = "ENABLED";
			Outer.ClientMessage(__NFUN_112__(__NFUN_112__(__NFUN_112__("VisualEffects ", EnabledString), " for "), string(Subsystem)));
		}				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function ToggleSoundEffects()
{
	local SoundEffectsSubsystem Subsystem;
	local string EnabledString;

	// End:0xE2
	foreach Outer.__NFUN_304__(Class'IGSoundEffectsSubsystem.SoundEffectsSubsystem', Subsystem)
	{
		Subsystem.DisableTriggering = __NFUN_129__(Subsystem.DisableTriggering);
		// End:0x87
		if(Subsystem.DisableTriggering)
		{
			EnabledString = "DISABLED";
			goto J0x9A;
			EnabledString = "ENABLED";
			Outer.ClientMessage(__NFUN_112__(__NFUN_112__(__NFUN_112__("SoundEffects ", EnabledString), " for "), string(Subsystem)));
		}				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function AudioBeacon(string Tag)
{
	local ShockPlayer Player;
	local name TagAsName;

	TagAsName = string(Tag);
	Player = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn);
	Outer.ClientMessage(__NFUN_112__(__NFUN_112__(__NFUN_112__("Spawned AudioBeacon with Tag=", string(TagAsName)), " at location "), string(Player.Location)));
	Outer.__NFUN_278__(Class'ShockGame.AudioBeacon',, TagAsName, Player.Location,, true, TagAsName);
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function KillAudioBeacon(string Tag)
{
	local AudioBeacon Beacon;

	// End:0x10D
	foreach Outer.__NFUN_304__(Class'ShockGame.AudioBeacon', Beacon)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x10C
		/*@Error*/
		Beacon.LifeSpan = 0.0010000;
		Outer.ClientMessage(__NFUN_112__(__NFUN_112__(__NFUN_112__("Killed AudioBeacon $with Tag=", string(Beacon.Tag)), " at location "), string(Beacon.Location)));				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function DebugAIAttacking(name AIName)
{
	local BaseShockAI AI;

	// End:0x8B
	foreach Outer.Level.__NFUN_313__(Class'ShockGame.BaseShockAI', AI)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x8A
		/*@Error*/
		AI.bDebugAIAttacking = __NFUN_129__(AI.bDebugAIAttacking);
		// End:0x8B
		break;				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function HelmetOn()
{
	local Head Head;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x178
	/*@Error*/
	Head = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn).GetHead();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x178
	/*@Error*/
	Head.AddPersistentEffectsSystemContext('PlayerHasHelmet');
	Head.TriggerEffectEvent('ScriptTrigger',,,,,,,, 'HelmetActive');
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function HelmetOff()
{
	local Head Head;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x171
	/*@Error*/
	Head = ShockPlayer(Outer.Level.GetLocalPlayerController().Pawn).GetHead();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x171
	/*@Error*/
	Head.UnTriggerEffectEvent('ScriptTrigger', 'HelmetActive');
	Head.RemovePersistentEffectsSystemContext('PlayerHasHelmet');
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function PrintWeaponEffects()
{
	local Weapon FoundWeapon;

	log(,, "PrintWeaponEffects()");
	// End:0xFF
	foreach Outer.__NFUN_313__(Class'ShockGame.Weapon', FoundWeapon)
	{
		log(,, "\n============================================================================\n");
		FoundWeapon.LogOnFiredEffectSpecifications();
		FoundWeapon.LogOnFiredEffectInstances();
		log(,, "");
		FoundWeapon.LogTracerEffectSpecifications();
		FoundWeapon.LogTracerEffectInstances();				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function RecreateWeaponEffects()
{
	local Weapon FoundWeapon;

	// End:0x54
	foreach Outer.__NFUN_313__(Class'ShockGame.Weapon', FoundWeapon)
	{
		FoundWeapon.RespawnOnFiredEmitters();
		FoundWeapon.RespawnTracerEmitters();				
		return;
		@NULL
		Item
		default.Item
		@NULL
	}
}

function BotEnterTestMode(name BotLabel)
{
	// End:0x8E
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'BotEnterTestMode', but that command is disabled in the CENSORED version.");
		goto J0xD1;
		SpawningManagerBase(Outer.Level.SpawningManager).BotEnterTestMode(BotLabel);
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function BotGoToLocation(name ActorLocationLabel)
{
	// End:0x8D
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'BotGoToLocation', but that command is disabled in the CENSORED version.");
		goto J0xD0;
		SpawningManagerBase(Outer.Level.SpawningManager).BotGoToLocation(ActorLocationLabel);
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function BotFakeAttackPawn(name PawnLabel)
{
	// End:0x8F
	if(IsCensoredContent())
	{
		AssertWithDescription(false, "BUG THIS: Attempted to execute function 'BotFakeAttackPawn', but that command is disabled in the CENSORED version.");
		goto J0xD2;
		SpawningManagerBase(Outer.Level.SpawningManager).BotFakeAttackPawn(PawnLabel);
	}
	return;
	@NULL
	Item
	default.Item
	@NULL
}

defaultproperties
{
	WeaponName[0]="ShockGame.Wrench"
	WeaponName[1]="ShockGame.Pistol"
	WeaponName[2]="ShockGame.Shotgun"
	WeaponName[3]="ShockGame.Crossbow"
	WeaponName[4]="ShockGame.GrenadeLauncher"
	WeaponName[5]="ShockGame.MachineGun"
	WeaponName[6]="ShockGame.ChemicalThrower"
	WeaponName[7]="ShockGame.ResearchCamera"
	ItemName[0]="ShockGame.Pistol_Bullet"
	ItemName[1]="ShockGame.Pistol_AntiPersonnel"
	ItemName[2]="ShockGame.Pistol_ArmorPiercing"
	ItemName[3]="ShockGame.Shotgun_00Buck"
	ItemName[4]="ShockGame.Shotgun_IonicBuck"
	ItemName[5]="ShockGame.Shotgun_HighExplosiveBuck"
	ItemName[6]="ShockGame.Crossbow_Bolt"
	ItemName[7]="ShockGame.Crossbow_SuperHeatedBolt"
	ItemName[8]="ShockGame.Crossbow_TrapBolt"
	ItemName[9]="ShockGame.ChemicalThrower_Kerosene"
	ItemName[10]="ShockGame.ChemicalThrower_IonicGel"
	ItemName[11]="ShockGame.ChemicalThrower_LiquidNitrogen"
	ItemName[12]="ShockGame.GrenadeLauncher_FragGrenade"
	ItemName[13]="ShockGame.GrenadeLauncher_StickyGrenade"
	ItemName[14]="ShockGame.GrenadeLauncher_RPG"
	ItemName[15]="ShockGame.Film"
	ItemName[16]="ShockGame.MachineGun_Bullet"
	ItemName[17]="ShockGame.MachineGun_FrozenBullet"
	ItemName[18]="ShockGame.MachineGun_ArmorPiercingBullet"
	ItemName[19]="ShockDesignerClasses.MedHypo"
	ItemName[20]="ShockDesignerClasses.BioAmmoHypo"
}