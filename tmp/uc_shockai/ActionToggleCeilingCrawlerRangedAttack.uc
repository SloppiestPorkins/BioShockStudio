class ActionToggleCeilingCrawlerRangedAttack extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name CeilingCrawlerLabel;
var travel bool bEnableRangedAttack;

function Variable execute()
{
	local CeilingCrawler IterCrawler;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9C
	/*@Error*/
	// End:0x9B
	foreach parentScript.dynamicActorLabel(Class'ShockAI.CeilingCrawler', IterCrawler, CeilingCrawlerLabel)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x9A
		/*@Error*/
		IterCrawler.SetCanAttackWithRangedWeapon(bEnableRangedAttack);				
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
	// End:0xD9
	if(__NFUN_255__(CeilingCrawlerLabel, 'None'))
	{
		// End:0x7E
		if(bEnableRangedAttack)
		{
			S = __NFUN_112__(__NFUN_112__("Ceiling Crawler with label ", string(CeilingCrawlerLabel)), " ranged attack will be enabled.");
			goto J0xD6;
			S = __NFUN_112__(__NFUN_112__("Ceiling Crawler with label ", string(CeilingCrawlerLabel)), " ranged attack will be disabled.");
		}
		goto J0x104;
		S = "CeilingCrawlerLabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Toggle whether a Ceiling Crawler uses its ranged attack"
	actionHelp="Toggle whether a Ceiling Crawler uses its ranged attack"
	Category="AI"
}