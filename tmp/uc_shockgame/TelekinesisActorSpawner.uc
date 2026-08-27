class TelekinesisActorSpawner extends StaticMeshActor implements IAffectedByTelekinesis
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Force,LightColor,Lighting,Object,Sound);

var(Telekinesis) array< Class<Actor> > SpawnedClasses;
var(Telekinesis) float MaxLifetimeOfSpawnedObjects;

function OnTelekinesisStartedPulling(TelekinesisAbility Telekinesis)
{
	return;
}

function OnTelekinesisStartedThrowing(TelekinesisAbility Telekinesis)
{
	return;
}

function OnTelekinesisStartedHolding(TelekinesisAbility Telekinesis)
{
	return;
}

function OnTelekinesisStartedDroping(TelekinesisAbility Telekinesis)
{
	return;
}

function Actor GetAffectedActor()
{
	local Actor SpawnedActor;

	// End:0x1E
	if(__NFUN_154__(SpawnedClasses.Length, 0))
	{
		SpawnedActor = none;
		goto J0xFC;
		SpawnedActor = __NFUN_278__(SpawnedClasses[__NFUN_167__(SpawnedClasses.Length)]);
	}
	// End:0xA1
	if(__NFUN_177__(SpawnedActor.LifeSpan, float(0)))
	{
		SpawnedActor.LifeSpan = __NFUN_244__(SpawnedActor.LifeSpan, __NFUN_245__(1.0000000, MaxLifetimeOfSpawnedObjects));
		goto J0xC8;
		SpawnedActor.LifeSpan = __NFUN_245__(1.0000000, MaxLifetimeOfSpawnedObjects);
		SpawnedActor.FadeOutDuration = __NFUN_244__(1.0000000, SpawnedActor.LifeSpan);
	}
	return SpawnedActor;
	return;
	@NULL
	Item
	Item
	@NULL
}

function PreTelekinesis()
{
	return;
}

function bool IsAffectedByTelekinesis()
{
	return true;
	return;
}

function ActorsAffectedByTelekinesis(LevelInfo Level, out array< Class<Actor> > TheActors)
{
	local Class actorClass, BaseClass;

	BaseClass = Class'ShockGame.IAffectedByTelekinesis';
	// End:0x72
	foreach AllClasses(BaseClass, actorClass)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x71
		/*@Error*/
		TheActors[TheActors.Length] = Class<Actor>(actorClass);				
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

function string DisplayClassName(Class<Actor> theActor)
{
	local string TheActorName;

	// End:0x34
	if(__NFUN_119__(theActor, none))
	{
		TheActorName = string(theActor.Name);
		goto J0x4D;
		TheActorName = "Unknown Actor";
	}
	return TheActorName;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	MaxLifetimeOfSpawnedObjects=25.0000000
}