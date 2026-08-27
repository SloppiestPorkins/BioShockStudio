class PatrolList extends Object
	native
	editinlinenew
	hidecategories(Object);

struct native atomic PatrolEntry
{
	var() Range IdleTime;
	var() int IdleChance;
	var() edfindable PatrolPoint PatrolPoint;
	var() name AnimationToLoop;
	var() name AnimationToPlayOnce;
	var() name AnimationCategoryToLoop;
	var() name AnimationCategoryToPlayOnce;
	var() bool bDoNotRotateToFacePatrolPointRotation;
	var() bool IdleForever;
	var() bool bShouldRun;
	var() bool bShouldBeAggressive;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var export editinline array<export editinline PatrolEntry> PatrolEntries;
var name PatrolName;
var transient array<Vector> PatrolPathLocations;

function OutputAnimationCategories(LevelInfo Level, out array<name> S)
{
	SpawningManager(Level.SpawningManager).OutputAnimationCategories(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PatrolEntry GetPatrolEntry(int PatrolEntryIndex)
{
	assert(__NFUN_153__(PatrolEntryIndex, 0));
	assert(__NFUN_150__(PatrolEntryIndex, PatrolEntries.Length));
	return PatrolEntries[PatrolEntryIndex];
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function int GetNumPatrolEntries()
{
	return PatrolEntries.Length;
	return;
	@NULL
}
