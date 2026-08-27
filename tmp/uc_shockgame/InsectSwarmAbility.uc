class InsectSwarmAbility extends Ability
	config(Abilities);

var config Class<BaseShockAI> InsectSwarmClass;
var config int NumberOfInsectSwarmsToSpawn;

function UseAbility(ShockPlayer Instigator)
{
	local BaseShockAI SpawnedInsectSwarm;
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAB
	/*@Error*/
	SpawnedInsectSwarm = Instigator.__NFUN_278__(InsectSwarmClass, none,, Instigator.Location);
	SpawnedInsectSwarm.SetSwarmPlayerOwner(Instigator);
	SpawnedInsectSwarm.UpdateTimeToLive(Instigator);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	super.UseAbility(Instigator);
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	InsectSwarmClass=Class'ShockGame.ShockAIClasses.SpawnedInsectSwarm'
	NumberOfInsectSwarmsToSpawn=3
	ModGroupName="InsectSwarm_Exists"
	BioAmmoCost=8.0000000
	FriendlyName="Insect Swarm"
	FastEquipAnimationName="InsectSwarm_Equip"
	SlowEquipAnimationName="InsectSwarm_Equip"
	FireAnimationName="InsectSwarm_Fire"
	FinishFireWithEveAnimationName="InsectSwarm_FireEve"
	FinishFireWithoutEveAnimationName="InsectSwarm_FireNoEve"
	IdlingAnimationName[0]="InsectSwarm_Fidget"
}