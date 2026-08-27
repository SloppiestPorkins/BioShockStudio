class BioshockCharacterGoal extends AI_CharacterGoal
	abstract
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var private bool bFinishUp;

function bool ShouldFinishUp()
{
	return bFinishUp;
	return;
	@NULL
}

function FinishUp()
{
	bFinishUp = true;
	return;
	@NULL
}

function CancelFinishUp()
{
	bFinishUp = false;
	return;
	@NULL
}
