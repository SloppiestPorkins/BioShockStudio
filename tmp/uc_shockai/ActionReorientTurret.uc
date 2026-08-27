class ActionReorientTurret extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name TurretLabel;
var travel name TowardsActorLabel;

function Variable execute()
{
	local Turret FoundTurret;
	local Actor TowardsActor;

	super.execute();
	TowardsActor = findByLabel(Class'Engine.Actor', TowardsActorLabel);
	// End:0x87
	if(__NFUN_114__(TowardsActor, none))
	{
		log('Scripting', 3, "Could not find actor specified by TowardsActorLabel.");
		return none;
		// End:0x115
		foreach parentScript.dynamicActorLabel(Class'ShockAI.Turret', FoundTurret, TurretLabel)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x073! */
		FoundTurret.SetStandbyRotation(Rotator(__NFUN_216__(TowardsActor.Location, FoundTurret.Location)).Yaw);				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x020! */
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Reorient ", string(TurretLabel)), " towards "), string(TowardsActorLabel)), ".");
	return;
	@NULL
	CommanderAction
	CommanderAction
}

defaultproperties
{
	actionDisplayName="Reorient a turret."
	actionHelp="Change the orientation of a turret so it's facing another direction."
	Category="AI"
}