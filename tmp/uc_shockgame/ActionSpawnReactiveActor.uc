class ActionSpawnReactiveActor extends ActionSpawnActorAtActorLocation
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Class<ReactiveActor> ReactiveActorClass;
var travel bool StartsPhysical;

function AllConcreteReactiveActorClasses(LevelInfo Level, out array< Class<ReactiveActor> > S)
{
	//native.Level;
	//native.S;	
	@NULL
	@NULL
}

function Variable execute()
{
	local ReactiveActor SpawnedReactiveActor;

	super(Action).execute();
	SpawnedReactiveActor = ReactiveActor(SpawnActor(ReactiveActorClass));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x60
	/*@Error*/
	SpawnedReactiveActor.HavokActivate(StartsPhysical);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Spawn a ReactiveActor of class ", string(ReactiveActorClass)), " at "), string(TargetActorLabel)), " with label "), string(ActorLabel)), ".");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Spawn a ReactiveActor"
	actionHelp="Spawn a ReactiveActor at the location specified by an actor."
}