class ActionToggleAIWeaponVisibility extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel bool bShowWeapon;

function ToggleAIWeaponVisibility(ShockAI Target)
{
	local Weapon AIWeapon;

	AIWeapon = Weapon(Target.GetActiveHoldable());
	// End:0x7C
	if(__NFUN_119__(AIWeapon, none))
	{
		// End:0x61
		if(bShowWeapon)
		{
			AIWeapon.SetHidden(false);
			goto J0x79;
			AIWeapon.SetHidden(true);
			goto J0xC7;
			log('AI', 2, __NFUN_112__("No active weapon to be hidden/shown for AI: ", string(Target)));
		}
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Variable execute()
{
	local ShockAI Target;

	super.execute();
	// End:0x8A
	if(__NFUN_255__(AILabel, 'None'))
	{
		// End:0x86
		foreach parentScript.Level.dynamicActorLabel(Class'ShockAI.ShockAI', Target, AILabel)
		{
			// End:0x85
			if(__NFUN_119__(Target, none))
			{
				ToggleAIWeaponVisibility(Target);								
				goto J0xC7;
				log('AI', 2, __NFUN_112__("No AILabel or AIClass set for ", string(Name)));
			}
		}
	}
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x93
	if(__NFUN_255__(AILabel, 'None'))
	{
		// End:0x37
		if(bShowWeapon)
		{
			S = "Show";
			goto J0x47;
			S = "Hide";
		}
		S = __NFUN_112__(__NFUN_112__(S, " the active weapon of AIs with label "), string(AILabel));
		goto J0xAF;
		S = "AILabel not set!";
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Toggle AI's Weapon Visibility"
	actionHelp="Show or hide an AI's active weapon"
	Category="AI"
}