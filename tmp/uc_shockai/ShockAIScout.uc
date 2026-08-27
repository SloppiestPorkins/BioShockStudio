class ShockAIScout extends ShockAI
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

function float GetPathfindingDistanceBetween(Actor Start, Vector StartLocation, Actor Finish, Vector FinishLocation, Class AIClass)
{
	//native.Start;
	//native.StartLocation;
	//native.Finish;
	//native.FinishLocation;
	//native.AIClass;	
	@NULL
	@NULL
	return default.@NULL;
}

defaultproperties
{
	bIsInvincible=true
	bUsesTyrion=false
	bUseHavokPhantomCollisions=false
	AILookAtType=0
	DrawType=0
	bHidden=true
	bCollideActors=false
	bCollideWorld=false
	bBlockPlayers=false
	bIgnoreOutOfWorld=true
}