class ActionHackTurret extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name TurretLabel;
var travel bool SetHacked;

function Variable execute()
{
	local Turret FoundTurret;

	super.execute();
	// End:0xFB
	foreach parentScript.dynamicActorLabel(Class'ShockAI.Turret', FoundTurret, TurretLabel)
	{
		log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("Setting ", string(FoundTurret)), " to "), string(SetHacked)));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xFA
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE3
		/*@Error*/
		FoundTurret.SetHacked(ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn));
		goto J0xFA;
		FoundTurret.SetNotHacked();				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function editorDisplayString(out string S)
{
	// End:0x4C
	if(SetHacked)
	{
		S = __NFUN_112__(__NFUN_112__("Hack all turrets with label '", string(TurretLabel)), "'.");
		goto J0x8A;
		S = __NFUN_112__(__NFUN_112__("Unhack all turrets with label '", string(TurretLabel)), "'.");
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	SetHacked=true
	actionDisplayName="Hack or Unhack Turrets"
	actionHelp="Hacks or unhacks a turret."
	Category="Security"
}