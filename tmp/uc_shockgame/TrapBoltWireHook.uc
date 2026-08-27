class TrapBoltWireHook extends Actor
	native
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var TrapBoltProjectile OwnerTrapBolt;

function Destroyed()
{
	// End:0x50
	if(__NFUN_130__(__NFUN_119__(OwnerTrapBolt, none), OwnerTrapBolt.BoltIsArmed()))
	{
		OwnerTrapBolt.WireTripped(none, vect(0.0000000, 0.0000000, 0.0000000));
		return;
		@NULL
		Item
	}
	Item
}

defaultproperties
{
	bInGameRenderable=true
}