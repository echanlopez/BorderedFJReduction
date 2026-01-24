(* ::Package:: *)

BeginPackage["BorderedFJReduction`"]

Unprotect@@Names["BorderedFJReduction`*"];
ClearAll@@Names["BorderedFJReduction`*"];

(* =====================USAGE MESSAGES=====================*)

BorderedFJMatrix::usage="BorderedFJMatrix[kinetic, potential, vars, opts] performs the symbolic Faddeev-Jackiw reduction using geometrically constrained matrix bordering and returns an opaque symbolic object.";

FJSymplecticFrame::usage="FJSymplecticFrame[obj, divColor, backColor] displays a structured visualization of the inverse extended symplectic matrix, when available.";

FaddeevJackiwMatrix::usage="FaddeevJackiwMatrix[oneForm, vars] constructs the pre-symplectic matrix associated with a first-order Lagrangian.";

ToSubscript::usage="ToSubscript[expr] converts symbolic variable names into subscripted form for display purposes. The function is Listable.";

BorderedFJMatrix::iter="After `1` iteration(s), the Faddeev-Jackiw matrix remains unregularized. Try increasing \"MaxIterations\".";

Options[BorderedFJMatrix]={"MaxIterations"->5};

(* =====================IMPLEMENTATION=====================*)

Begin["`Private`"]

(*Main function 1*)
BorderedFJMatrix[Pattern[kineticEnergy, Blank[]], Pattern[symplecticPotential, Blank[]], Pattern[vars, Blank[]], OptionsPattern[]] := With[
	{
		maxIterations = OptionValue @ "MaxIterations",
		potentialDerivatives = Map[D[symplecticPotential, #]&, vars],
(*Initial system:original variables,one-form derived from the kinetic energy,no constraints*)
		initialSystem = Association[
			<|
				"ExtendedSymplecticVariables" -> vars, 
(*The extended one-form comes from the difference kineticEnergy-symplecticPotential*)"ExtendedOneForm" -> Simplify[Coefficient[kineticEnergy, Map[Derivative[1], vars]]],
				"Constraints" -> {},
				"IterationCount" -> 0, "GaugeSymmetry" -> "NotFound", "GaugeCheck" -> "None"
			|>
		],
(*Define the iterative step function that incorporates the derivatives of the symplectic potential*)
		stepFunction = BorderedFJMatrix`BFJStep[
			kineticEnergy, symplecticPotential, vars, Map[D[symplecticPotential, #]&, vars]
		]
	},
(*Iterate until either gauge is detected or no new constraints are added,or MaxIterations is reached*)
	With[
		{
			finalSystem = NestWhile[
				stepFunction, initialSystem, Function[current,
					And[
						Less[Lookup[current, "IterationCount", 0], maxIterations],
						Less[
							Length @ Lookup[current, "Constraints"],
							Length @ Lookup[stepFunction @ current, "Constraints"]
						],
						UnsameQ[Lookup[current, "GaugeSymmetry", "NotFound"], "Found"]
					]
				]
			]
		},
(*Check if iteration limit has been reached*)
		If[
			GreaterEqual[Lookup[finalSystem, "IterationCount", 0], maxIterations],
			Message[BorderedFJMatrix::iter, maxIterations];
			Return[$Failed]
		];
(*"Regularized" when full rank,"NotRegularized" if not,or "GaugeDetected" if a gauge symmetry is found.*)
		With[
			{regularizationStatus = DetermineRegularizationStatus @ finalSystem},
			With[
				{updatedSystem = Append[finalSystem, "MatrixStatus" -> regularizationStatus]},
				If[SameQ[regularizationStatus, "NotRegularized"],
			(*Emit a message if the matrix is not regularized*)
					Message[BorderedFJMatrix::iter, maxIterations];
					Return[$Failed],
(*Wrap the result in BorderedFJMatrix to trigger the summary box,after filtering constraints*)
					(*1*)BorderedFJMatrix @ FilterNullConstraints @ updatedSystem
				]
			]
		]
	]
];
(*Accessor for the association wrapped in the head BorderedFJMatrix*)
BorderedFJMatrix[assoc_Association][key_] := assoc @ key;
(*Helper to determine the regularization status*)
DetermineRegularizationStatus[system_] := If[
	Equal[Lookup[system, "GaugeSymmetry", "NotFound"], "NotFound"],
	If[
		Equal[MatrixRank @ Lookup[system, "ExtendedMatrix"],
			Length @ Lookup[system, "ExtendedSymplecticVariables"]
		],
		"Regularized", "NotRegularized"
	],
	"GaugeDetected"
];
(*Post-processing function:filters constraints that simplify to 0*)
FilterNullConstraints[system_] := Module[
	{cleanedConstraints, cleanedConstraintsLength},
	cleanedConstraints = Select[Lookup[system, "Constraints"], UnsameQ[#, 0]&];
	cleanedConstraintsLength = Length @ cleanedConstraints;
	Join[system,
		<|
			"Constraints" -> cleanedConstraints, "ConstraintsLength" -> cleanedConstraintsLength
		|>
	]
];
(*BFJStep:performs one update step on the system*)
BorderedFJMatrix`BFJStep[kineticEnergy_, symplecticPotential_, vars_, potentialDerivatives_][system_] := Module[
	{
		oneForm, constraints, iterationCount, extMatrix, nullSpace, newPhiList, result,
		extendedOneForm, extendedVariables, extendedMatrix
	},
(*1. Extract system data*)
	{oneForm, constraints, iterationCount} = extractSystemData @ system;
(*2. Compute the extended matrix*)
	extMatrix = computeExtendedMatrix[system, oneForm, vars];
(*3. Compute the null space*)
	nullSpace = computeNullSpace @ extMatrix;
(*If no null space is found,the counter is updated and the function returns*)
	If[Equal[Length @ nullSpace, 0],
		result = updateSystemIteration[system, iterationCount];
		Return[result];
	];
(*4. Compute new constraints*)
	newPhiList = computeNewConstraints[nullSpace, vars, potentialDerivatives];
	result = updateIterationCount[system, iterationCount, Length @ newPhiList];
(*5. Compute new extended objects*)
	{extendedOneForm, extendedVariables, extendedMatrix} = computeExtendedObjects[result, newPhiList, vars];
(*6. Update the system with the new extended objects*)
	result = updateExtendedSystem[result,
		newPhiList, extendedOneForm, extendedVariables, extendedMatrix
	];
(*7. Check if all new constraints are 0*)
	If[allConstraintsZeroQ[newPhiList],
		result = setGaugeFoundZero[result, extendedMatrix];
		Return[result];
	];
(*8. Check if the new constraints are linearly dependent on the existing ones*)
	If[UnsameQ[constraints, {}],
		If[dependentConstraintsQ[constraints, newPhiList, vars],
			result = setGaugeFoundDependent[result, extendedMatrix];
			Return[result];
		]
	];
(*9. If no gauge symmetry is detected,compute the inverse of the extended matrix*)
	result = updateInverseExtendedMatrix[result, extendedMatrix];
	result
];
(*Helper functions for BFJStep*)
extractSystemData[system_] := {
	Lookup[system, "ExtendedOneForm"],
	Lookup[system, "Constraints"],
	Lookup[system, "IterationCount", 0]
};

(*Main function 2: Faddeev-Jackiw Matrix*)
FaddeevJackiwMatrix[oneForm_,vars_]:=Simplify[
		Transpose[Outer[D, oneForm, vars]] - Outer[D, oneForm, vars]
	];

computeExtendedMatrix[system_, oneForm_, vars_] := Lookup[system,
	"ExtendedMatrix",
	FaddeevJackiwMatrix[oneForm,vars]
];

computeNullSpace[matrix_] := NullSpace @ matrix;

updateSystemIteration[system_, iterationCount_] := Module[
	{res = Association @ system},
	res = Append[res, "IterationCount" -> (iterationCount + 1)];
	res = Append[res, "GaugeSymmetry" -> "NotFound"];
	res
];

computeNewConstraints[nullSpace_, vars_, potentialDerivatives_] := Simplify @ Dot[Take[nullSpace, All, Length @ vars], potentialDerivatives];

updateIterationCount[system_, iterationCount_, numNew_] := Module[
	{res = Association @ system},
	res = Append[res, "IterationCount" -> (iterationCount + numNew)];
	res
];

computeExtendedObjects[system_, newPhiList_, vars_] := Module[
	{oneForm, extendedOneForm, extendedVariables, extendedMatrix},
	oneForm = Lookup[system, "ExtendedOneForm"];
	extendedOneForm = Join[oneForm, -newPhiList];
	extendedVariables = Join[Lookup[system, "ExtendedSymplecticVariables"],
		Array[\[FormalLambda], Length @ newPhiList]
	];
	extendedMatrix = Simplify[
		Transpose[Outer[D, extendedOneForm, extendedVariables]] - Outer[D, extendedOneForm, extendedVariables]
	];
	{extendedOneForm, extendedVariables, extendedMatrix}
];

updateExtendedSystem[system_,newPhiList_,extendedOneForm_,extendedVariables_,extendedMatrix_] := Module[
	{res = Association @ system, constraints},
	constraints = Lookup[res, "Constraints"];
	res = Append[res, "ExtendedSymplecticVariables" -> extendedVariables];
	res = Append[res, "ExtendedOneForm" -> extendedOneForm];
	res = Append[res, "ExtendedMatrix" -> extendedMatrix];
	res = Append[res, "Constraints" -> Join[constraints, newPhiList]];
	res = Append[res, "ConsistencyCheck" -> True];
	res = Append[res,
		"ConstraintsLength" -> Length[Join[constraints, newPhiList]]
	];
	res = Append[res, "ExtendedMatrixRank" -> MatrixRank[extendedMatrix]];
	res = Append[res, "OneFormLength" -> Length[extendedOneForm]];
	Append[res, "VariablesLength" -> Length[extendedVariables]]
];

allConstraintsZeroQ[newPhiList_] := AllTrue[newPhiList, SameQ[#, 0]&];

setGaugeFoundZero[system_, extendedMatrix_] := Append[
	Append[
		Append[Append[system, "GaugeSymmetry" -> "Found"],
			"GaugeDetectionReason" -> "Null constraint detected: all new constraints are identically zero."
		],
		"PartialExtendedMatrix" -> extendedMatrix
	],
	"Properties" -> {
		"Constraints", "ExtendedMatrix", "ExtendedOneForm", "ExtendedSymplecticVariables",
		"GaugeDetectionReason", "IterationCount", "MatrixStatus"
	}
];

dependentConstraintsQ[constraints_, newPhiList_, vars_] := Module[
	{oldRank, newRank},
	oldRank = MatrixRank[Part[CoefficientArrays[constraints, vars], 2]];
	newRank = MatrixRank[
		Part[CoefficientArrays[Join[constraints, newPhiList], vars], 2]
	];
	SameQ[newRank, oldRank]
];

setGaugeFoundDependent[system_, extendedMatrix_] := Append[
	Append[
		Append[Append[system, "GaugeSymmetry" -> "Found"],
			"GaugeDetectionReason" -> "Dependent constraints detected: new constraints are linearly dependent on existing ones."
		],
		"PartialExtendedMatrix" -> extendedMatrix
	],
	"Properties" -> {
		"Constraints", "ExtendedMatrix", "ExtendedOneForm", "ExtendedSymplecticVariables",
		"GaugeDetectionReason", "IterationCount", "MatrixStatus"
	}
];

updateInverseExtendedMatrix[system_, extendedMatrix_] := Module[
	{res = Association @ system, invMatrix},
	If[
		Or[Less[MatrixRank @ extendedMatrix, Length @ extendedMatrix],
			SameQ[Lookup[res, "GaugeSymmetry", "NotFound"], "Found"]
		],
(*If the matrix is singular or gauge is detected,the inverse is not computed*)
		res,
(*If not,the inverse is computed*)
		invMatrix = Quiet @ Simplify @ Inverse @ extendedMatrix;
		res = Append[res, "InverseExtendedMatrix" -> invMatrix];
		res = Append[res, "GaugeSymmetry" -> "NotFound"];
		Append[res,
			"Properties" -> {
				"Constraints", "ExtendedMatrix", "ExtendedOneForm", "ExtendedSymplecticVariables",
				"InverseExtendedMatrix", "IterationCount", "MatrixStatus"
			}
		]
	]
];

(*MakeBoxes rule to display the summary box for BorderedFJMatrix objects*)
BorderedFJMatrix/:MakeBoxes[ifun:BorderedFJMatrix[assoc_Association],fmt_] :=BoxForm`ArrangeSummaryBox[
	BorderedFJMatrix, ifun, myicon, {
		mylabel["ExtendedMatrixRank", assoc @ "ExtendedMatrixRank"],
		mylabel["GaugeSymmetry", assoc @ "GaugeSymmetry"]
	},
	{
		mylabel["ConsistencyCheck", assoc @ "ConsistencyCheck"],
		mylabel["ConstraintsLength", assoc @ "ConstraintsLength"],
		mylabel["OneFormLength", assoc @ "OneFormLength"],
		mylabel["VariablesLength", assoc @ "VariablesLength"]
	},
	fmt
];

(*Icon for summary box display*)
myicon := MatrixPlot[
	{{1, 1, 2}, {3, 5, 8}, {13, 21, 34}},
	ColorRules->{0->LightOrange,1->Purple,2->LightBlue}, 
	Frame -> False, ImageSize -> Dynamic[
		{
			Automatic,
			Times[3.5,
				CurrentValue["FontCapHeight"] / AbsoluteCurrentValue[Magnification]
			]
		}
	],
	AspectRatio -> 1
];

(*Label function for the summary box*)
mylabel[lbl_,v_] := Row @ {
	Style[StringJoin[lbl, ": "], "SummaryItemAnnotation"],
	Style[ToString @ v, "SummaryItem"]
};

ToSubscript[sym_Symbol] /; UnsameQ[Context @ sym, "System`"] := Fold[
	ReverseApplied @ Subscript,
	Reverse @ ToExpression @ Characters @ ToString @ sym
];

(*Main function 3*)
ToSubscript[Pattern[expr, Blank[]]] /; SameQ[Head @ expr, Subscript] := expr;

SetAttributes[ToSubscript,Listable];

(*Main function 4*)
FJSymplecticFrame[bfj_BorderedFJMatrix,divColor_:Darker@Blue,backColor_:LightBlue]:=Module[
	{props = bfj @ "Properties", mat, vars, labels, newMat, divStyle, grd},
	If[!MemberQ[props, "InverseExtendedMatrix"],
		Return["This format applies only if the \"InverseExtendedMatrix\" property exists."];
	];
	mat = bfj @ "InverseExtendedMatrix";
	vars = bfj @ "ExtendedSymplecticVariables";
	labels = ToSubscript[
		ReplaceAll[vars, sym_Symbol[Pattern[n, Blank[]]] :> Subscript[sym, n]]
	];
	newMat = Prepend[MapThread[Prepend, {mat, labels}], Prepend[labels, ""]];
	divStyle = Directive[divColor, Dashed, Thickness @ 1];
	grd = Grid[newMat,
		Alignment -> Center,
		Dividers -> {{2 -> divStyle}, {2 -> divStyle}},
		Background -> {1 -> backColor, 1 -> backColor},
		ItemStyle -> Automatic
	];
	MatrixForm @ {{grd}}
];

End[]

Protect@@Names["BorderedFJReduction`*"];

SetAttributes[BorderedFJMatrix,{ReadProtected,Protected,Locked}];
SetAttributes[FaddeevJackiwMatrix,{ReadProtected,Protected,Locked}];
SetAttributes[ToSubscript,{ReadProtected,Protected,Locked}];
SetAttributes[FJSymplecticFrame,{ReadProtected,Protected,Locked}];

EndPackage[]
