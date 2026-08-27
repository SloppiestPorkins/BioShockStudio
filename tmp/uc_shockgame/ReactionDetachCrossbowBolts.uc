class ReactionDetachCrossbowBolts extends Object implements IReaction;

function React(ReactiveActor inReactiveActor, ReactionData inData)
{
	local bool ShouldDestroyBolts;

	ShouldDestroyBolts = inData.Bool_1;
	// End:0x58
	if(__NFUN_129__(ShouldDestroyBolts))
	{
		Class'ShockGame.CrossbowProjectile'.static.DetachAnyCrossbowBoltsFromActor(inReactiveActor);
		goto J0x78;
		Class'ShockGame.CrossbowProjectile'.static.DestroyAnyCrossbowBoltsOnActor(inReactiveActor);
		return;
		@NULL
	}
	Item
	Item
	@NULL
}

function string GetReactionEditorDescription()
{
	return __NFUN_112__(__NFUN_112__(__NFUN_112__("Drop/Destroy attached crossbow bolts", " ("), string(default.Class.Name)), ")");
	return;
	@NULL
	Item
}

function string GetReactionDataEditorDisplayName(name OriginalName)
{
	// End:0x37
	if(__NFUN_254__('Bool_1', OriginalName))
	{
		return "DestroyBoltsInsteadOfDropping";
		return "";
		return;
	}
	@NULL
}
