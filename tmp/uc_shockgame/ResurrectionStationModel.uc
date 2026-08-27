class ResurrectionStationModel extends ResurrectionStationAttachment implements ICanBeUsed
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Force,LightColor,Lighting,Object,Sound);

var private bool bIsADoor;

function SetDoorFlag(bool DoorFlag)
{
	bIsADoor = DoorFlag;
	return;
	@NULL
	Item
}

function bool IsADoor()
{
	return bIsADoor;
	return;
	@NULL
}

// Export UResurrectionStationModel::execDestroyAttachments(FFrame&, void* const)
native function DestroyAttachments();

function Attach(Actor Other)
{
	OwnerStation.OnActorAttached(self, Other);
	return;
	@NULL
	Item
}

function bool CanBeUsedNow()
{
	return OwnerStation.CanBeUsedNow(self);
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
	OwnerStation.OnUsed(Pawn, self);
	return;
	@NULL
	Item
}

function OnUseStopped(Pawn Pawn)
{
	return;
}

function string GetUseVerbText()
{
	return OwnerStation.GetUseVerbText(self);
	return;
	@NULL
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

function bool CanBeFocusedNow()
{
	return OwnerStation.CanBeFocusedNow(self);
	return;
	@NULL
}

function string GetFocusDisplayName()
{
	return OwnerStation.GetFocusDisplayName(self);
	return;
	@NULL
}

function string GetHUDMessageForFocusAttained()
{
	return OwnerStation.GetHUDMessageForFocusAttained(self);
	return;
	@NULL
}

function bool ShouldHighlightWhenFocused()
{
	return OwnerStation.ShouldHighlightWhenFocused(self);
	return;
	@NULL
}

function bool ShouldShowHelpTagWhenFocused()
{
	return OwnerStation.ShouldShowHelpTagWhenFocused(self);
	return;
	@NULL
}

function OnFocusStarted()
{
	OwnerStation.OnFocusStarted(self);
	return;
	@NULL
}

function OnFocusStopped()
{
	OwnerStation.OnFocusStopped(self);
	return;
	@NULL
}

defaultproperties
{
	bOccludesSound=true
	bUpdateAudioOcclusionWhenMoving=true
	bCollideActors=true
	bBlockActors=true
	bBlockPlayers=true
	bBlockHavok=true
}