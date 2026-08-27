class ActionSpawnActorAtActorLocation extends ActionSpawnActor
	abstract
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name TargetActorLabel;

function Actor SpawnActor(Class<Actor> actorClass)
{
	local Actor targetActor;

	targetActor = findByLabel(Class'Engine.Actor', TargetActorLabel);
	// End:0x91
	if(__NFUN_114__(targetActor, none))
	{
		log('Scripting', 3, __NFUN_112__(__NFUN_112__("ActionSpawnActorAtActorLocation: Could not find actor ", string(TargetActorLabel)), "."));
		return none;
		return SpawnActorAtLocation(actorClass, targetActor.Location, targetActor.Rotation);
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Spawn an actor at ", string(TargetActorLabel)), " with label "), string(ActorLabel)), ".");
	return;
	@NULL
	Variable
	Variable
}

defaultproperties
{
	actionDisplayName="Spawn Actor at Another Actor's Location"
	actionHelp="Spawn an actor at the location specified by an actor."
}