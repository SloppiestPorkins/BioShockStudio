class DoorButtonControl extends DoorAccessControl implements ICanBeUsed
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Force,LightColor,Lighting,Object,Sound);

var(Door) private bool bOpenDoorAutomatically;
var private config localized string FriendlyName;
var private config localized string UseVerbText;

function PreBeginPlay()
{
	super.PreBeginPlay();
	log('Doors', 4, __NFUN_112__(string(self), "---DoorButtonControl::PreBeginPlay()."));
	TheDoor.SetIsButtonDoor();
	SetDrawType(2);
	return;
	@NULL
	Item
	Item
}

function bool CanBeUsedNow()
{
	return true;
	return;
}

function bool GetRequiredPlacementForUse(out Vector WorldSpaceLocation, out Rotator WorldSpaceRotation)
{
	return false;
	return;
}

function OnUsed(Pawn Pawn)
{
	log('Doors', 4, __NFUN_112__(string(self), "---DoorButtonControl::OnUsed()"));
	// End:0xA3
	if(TheDoor.isIdle())
	{
		// End:0x66
		if(bOpenDoorAutomatically)
		{
			OpenDoor();
			dispatchMessage(Class'ShockGame.MessageDoorButtonPressed'.static.Allocate(self)., construct_Name(DoorLabel));
		}
		goto J0xF8;
		log('Doors', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), " pressed but "), string(TheDoor)), " is not idle."));
	}
	TriggerEffectEvent('ButtonPressedWhileBusy');
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
	// End:0x13
	if(CanBeUsedNow())
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

function OpenDoor()
{
	log('Doors', 4, __NFUN_112__(string(self), "---DoorButtonControl::OpenDoor()"));
	TheDoor.Open();
	TriggerEffectEvent('ButtonPressedSucceeded');
	return;
	@NULL
}

defaultproperties
{
	FriendlyName="Button"
	UseVerbText="PRESS"
	DrawType=8
	StaticMesh=StaticMesh'ShockGame.SimpleShapes.Cube256Diameter'
}