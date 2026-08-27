class CorpseManager extends Object implements IInterestedActorDestroyed, IInterestedPawnDied
	native
	config(ShockGame);

struct native atomic CorpseInfo
{
	var BaseShockAI Corpse;
	var float TimeOfDeath;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic LootInfo
{
	var StaticMeshContainer Container;
	var float TimeOfDeath;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var config int NumCorpsesAllowed;
var config int NumVisibleCorpsesAllowed;
var config float CorpseFadeOutTime;
var config float CorpseNotRenderedCleanupTime;
var array<CorpseInfo> Corpses;
var BaseShockAI CorpseFadingOut;
var config int NumLootsAllowed;
var config int NumVisibleLootsAllowed;
var config float LootFadeOutTime;
var config float LootNotRenderedCleanupTime;
var array<LootInfo> Loots;
var StaticMeshContainer LootFadingOut;
var LevelInfo Level;
var config Class<StaticMeshContainer> DropContainerClass;

function Construct(LevelInfo inLevel)
{
	assert(__NFUN_119__(inLevel, none));
	Level = inLevel;
	Level.RegisterNotifyActorDestroyed(self);
	Level.RegisterNotifyPawnDied(self);
	return;
	@NULL
	Item
	Vector
	@NULL
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	local CorpseInfo Info;
	local BaseShockAI AI;

	AI = BaseShockAI(DeadPawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBC
	/*@Error*/
	Info.Corpse = AI;
	Info.TimeOfDeath = Level.TimeSeconds;
	Corpses[Corpses.Length] = Info;
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	local int i;
	local IHaveAContainer ContainerActor;
	local StaticMeshContainer SpawnedContainer;
	local LootInfo LootInfo;

	// End:0x1FD
	if(__NFUN_114__(CorpseFadingOut, ActorBeingDestroyed))
	{
		CorpseFadingOut = none;
		ContainerActor = IHaveAContainer(ActorBeingDestroyed);
		// End:0x1FD
		if(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_119__(DropContainerClass, none), __NFUN_119__(ContainerActor, none)), __NFUN_119__(ContainerActor.GetContainer(), none)), __NFUN_129__(__NFUN_130__(ContainerActor.GetContainer().HasEverBeenRolled(), ContainerActor.GetContainer().IsEmpty()))))
		{
			SpawnedContainer = ActorBeingDestroyed.__NFUN_278__(DropContainerClass,,, ActorBeingDestroyed.Location, ActorBeingDestroyed.Rotation, true);
			assert(__NFUN_114__(SpawnedContainer.Container, none));
			SpawnedContainer.Container = ContainerActor.GetContainer().GetCopy();
			SpawnedContainer.Container.SetOwner(SpawnedContainer);
			SpawnedContainer.HavokUnfreeze();
			LootInfo.Container = SpawnedContainer;
			__NFUN_163__(SpawnedContainer.SendDestructionNotification);
			i = __NFUN_147__(Corpses.Length, 1);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2B6
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2A8
			/*@Error*/
			LootInfo.TimeOfDeath = Corpses[i].TimeOfDeath;
			Corpses.Remove(i, 1);
			__NFUN_164__(i);
			goto J0x214;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2F4
			/*@Error*/
		}
	}
	Loots[Loots.Length] = LootInfo;
	i = __NFUN_147__(Loots.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x36E
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x360
	/*@Error*/
	Loots.Remove(i, 1);
	__NFUN_164__(i);
	goto J0x30B;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x390
	/*@Error*/
	LootFadingOut = none;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	NumCorpsesAllowed=10
	NumVisibleCorpsesAllowed=4
	CorpseFadeOutTime=3.0000000
	CorpseNotRenderedCleanupTime=10.0000000
	NumLootsAllowed=20
	NumVisibleLootsAllowed=4
	LootFadeOutTime=3.0000000
	LootNotRenderedCleanupTime=10.0000000
	DropContainerClass=Class'ShockGame.ShockDesignerClasses.Lockbox'
}