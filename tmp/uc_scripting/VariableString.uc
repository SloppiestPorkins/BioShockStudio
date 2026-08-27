class VariableString extends Variable
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel string Value;

function Add(string rhs)
{
	Value = __NFUN_112__(Value, rhs);
	return;
	@NULL
	Variable
	Variable
}

function subtract(string rhs)
{
	return;
}

function multiply(string rhs)
{
	return;
}

function divide(string rhs)
{
	return;
}

function bool less(string rhs)
{
	return false;
	return;
}

function bool lessEqual(string rhs)
{
	return false;
	return;
}

function bool equal(string rhs)
{
	return __NFUN_124__(Value, rhs);
	return;
	@NULL
	Variable
}

function bool notEqual(string rhs)
{
	return __NFUN_129__(__NFUN_124__(Value, rhs));
	return;
	@NULL
	Variable
}

function bool greaterEqual(string rhs)
{
	return false;
	return;
}

function bool greater(string rhs)
{
	return false;
	return;
}

function bool and(string rhs)
{
	return __NFUN_130__(__NFUN_155__(__NFUN_125__(Value), 0), __NFUN_155__(__NFUN_125__(rhs), 0));
	return;
	@NULL
	Variable
}

function bool or(string rhs)
{
	return __NFUN_132__(__NFUN_155__(__NFUN_125__(Value), 0), __NFUN_155__(__NFUN_125__(rhs), 0));
	return;
	@NULL
	Variable
}

function bool not()
{
	return __NFUN_154__(__NFUN_125__(Value), 0);
	return;
	@NULL
}

function bool truth()
{
	return __NFUN_155__(__NFUN_125__(Value), 0);
	return;
	@NULL
}
