class DoorKeypadControl extends DoorAccessControl implements ICanBeUsed, ICanBeHacked, IHandleMovieEvents
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Force,LightColor,Lighting,Object,Sound);

var(Hacking) private name HackInfoName;
var transient HackInfo HackingGameSetupInfo;
var private config localized string HackingSuccessFeedbackText;
var(movie) name movie;
var private config localized string FriendlyName;
var private config localized string UseVerbText;
var private bool bIsHacked;
var private config bool bHackable;
var private config localized string KeypadFailureText;

function PreBeginPlay()
{
	super.PreBeginPlay();
	log('Doors', 4, __NFUN_112__(string(self), "---DoorKeypadControl::PreBeginPlay()."));
	Level.GetFlashLiaison().RegisterForMovieEvent(self, 'SelectedValue');
	Level.GetFlashLiaison().RegisterForMovieEvent(self, 'CancelKeypad');
	Level.GetFlashLiaison().RegisterForMovieEvent(self, 'HackResult');
	TheDoor.LockWithoutEffectEvents();
	return;
	@NULL
	Item
	Item
	@NULL
}

function PostLoadGame()
{
	super(Actor).PostLoadGame();
	Level.GetFlashLiaison().RegisterForMovieEvent(self, 'SelectedValue');
	Level.GetFlashLiaison().RegisterForMovieEvent(self, 'CancelKeypad');
	Level.GetFlashLiaison().RegisterForMovieEvent(self, 'HackResult');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function Destroyed()
{
	Level.GetFlashLiaison().UnRegisterForAllMovieEvents(self);
	super(Actor).Destroyed();
	return;
	@NULL
	Item
}

function string GetHackVerbText()
{
	return "HACK";
	return;
}

function bool CanBeHackedNow(ShockPlayer Player)
{
	return __NFUN_130__(TheDoor.IsLocked(), bHackable);
	return;
	@NULL
	Item
}

function OnHackAttempted(ShockPlayer Player)
{
	Player.OnStartHacking(GetHackInfo(), self);
	Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodString("SetHackDescription", HackingSuccessFeedbackText);
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool IsHacked()
{
	return bIsHacked;
	return;
	@NULL
}

function HackInfo GetHackInfo()
{
	// End:0x4C
	if(__NFUN_114__(HackingGameSetupInfo, none))
	{
		HackingGameSetupInfo = Class'ShockGame.HackInfo'.static.Allocate(self,, string(HackInfoName)).;
		Construct_Void();
		return HackingGameSetupInfo;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	log('DoorKeypadControl', 3, __NFUN_112__(string(self), ": Hack attempt SUCCEEDED"));
	KeypadUsed(true);
	TriggerEffectEvent('HackSucceeded');
	bIsHacked = true;
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
	log('DoorKeypadControl', 3, __NFUN_112__(string(self), ": Hack attempt FAILED"));
	TriggerEffectEvent('HackFailed');
	return GetHackInfo();
	return;
}

function bool CanBeUsedNow()
{
	return TheDoor.IsLocked();
	return;
	@NULL
}

function bool GetRequiredPlacementForUse(out Vector WorldSpaceLocation, out Rotator WorldSpaceRotation)
{
	return false;
	return;
}

function OnUsed(Pawn Pawn)
{
	log('Doors', 4, __NFUN_112__(string(self), "---DoorKeypadControl::OnUsed()."));
	Level.GetLocalPlayerController().SetPause(true);
	Level.GetFlashGUIController().PlayMovie(movie);
	Level.GetFlashGUIController().GetPlayingMovie(movie).CallMethodInt("SetHacked", int(__NFUN_129__(bHackable)));
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnUseStopped(Pawn Pawn)
{
	return;
}

function string GetUseVerbText()
{
	return UseVerbText;
	return;
	@NULL
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

function OnMovieEvent(name Event, MovieEventData Data)
{
	local string KeycodeEntered, HackResult;

	// End:0x36
	if(__NFUN_119__(ShockPlayerController(Level.GetLocalPlayerController()).GetCurrentUsedObject(), self))
	{
		return;
		log('Doors', 4, __NFUN_112__(__NFUN_112__(string(self), "---DoorKeypadControl::OnMovieEvent(). Event="), string(Event)));
	}
	switch(Event)
	{
		// End:0x181
		case 'SelectedValue':
			KeycodeEntered = Data.GetValue('Keys');
			log('Doors',, __NFUN_112__(__NFUN_112__(string(self), ": keycode entered. Keys="), KeycodeEntered));
			dispatchMessage(Class'ShockGame.MessageDoorKeypadUsed'.static.Allocate(self)., construct_StrName(KeycodeEntered, Actor(ShockPlayerController(Level.GetLocalPlayerController()).GetCurrentUseFocus()).Label));
			// End:0x1EC
			break;
			// End:0x190
			case 'CancelKeypad':
				// End:0x1EC
				break;
				// End:0x1E5
				case 'HackResult':
					HackResult = Data.GetValue('Value');
				// End:0x1E2
				if(__NFUN_122__(HackResult, "1"))
				{
					KeypadUsed(true);/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x182! */
				// End:0x1EC
				break;
				// End:0xFFFF
				default:
					assert(false);
					Level.GetLocalPlayerController().SetPause(false);
					Level.GetFlashGUIController().StopMovie(movie);
					break;/* Tried to find Switch scope, found Case instead */
			}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x145! */
			return;
		@NULL
		Item
	}
	Item
	@NULL
}

function KeypadUsed(bool Success)
{
	log('Doors', 4, __NFUN_112__(__NFUN_112__(string(self), "---DoorKeypadControl::KeypadUsed(). Success="), string(Success)));
	// End:0x8B
	if(Success)
	{
		TriggerEffectEvent('KeypadSucceeded');
		TheDoor.unlock();
		goto J0xD5;
		Level.GetLocalPlayerController().ClientMessage(KeypadFailureText, 'Warning');
	}
	TriggerEffectEvent('KeypadFailed');
	return;
	@NULL
	Item
	Item
	@NULL
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

defaultproperties
{
	HackInfoName="KeypadDefault"
	HackingSuccessFeedbackText="Successfully hacking this door will unlock it."
	movie="ComboLock"
	FriendlyName="Keypad"
	UseVerbText="ENTER CODE"
	bHackable=true
	KeypadFailureText="Incorrect code entered."
	DrawType=8
	StaticMesh=StaticMesh'ShockGame.MA_ComboLock.ComboLock'
}