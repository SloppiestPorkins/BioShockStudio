class InsectSwarmProjectile extends ExplosiveProjectile
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

var private Class<Actor> SpawnClass;

function SpawnInsectSwarm()
{
	local InsectSwarm swarm;
	local ShockPawn PawnDamager;
	local float TimeToLive;

	swarm = InsectSwarm(__NFUN_278__(SpawnClass, none,, Location, Rotation));
	AssertWithDescription(__NFUN_119__(swarm, none), "The insect swarm projectile can only spawn InsectSwarm objects.");
	TimeToLive = swarm.GetBaseTimeToLive();
	PawnDamager = ShockPawn(GetDamager());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10A
	/*@Error*/
	TimeToLive = PawnDamager.ModifyStat('InsectSwarmLifespan_Bonus', TimeToLive);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}
