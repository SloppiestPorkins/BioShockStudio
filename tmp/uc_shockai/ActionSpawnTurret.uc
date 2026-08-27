class ActionSpawnTurret extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var TurretSpawner Spawner;

function DisplaySpawners(LevelInfo Level, out array<TurretSpawner> Spawners)
{
	local TurretSpawner Iter;

	// End:0x44
	foreach Level.__NFUN_304__(Class'ShockAI.TurretSpawner', Iter)
	{
		Spawners[Spawners.Length] = Iter;				
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function string DisplaySpawnerName(TurretSpawner Spawner)
{
	// End:0x2B
	if(__NFUN_119__(Spawner, none))
	{
		return string(Spawner.Name);
		goto J0x3D;
		return "Spawner Not Set";
	}
	return;
	@NULL
	CommanderAction
	J0x3D:

	CommanderAction
}

function Variable execute()
{
	super.execute();
	// End:0x30
	if(__NFUN_119__(Spawner, none))
	{
		Spawner.SpawnScriptedTurret();
		return none;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Spawn Turret using spawner ", propertyDisplayString('Spawner'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Spawn a Turret"
	actionHelp="Spawns a Turret"
	Category="AI"
}