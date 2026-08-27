class FuseBox extends Actor implements ICanBeUsed
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var private localized string FriendlyName;
var private localized string UseVerbText;
var bool bHasFuse;
var bool bCanReplaceFuse;
var private name FuseSocket;
var private Class<Actor> FuseClass;
var private Actor FuseModel;

function PreBeginPlay()
{
	super.PreBeginPlay();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDF
	/*@Error*/
	FuseModel = __NFUN_278__(FuseClass);
	AssertWithDescription(__NFUN_119__(FuseModel, none), __NFUN_112__(__NFUN_112__(string(self), " ... unable to spawn fuse model of class: "), string(FuseClass)));
	AttachToBone(FuseModel, FuseSocket);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDF
	/*@Error*/
	FuseModel.SetHidden(true);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xFF
	/*@Error*/
	TriggerEffectEvent('FuseBoxPowered');
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool HasFuse()
{
	return bHasFuse;
	return;
	@NULL
}

function bool CanReplaceFuse()
{
	return __NFUN_130__(__NFUN_129__(HasFuse()), bCanReplaceFuse);
	return;
	@NULL
}

function ReplaceFuse()
{
	AssertWithDescription(CanReplaceFuse(), __NFUN_112__(__NFUN_112__("Attempted to replaceFuse() in ", string(self)), ", but the player cannot replace a fuse at this time."));
	bHasFuse = true;
	// End:0xA4
	if(__NFUN_119__(FuseModel, none))
	{
		FuseModel.SetHidden(false);
		OnFuseReplaced();
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function BlowFuse()
{
	AssertWithDescription(bHasFuse, __NFUN_112__(__NFUN_112__("Attempted to BlowFuse() in ", string(self)), ", but there is no fuse to blow."));
	bHasFuse = false;
	// End:0x8C
	if(__NFUN_119__(FuseModel, none))
	{
		FuseModel.SetHidden(true);
		OnFuseBlown();
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function OnFuseReplaced()
{
	local Actor Test;
	local IPoweredByFuse Powered;

	// End:0x89
	foreach __NFUN_313__(Class'Engine.Actor', Test)
	{
		// End:0x88
		if(__NFUN_119__(Test, none))
		{
			Powered = IPoweredByFuse(Test);
			// End:0x88
			if(__NFUN_130__(__NFUN_119__(Powered, none), __NFUN_114__(Powered.GetFuseBox(), self)))
			{
				Powered.OnFuseReplaced();								
				dispatchMessage(Class'ShockGame.MessageFuseReplaced'.static.Allocate(self)., construct_Name(Label));
			}
		}
	}
	TriggerEffectEvent('FuseReplaced');
	TriggerEffectEvent('FuseBoxPowered');
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnFuseBlown()
{
	local Actor Test;
	local IPoweredByFuse Powered;

	// End:0x89
	foreach __NFUN_304__(Class'Engine.Actor', Test)
	{
		// End:0x43
		if(__NFUN_119__(Test, none))
		{
			Powered = IPoweredByFuse(Test);
			// End:0x88
			if(__NFUN_130__(__NFUN_119__(Powered, none), __NFUN_114__(Powered.GetFuseBox(), self)))
			{
			}
			Powered.OnFuseBlown();						
			dispatchMessage(Class'ShockGame.MessageFuseBlown'.static.Allocate(self)., construct_Name(Label));
		}
	}
	TriggerEffectEvent('FuseBlown');
	UnTriggerEffectEvent('FuseBoxPowered');
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool CanBeUsedNow()
{
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	assert(__NFUN_119__(thePlayer, none));
	return __NFUN_130__(CanReplaceFuse(), __NFUN_151__(thePlayer.GetNumberOfItems(Class'ShockGame.Battery'), 0));
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool GetRequiredPlacementForUse(out Vector WorldSpaceLocation, out Rotator WorldSpaceRotation)
{
	return false;
	return;
}

function OnUsed(Pawn Pawn)
{
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Pawn);
	assert(__NFUN_119__(thePlayer, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7C
	/*@Error*/
	thePlayer.UseUpItem(Class'ShockGame.Battery', 1);
	ReplaceFuse();
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
	local string VerbPlusFuses;
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	assert(__NFUN_119__(thePlayer, none));
	VerbPlusFuses = __NFUN_112__(__NFUN_112__(__NFUN_112__(UseVerbText, " ("), string(thePlayer.GetNumberOfItems(Class'ShockGame.Battery'))), " REMAINING)");
	return VerbPlusFuses;
	return;
	@NULL
	Item
	Item
	@NULL
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	return 1;
	return;
}

function float GetUseDistance()
{
	return 0.0000000;
	return;
}

function bool ActionBlockedByPawns()
{
	return true;
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

defaultproperties
{
	FriendlyName="Fuse Box"
	UseVerbText="REPLACE FUSE"
	bHasFuse=true
	bCanReplaceFuse=true
	FuseClass=Class'ShockGame.ShockDesignerClasses.FusePickup'
	DrawType=8
	bStatic=true
	bInGameRenderable=true
	bCollideActors=true
	bBlockActors=true
	bBlockPlayers=true
	bBlockHavok=true
	ActorSpecificTextureWeight=1.2500000
}