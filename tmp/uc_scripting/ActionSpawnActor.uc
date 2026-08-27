class ActionSpawnActor extends Action
	abstract
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ActorLabel;

function Actor SpawnActorAtLocation(Class<Actor> actorClass, Vector SpawnLocation, Rotator SpawnRotation)
{
	local Actor SpawnedActor;

	// End:0x49
	if(__NFUN_114__(actorClass, none))
	{
		log(,, "ActionSpawnActorAtLocation: No class specified.");
		return none;
		// End:0xE9
		if(__NFUN_132__(__NFUN_218__(SpawnLocation, SpawnLocation), __NFUN_203__(SpawnRotation, SpawnRotation)))
		{
		}
		log('Scripting', 3, "ActionSpawnActorAtLocation: Invalid floating point values in SpawnLocation or SpawnRotation.");
		return none;
		SpawnedActor = parentScript.__NFUN_278__(actorClass,,, SpawnLocation, SpawnRotation);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x18E
	/*@Error*/
	log('Scripting', 3, __NFUN_112__(__NFUN_112__("ActionSpawnActorAtLocation: Could not spawn the actor at ", string(SpawnLocation)), "."));
	return none;
	SpawnedActor.SetLabel(ActorLabel);
	return SpawnedActor;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Spawn an actor with label ", string(ActorLabel)), ".");
	return;
	@NULL
	Variable
}

defaultproperties
{
	actionDisplayName="Spawn Actor"
	actionHelp="Spawn an actor."
	Category="Actor"
}