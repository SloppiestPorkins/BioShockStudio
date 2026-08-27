class ActionChangeCollision extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

enum CollisionChangeType
{
	SetToTrue,                      // 0
	SetToFalse,                     // 1
	DoNotChange                     // 2
};

var travel name Target;
var travel ActionChangeCollision.CollisionChangeType CollideActors;
var travel ActionChangeCollision.CollisionChangeType CollideWorld;
var travel ActionChangeCollision.CollisionChangeType BlockActors;
var travel ActionChangeCollision.CollisionChangeType BlockPlayers;
var travel ActionChangeCollision.CollisionChangeType BlockNonZeroExtentTraces;
var travel ActionChangeCollision.CollisionChangeType WorldGeometry;
var travel ActionChangeCollision.CollisionChangeType blockHavok;

function Variable execute()
{
	local Actor targetActor;

	super.execute();
	// End:0x53
	foreach parentScript.allActorLabel(Class'Engine.Actor', targetActor, Target)
	{
		SetCollisionForActor(targetActor);				
		return none;
		return;
		@NULL
		Variable
		Variable
		@NULL
	}
}

function SetCollisionForActor(Actor targetActor)
{
	local bool newCollideActors, newCollideWorld, NewBlockActors, NewBlockPlayers, newBlockNonZeroExtentTraces, newWorldGeometry,
		newBlockHavok;

	newCollideActors = targetActor.bCollideActors;
	newCollideWorld = targetActor.bCollideWorld;
	NewBlockActors = targetActor.bBlockActors;
	NewBlockPlayers = targetActor.bBlockPlayers;
	newBlockNonZeroExtentTraces = targetActor.bBlockNonZeroExtentTraces;
	newWorldGeometry = targetActor.bWorldGeometry;
	newBlockHavok = false;
	// End:0xFB
	if(__NFUN_154__(int(CollideActors), int(0)))
	{
		newCollideActors = true;
		goto J0x11B;
		// End:0x11B
		if(__NFUN_154__(int(CollideActors), int(1)))
		{
			newCollideActors = false;
			// End:0x13E
			if(__NFUN_154__(int(CollideWorld), int(0)))
			{
				newCollideWorld = true;
				goto J0x15E;
				// End:0x15E
				if(__NFUN_154__(int(CollideWorld), int(1)))
				{
					newCollideWorld = false;
					// End:0x181
					if(__NFUN_154__(int(BlockActors), int(0)))
					{
					}
					NewBlockActors = true;
					goto J0x1A1;
					// End:0x1A1
					if(__NFUN_154__(int(BlockActors), int(1)))
					{
					}
					NewBlockActors = false;
					// End:0x1C4
					if(__NFUN_154__(int(BlockPlayers), int(0)))
					{
						NewBlockPlayers = true;
						goto J0x1E4;
					}
					// End:0x1E4
					if(__NFUN_154__(int(BlockPlayers), int(1)))
					{
						NewBlockPlayers = false;
						// End:0x207
						if(__NFUN_154__(int(BlockNonZeroExtentTraces), int(0)))
						{
						}
						newBlockNonZeroExtentTraces = true;
						goto J0x227;
						// End:0x227
						if(__NFUN_154__(int(BlockNonZeroExtentTraces), int(1)))
						{
						}
						newBlockNonZeroExtentTraces = false;
						// End:0x24A
						if(__NFUN_154__(int(WorldGeometry), int(0)))
						{
							newWorldGeometry = true;
						}
						goto J0x26A;
						// End:0x26A
						if(__NFUN_154__(int(WorldGeometry), int(1)))
						{
							newWorldGeometry = false;
							// End:0x28D
							if(__NFUN_154__(int(blockHavok), int(0)))
							{
							}
							newBlockHavok = true;
							goto J0x2AD;
							// End:0x2AD
							if(__NFUN_154__(int(blockHavok), int(1)))
							{
							}
							newBlockHavok = false;
							targetActor.bCollideWorld = newCollideWorld;
						}
						targetActor.bBlockNonZeroExtentTraces = newBlockNonZeroExtentTraces;
						/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
							
						*/

						// End:0x352
						/*@Error*/
					}
					targetActor.bWorldGeometry = newWorldGeometry;
				}
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x387
				/*@Error*/
			}
			targetActor.HavokSetBlocking(newBlockHavok);
			targetActor.__NFUN_262__(newCollideActors, NewBlockActors, NewBlockPlayers);
		}
		return;
		@NULL
		Variable
	}
	J0x2AD:

	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Change the collision of ", string(Target)), " to bCollideActors="), string(CollideActors)), ", bCollideWorld="), string(CollideWorld)), ", bBlockActors="), string(BlockActors)), ", bBlockPlayers="), string(BlockPlayers)), ".");
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	CollideActors=2
	CollideWorld=2
	BlockActors=2
	BlockPlayers=2
	BlockNonZeroExtentTraces=2
	WorldGeometry=2
	blockHavok=2
	actionDisplayName="Change Collision Properties"
	actionHelp="Change the basic collision properties of an actor."
	Category="Actor"
}