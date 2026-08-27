class EaseTableEvaluator extends DifficultyEvaluator
	config(Difficulty)
	perobjectconfig;

var private config name EaseTableName;
var private transient EaseTable Table;

function Construct()
{
	log('Difficulty', 4, __NFUN_112__(__NFUN_112__(string(Name), " using "), string(EaseTableName)));
	Table = Class'ShockGame.EaseTable'.static.Allocate(self,, string(EaseTableName)).;
	Construct_Void();
	return;
	@NULL
	Item
	Vector
	@NULL
}

function int Evaluate(array<DifficultyStat> Stats, DifficultyManager DifficultyManager, out int BaseEaseValue)
{
	AssertWithDescription(__NFUN_154__(Stats.Length, 1), "EaseTables only evaluate based on one stat, multiple stats passed to evaluate");
	BaseEaseValue = Table.GetEaseValue(Stats[0].BaseValue, DifficultyManager);
	return Table.GetEaseValue(Stats[0].Value, DifficultyManager);
	return;
	@NULL
	Item
	Item
	@NULL
}
