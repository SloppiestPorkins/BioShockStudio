class PhysicalReactiveActor extends ReactiveActor implements IAffectedByTelekinesis
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Collision);

var(Reactions) editinline array<editinline ReactionData> TelekinesisImpactReactions;
var(Telekinesis) bool bTelekinesisDisabled;

function OnTelekinesisStartedPulling(TelekinesisAbility Telekinesis)
{
	SetInfernoID(0);
	return;
	@NULL
}

event OnTelekinesisStartedHolding(TelekinesisAbility Telekinesis)
{
	return;
}

event OnTelekinesisStartedThrowing(TelekinesisAbility Telekinesis)
{
	return;
}

event OnTelekinesisStartedDroping(TelekinesisAbility Telekinesis)
{
	return;
}

event Actor GetAffectedActor()
{
	return self;
	return;
}

function PreTelekinesis()
{
	return;
}

function bool IsAffectedByTelekinesis()
{
	// End:0x48
	if(IsCensoredContent())
	{
		// End:0x48
		if(__NFUN_130__(__NFUN_154__(int(DrawType), int(2)), __NFUN_154__(int(GetRagdoll().GetRagdollState()), int(2))))
		{
			return false;
			return __NFUN_129__(bTelekinesisDisabled);
		}
	}
	return;
	@NULL
	Item
	Item
}

function Destroyed()
{
	Class'ShockGame.CrossbowProjectile'.static.DetachAnyCrossbowBoltsFromActor(self);
	super.Destroyed();
	return;
	@NULL
	Item
}

function OnCollidedAfterThrownByTelekinesis()
{
	// End:0x23
	if(__NFUN_151__(TelekinesisImpactReactions.Length, 0))
	{
		ExecuteReactions(TelekinesisImpactReactions);
		return;
		@NULL
		Item
	}
	stop;
	default.@NULL
}

defaultproperties
{
	Physics=1
	bBlockActors=false
	bBlockPlayers=false
}