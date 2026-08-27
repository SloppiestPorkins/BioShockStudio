class FrequentDeathAdvisor extends DifficultyAdvisor
	config(Difficulty);

var private config DifficultyFloat MaxDeathDuration;
var private config DifficultyFloat AliveDuration;

function int AssessInternal(ShockPlayer Player, out int BaseEase)
{
	local DifficultyStatsManager StatsManager;

	StatsManager = DifficultyManager.DifficultyStatsManager;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x17A
	/*@Error*/
	BaseEase = -1;
	return -1;
	goto J0x187;
	BaseEase = 0;
	return 0;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

defaultproperties
{
	MaxDeathDuration=(Low=2000.0000000,Normal=1200.0000000,High=300.0000000,Extreme=300.0000000)
	AliveDuration=(Low=900.0000000,Normal=300.0000000,High=120.0000000,Extreme=120.0000000)
	AdjustmentRecommendations[0]=(AdjustmentClass=Class'ShockGame.SpawnMedHypoAdjustment',ProbabilityTableName="DeathProbabilityTable",Count=4,Priority=10,Weight=-1.0000000)
	AdjustmentRecommendations[1]=(AdjustmentClass=Class'ShockGame.SpawnAmmoAdjustment',ProbabilityTableName="DeathProbabilityTable",Count=4,Priority=4,Weight=-1.0000000)
	AdjustmentRecommendations[2]=(AdjustmentClass=Class'ShockGame.SpawnBioAmmoAdjustment',ProbabilityTableName="DeathProbabilityTable",Count=4,Priority=5,Weight=-1.0000000)
}