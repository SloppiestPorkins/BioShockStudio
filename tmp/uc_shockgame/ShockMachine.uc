class ShockMachine extends Actor implements ICanBeUsed, ICanBeHacked, IPoweredByFuse
	abstract
	native
	config(Machines)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

const UNLIMITED_USE = -1;

enum CostGrowth
{
	CG_Add,                         // 0
	CG_Multiply                     // 1
};

var(Machine) private edfindable FuseBox FuseBox;
var(Machine) private float InitialCost;
var(Machine) private float CostIncreaseFactor;
var(Machine) ShockMachine.CostGrowth CostIncreaseFunction;
var(Machine) private int MaxUses;
var(Machine) private float HackedCostModifier;
var(Machine) private string PlayerStandSocketName;
var(Machine) bool bCanBeUsed;
var(Hacking) private name HackInfoName;
var(Hacking) private bool HackPurchaseOptionEnabled;
var(Hacking) bool bCanBeHacked;
var transient HackInfo HackingGameSetupInfo;
var private config localized string HackingSuccessFeedbackText;
var(HUDDisplay) private config localized string FriendlyName;
var(HUDDisplay) private config localized string UseVerbText;
var private config localized string UsedFeedbackTextNoFuse;
var private config localized string UsedFeedbackTextDormant;
var private config localized string UsedFeedbackTextInsufficientCredits;
var private config localized string DormantFriendlyName;
var private config name AnimWaitingStarted;
var private config name AnimWaitingLoop;
var private config name AnimWaitingEnded;
var private config name AnimInteractionStarted;
var private config name AnimInteractionLoop;
var private config name AnimInteractionEnded;
var private config name AnimDormancyStarted;
var private config name AnimDormancyLoop;
var private config name AnimDormancyEnded;
var private int NumTimesUsed;
var private bool bIsHacked;
var private ShockPlayer CurrentPlayer;
var private bool CachedPlayerInvincibilityValue;
var bool ScriptDisabled;

function PreBeginPlay()
{
	super.PreBeginPlay();
	return;
	@NULL
}

function PostBeginPlay()
{
	log('Machines', 5, __NFUN_112__(string(self), ".PostBeginPlay()"));
	InitialState = 'Waiting';
	super.PostBeginPlay();
	return;
	@NULL
	Item
}

function Destroyed()
{
	log('Machines', 5, __NFUN_112__(string(self), ".Destroyed()"));
	super.Destroyed();
	return;
	@NULL
}

function SendFeedbackToHUD(string FeedbackText)
{
	log('Machines', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), ":SendFeedbackToHUD("), FeedbackText), ")"));
	Level.GetLocalPlayerController().ClientMessage(FeedbackText, 'Feedback');
	return;
	@NULL
	Freebie
	DifficultyAdjustment
	@NULL
}

function bool CanBeUsedNow()
{
	return bCanBeUsed;
	return;
	@NULL
}

function bool GetRequiredPlacementForUse(out Vector WorldSpaceLocation, out Rotator WorldSpaceRotation)
{
	local Vector DummyScale;

	return getSocket(PlayerStandSocketName, WorldSpaceLocation, WorldSpaceRotation, DummyScale, 0);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnUsed(Pawn Pawn)
{
	log('Machines', 3, __NFUN_112__(__NFUN_112__(string(self), ": Player initiating use of machine that is in state "), string(__NFUN_284__())));
	OnPlayerTriedToInteract(ShockPlayer(Pawn));
	return;
	@NULL
	Freebie
	DifficultyAdjustment
}

function OnUseStopped(Pawn Pawn)
{
	return;
}

function string GetUseVerbText()
{
	local string VerbPlusCost;

	// End:0x5B
	if(__NFUN_151__(int(GetCostToUse()), 0))
	{
		VerbPlusCost = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(UseVerbText, " ("), string(int(GetCostToUse()))), Class'ShockGame.FlashStrings'.default.CreditsString), ")");
		goto J0x6E;
		VerbPlusCost = UseVerbText;
		return VerbPlusCost;
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	// End:0x23
	if(__NFUN_132__(CanBeUsedNow(), CanBeHackedNow(none)))
	{
		return 1;		
	}
	else
	{
		return 0;
	}
	return;
}

function bool ActionBlockedByPawns()
{
	return true;
	return;
}

function float GetUseDistance()
{
	return 0.0000000;
	return;
}

function bool CanBeFocusedNow()
{
	return true;
	return;
}

function string GetFocusDisplayName()
{
	return FriendlyName;
	return;
	@NULL
}

function string GetHUDMessageForFocusAttained()
{
	return GetFocusDisplayName();
	return;
}

function bool ShouldHighlightWhenFocused()
{
	return CanBeUsedNow();
	return;
}

function bool ShouldShowHelpTagWhenFocused()
{
	return true;
	return;
}

function OnFocusStarted()
{
	TriggerEffectEvent('BecameUseFocus');
	return;
}

function OnFocusStopped()
{
	UnTriggerEffectEvent('BecameUseFocus');
	return;
}

function OnPlayerTriedToInteract(ShockPlayer thePlayer)
{
	local name CannotInteractEffectEventContext;
	local string CannotInteractHUDFeedbackString;

	// End:0x87
	if(CanBeInteractedWith(thePlayer, CannotInteractHUDFeedbackString, CannotInteractEffectEventContext))
	{
		log('Machines', 3, __NFUN_112__(string(self), ": Player began interaction with machine"));
		CurrentPlayer = thePlayer;
		__NFUN_113__('Interacting');
		goto J0x167;
		log('Machines', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), ": Player cannot interact with machine: Reason='"), CannotInteractHUDFeedbackString), "' EffectEventContext='"), string(CannotInteractEffectEventContext)), "'"));
	}
	// End:0x128
	if(__NFUN_151__(__NFUN_125__(CannotInteractHUDFeedbackString), 0))
	{
		SendFeedbackToHUD(CannotInteractHUDFeedbackString);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x165
		/*@Error*/
		AddContextForNextEffectEvent(CannotInteractEffectEventContext);
		TriggerEffectEvent('UnableToInteract');
	}
	return;
	return;
	@NULL
	Freebie
	DifficultyAdjustment
	@NULL
}

function bool CanBeInteractedWith(ShockPlayer thePlayer, out string CannotInteractHUDFeedbackString, out name CannotInteractEffectEventContext)
{
	local float PlayerFunds, MachineCost;

	PlayerFunds = float(thePlayer.GetCredits());
	MachineCost = GetCostToUse();
	AssertWithDescription(__NFUN_255__(__NFUN_284__(), 'None'), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), ": CanBeInteractedWith was called from the base state this should never happen. "), "HasPower="), string(HasPower())));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x176
	/*@Error*/
	log('Machines', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), ": User tried to use machine but had too few credits (Had: "), string(PlayerFunds)), " Needed:"), string(MachineCost)));
	CannotInteractHUDFeedbackString = UsedFeedbackTextInsufficientCredits;
	CannotInteractEffectEventContext = 'InsufficientCredits';
	return false;
	return true;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function bool IsHacked()
{
	return bIsHacked;
	return;
	@NULL
}

function string GetHackVerbText()
{
	return "HACK";
	return;
}

function bool CanBeHackedNow(ShockPlayer Player)
{
	return __NFUN_130__(__NFUN_129__(bIsHacked), bCanBeHacked);
	return;
	@NULL
	Item
}

function HackInfo GetHackInfo()
{
	// End:0x4C
	if(__NFUN_114__(HackingGameSetupInfo, none))
	{
		HackingGameSetupInfo = Class'ShockGame.HackInfo'.static.Allocate(self,, string(HackInfoName)).;
		Construct_Void();
		HackingGameSetupInfo.HackPurchaseOptionEnabled = HackPurchaseOptionEnabled;
	}
	return HackingGameSetupInfo;
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnHackAttempted(ShockPlayer Player)
{
	log('Machines', 3, __NFUN_112__(__NFUN_112__(string(self), ": Player attempting hack of machine that is in state "), string(__NFUN_284__())));
	Player.OnStartHacking(GetHackInfo(), self);
	Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodString("SetHackDescription", HackingSuccessFeedbackText);
	return;
	@NULL
	Freebie
	stop;
	default.@NULL
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	bIsHacked = true;
	log('ShockMachine', 3, __NFUN_112__(string(self), ": Hack attempt SUCCEEDED"));
	TriggerEffectEvent('HackSucceeded');
	Level.GetLocalPlayerController().ClientMessage(HackingSuccessFeedbackText, 'HackingSuccess');
	return GetHackInfo();
	return;
	@NULL
	Item
	Item
	@NULL
}

function HackInfo OnHackFailed(ShockPlayer Player, string HackResult)
{
	log('ShockMachine', 3, __NFUN_112__(string(self), ": Hack attempt FAILED"));
	TriggerEffectEvent('HackFailed');
	return GetHackInfo();
	return;
}

function float GetCostToUse()
{
	local float cost;
	local int i;

	// End:0x42
	if(__NFUN_154__(int(CostIncreaseFunction), int(0)))
	{
		cost = __NFUN_174__(InitialCost, __NFUN_171__(float(NumTimesUsed), CostIncreaseFactor));
		goto J0xC6;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC2
		/*@Error*/
		cost = __NFUN_245__(1.0000000, InitialCost);
	}
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBF
	/*@Error*/
	__NFUN_184__(cost, __NFUN_171__(cost, CostIncreaseFactor));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x7B;
	goto J0xC6;
	assert(false);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE7
	/*@Error*/
	__NFUN_182__(cost, HackedCostModifier);
	return cost;
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool HasPower()
{
	return __NFUN_132__(__NFUN_114__(FuseBox, none), FuseBox.HasFuse());
	return;
	@NULL
	Freebie
}

function bool HasUsesRemaining()
{
	return __NFUN_132__(__NFUN_150__(NumTimesUsed, MaxUses), __NFUN_154__(MaxUses, -1));
	return;
	@NULL
	Freebie
	Item
}

function FuseBox GetFuseBox()
{
	return FuseBox;
	return;
	@NULL
}

protected function OnFuseBlown()
{
	return;
}

protected function OnFuseReplaced()
{
	return;
}

event FinishInteraction(bool SuccessfullyCompleted)
{
	return;
}

function BeginInteractingStateVisualEffects()
{
	FinishAnimation(GetAnimationOnChannel(0));
	TriggerEffectEvent('Interacting');
	FinishAnimation(PlayAnimationOnChannel(0, AnimInteractionStarted));
	PlayAnimationOnChannel(0, AnimInteractionLoop, 8);
	return;
	@NULL
	Collectable
	DifficultyAdjustment
	@NULL
}

function EndInteractingStateVisualEffects()
{
	PlayAnimationOnChannel(0, AnimInteractionEnded);
	UnTriggerEffectEvent('Interacting');
	return;
	@NULL
	Item
}

function AllHackInfoNames(LevelInfo Level, out array<name> S)
{
	local int i;
	local HackInfoList HackInfoList;

	HackInfoList = Class'ShockGame.HackInfoList'.static.Allocate(self).;
	Construct_Void();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA3
	/*@Error*/
	S[i] = HackInfoList.HackInfoName[i];
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x3C;
	HackInfoList.__NFUN_200__();
	return;
	@NULL
	Item
	Item
	@NULL
}

function AllConcreteItemClasses(LevelInfo Level, out array< Class<Item> > S)
{
	//native.Level;
	//native.S;	
	@NULL
	@NULL
}

function string DisplayClassAsClassName(Class<Item> theItem)
{
	local string displayString;

	// End:0x4D
	if(__NFUN_258__(theItem, Class'ShockGame.Ammunition'))
	{
		displayString = __NFUN_112__("Ammunition: ", string(theItem.Name));
		goto J0x46E;
		// End:0x9D
		if(__NFUN_258__(theItem, Class'ShockGame.ActivePlasmid'))
		{
			displayString = __NFUN_112__("ActivePlasmid: ", string(theItem.Name));
		}
		goto J0x46E;
		// End:0xEE
		if(__NFUN_258__(theItem, Class'ShockGame.EcologyPlasmid'))
		{
			displayString = __NFUN_112__("EcologyPlasmid: ", string(theItem.Name));
		}
		goto J0x46E;
		// End:0x143
		if(__NFUN_258__(theItem, Class'ShockGame.EngineeringPlasmid'))
		{
			displayString = __NFUN_112__("EngineeringPlasmid: ", string(theItem.Name));
		}
		goto J0x46E;
		// End:0x195
		if(__NFUN_258__(theItem, Class'ShockGame.PhysicalPlasmid'))
		{
			displayString = __NFUN_112__("PhysicalPlasmid: ", string(theItem.Name));
			goto J0x46E;
			// End:0x1E5
			if(__NFUN_258__(theItem, Class'ShockGame.WeaponPlasmid'))
			{
				displayString = __NFUN_112__("WeaponPlasmid: ", string(theItem.Name));
			}
			goto J0x46E;
			// End:0x22F
			if(__NFUN_258__(theItem, Class'ShockGame.Plasmid'))
			{
				displayString = __NFUN_112__("Plasmid: ", string(theItem.Name));
			}
			goto J0x46E;
			// End:0x276
			if(__NFUN_258__(theItem, Class'ShockGame.Hypo'))
			{
				displayString = __NFUN_112__("Hypo: ", string(theItem.Name));
				goto J0x46E;
				// End:0x2C3
				if(__NFUN_258__(theItem, Class'ShockGame.Ammunition'))
				{
				}
				displayString = __NFUN_112__("Ammunition: ", string(theItem.Name));
				goto J0x46E;
				// End:0x30D
				if(__NFUN_258__(theItem, Class'ShockGame.CraftingFormula'))
				{
					displayString = __NFUN_112__("Formula: ", string(theItem.Name));
				}
				goto J0x46E;
				// End:0x358
				if(__NFUN_258__(theItem, Class'ShockGame.QuestLog'))
				{
					displayString = __NFUN_112__("QuestLog: ", string(theItem.Name));
				}
				goto J0x46E;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x3A6
				/*@Error*/
				displayString = __NFUN_112__("Collectable: ", string(theItem.Name));
				goto J0x46E;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x3F3
				/*@Error*/
			}
			displayString = __NFUN_112__("Consumable: ", string(theItem.Name));
			goto J0x46E;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x43D
			/*@Error*/
			displayString = __NFUN_112__("Freebie: ", string(theItem.Name));
		}
		goto J0x46E;
		displayString = __NFUN_112__("Inventory: ", string(theItem.Name));
		return displayString;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

state Waiting
{
	ignores EndState;

	function BeginState()
	{
		log('Machines', 5, __NFUN_112__(__NFUN_112__(string(self), ": BeginState() of "), string(__NFUN_284__())));
		return;
	}

	protected function OnFuseBlown()
	{
		log('Machines', 4, __NFUN_112__(string(self), ": Machine entring dormancy due to blown fuse."));
		__NFUN_113__('Dormant');
		return;
	}

	latent function BeginWaiting()
	{
		return;
	}
Begin:

	log('Machines', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), ": Beginning code for state "), string(__NFUN_284__())), ""));
	// End:0x96
	if(__NFUN_129__(HasPower()))
	{
		log('Machines', 3, __NFUN_112__(string(self), ": Machine has no power, going dormant"));
		__NFUN_113__('Dormant');
		goto J0xFA;
		// End:0xFA
		if(__NFUN_129__(HasUsesRemaining()))
		{
		}
		log('Machines', 3, __NFUN_112__(string(self), ": Machine has no more uses remaining, going dormant"));
		__NFUN_113__('Dormant');
		FinishAnimation(GetAnimationOnChannel(0));
	}
	TriggerEffectEvent('Waiting');
	FinishAnimation(PlayAnimationOnChannel(0, AnimWaitingStarted));
	PlayAnimationOnChannel(0, AnimWaitingLoop, 8);
	BeginWaiting();
	stop;			
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state Interacting
{
	ignores FinishInteraction, CanBeInteractedWith, EndState, BeginState;

	protected function OnFuseBlown()
	{
		log('Machines', 4, __NFUN_112__(string(self), ": Machine interaction failed due to blown fuse."));
		FinishInteraction(false);
		return;
	}

	protected function OnInteractionSucceeded()
	{
		return;
	}

	protected function OnInteractionFailed()
	{
		return;
	}

	protected latent function BeginInteracting()
	{
		return;
	}
Begin:

	log('Machines', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), ": Beginning code for state "), string(__NFUN_284__())), ""));
	BeginInteractingStateVisualEffects();
	CurrentPlayer.OnStartedInteractingWithMachine(self);
	BeginInteracting();
	stop;		
	@NULL
}

state Dormant
{
	ignores GetFocusDisplayName, OnFuseReplaced, FinishDormancy, CanBeInteractedWith;

	function BeginState()
	{
		log('Machines', 5, __NFUN_112__(__NFUN_112__(string(self), ": BeginState() of "), string(__NFUN_284__())));
		return;
	}

	function EndState()
	{
		log('Machines', 5, __NFUN_112__(__NFUN_112__(string(self), ": EndState() of "), string(__NFUN_284__())));
		UnTriggerEffectEvent('Dormant');
		return;
	}

	protected function OnDormancyFinished()
	{
		return;
	}

	protected latent function BeginDormancy()
	{
		return;
	}

	function bool CanBeHackedNow(ShockPlayer Player)
	{
		return false;
		return;
	}

	function bool CanBeUsedNow()
	{
		return false;
		return;
	}

	function IPotentialAimOrActionTarget.TargetType GetTargetType()
	{
		return 0;
		return;
	}
Begin:

	log('Machines', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), ": Beginning code for state "), string(__NFUN_284__())), ""));
	FinishAnimation(GetAnimationOnChannel(0));
	TriggerEffectEvent('Dormant');
	PlayAnimationOnChannel(0, AnimDormancyStarted);
	FinishAnimation(GetAnimationOnChannel(0));
	PlayAnimationOnChannel(0, AnimDormancyLoop, 8);
	BeginDormancy();
	stop;	
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
	Holdable
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	MaxUses=-1
	HackedCostModifier=1.0000000
	bCanBeUsed=true
	HackInfoName="MachineDefault"
	HackPurchaseOptionEnabled=true
	bCanBeHacked=true
	HackingSuccessFeedbackText="Hack successful"
	FriendlyName="machine"
	UseVerbText="ACTIVATE"
	UsedFeedbackTextDormant="You have already used this machine. It cannot be used again."
	UsedFeedbackTextInsufficientCredits="Not enough money"
	DrawType=2
	bForceStaticLighting=true
	bStasis=true
	bWorldGeometry=true
	bAcceptsProjectors=true
	bInGameRenderable=true
	Mesh=SkeletalMesh'SimpleAnim.SimpleAnim'
	bCastStaticShadow=true
	bCollideActors=true
	bBlockActors=true
	bBlockPlayers=true
	bBlockHavok=true
	bPathColliding=true
	bTriggerEffectEventsBeforeGameStarts=true
	bNeedLifetimeEffectEvents=true
	bNeedPressureChangeEffectEvents=true
	HelpTag="Machines"
	ActorSpecificTextureWeight=7.0000000
}