(* ::Package:: *)

(* :Title: BorderedFJReduction *)
(* :Author: Ramon Eduardo Chan Lopez, Jose Alberto Martin Ruiz,
            Jaime Manuel Cabrera, Jorge Mauricio Paulin Fuentes *)
(* :Version: 0.1.3 *)
(* :Wolfram Language Version: 13.0+ *)
(* :Summary:
     Symbolic engine for the Faddeev-Jackiw reduction of singular
     first-order Lagrangians (Barcelos-Neto--Wotzasek bordering),
     formulated as a geometrically constrained instance of matrix
     bordering.

     SCOPE OF THIS BUILD.  The engine reduces the system until the
     extended matrix f^(m) is REGULARIZED, until an INCONSISTENCY is
     produced, or until the bordering recursion stalls in a way that is
     structurally compatible with a gauge symmetry.  In the last case
     the engine reports a CANDIDATE and stops: it does NOT construct,
     classify, or verify gauge generators.  Accordingly the verdict key
     "GaugeSymmetry" takes the values

         "CandidateFound"     the recursion stalled on a kernel whose
                              consistency contractions are weakly zero;
                              a gauge symmetry is the expected, but
                              NOT certified, explanation;
         "NotCandidateFound"  no such stall occurred along the path
                              actually traversed.

     The v0.1.2 values "Found"/"NotFound" are retired: they asserted a
     detection the engine never performed.  Generator construction,
     independence analysis, degeneracy loci and canonical charges live
     in the companion engine (separate repository) and are deliberately
     absent here; every candidate halt stores
     "GaugeAnalysis" -> Missing["NotAvailable", ...] to make the
     boundary explicit rather than implicit.

     CHANGELOG v0.1.2 -> v0.1.3
     ---------------------------------------------------------------
     C1  Verdict semantics.  "GaugeSymmetry" now reports
         "CandidateFound"/"NotCandidateFound"; "MatrixStatus" reports
         "GaugeCandidate" instead of "GaugeDetected"; the halt keys
         "GaugeCandidateBranch" ("ZeroContraction" |
         "DependentConstraints"), "GaugeCandidateReason",
         "GaugeCandidateMethod", "KernelDimension" and
         "CandidateMultiplicity" replace the single prose string of
         v0.1.2.  "GaugeDetectionReason" is kept as a deprecated alias.

     C2  Halting and iteration semantics.  The NestWhile predicate used
         to CALL the step function inside the test, so every pass was
         evaluated twice (all Groebner/Simplify work duplicated) and the
         halt condition was inferred from a look-ahead state that was
         then discarded.  The halt now lives in the state under "Halt"
         (None | "Regular" | "GaugeCandidate" | "Inconsistent") and the
         step function is idempotent on halted states.
         "IterationCount" is m, the number of BORDERING ROUNDS (the
         superscript of f^(m)), incremented only on extension; v0.1.2
         incremented it by the NUMBER of new constraints, prematurely
         exhausting "MaxIterations".  The total number of passes is
         reported separately as "PassCount"; a readout pass (empty
         kernel, candidate or inconsistent halt) is not an iteration.

     C3  Input validation.  The kinetic term must be linear in the
         atomic velocities Derivative[1][q]; otherwise
         BorderedFJMatrix::lin is issued and $Failed returned.  v0.1.2
         silently produced a velocity-dependent one-form and a
         meaningless f^(0).  "MaxIterations" is validated
         (positive integer or Infinity).

     C4  Identically-zero candidate constraints are discarded during the
         step and recorded in "Diagnostics", never appended.  v0.1.2
         appended them, creating multipliers with zero coupling, hence
         permanent spurious null modes and false verdicts.

     C5  Constraint novelty by ideal membership.  A candidate is
         redundant iff its Groebner normal form modulo the ideal of the
         accumulated constraints vanishes (PolynomialReduce).  This is
         the weak-vanishing notion of Dirac consistency and is exact for
         NONLINEAR constraints; it resolves the q-vs-q^2 pathology that
         defeats the linear-coefficient rank test of v0.1.2
         (CoefficientArrays[..., vars][[2]], which moreover degenerated
         to zero rows on trigonometric data).  Trigonometric-polynomial
         data is embedded exactly via Cos[v] -> c_v, Sin[v] -> s_v with
         the Pythagorean relations adjoined.  Genuinely non-algebraic
         data falls back to generic gradient rank over the function
         field and issues BorderedFJMatrix::nonpoly at most once per
         run.

     C6  Candidate multiplicity by ideal membership.  In the dependent
         branch the constant combinations w with Sum_a w_a (v^(a).dV) in
         the constraint ideal are counted as the null space of the
         monomial-coefficient matrix of the normal forms (the
         normal-form map is linear, so constant-w membership is exact
         linear algebra).  Only the DIMENSION of that space is reported
         ("CandidateMultiplicity"); the combinations themselves are the
         raw material of generator construction and are out of scope.

     C7  Globally numbered multipliers.  Successive bordering rounds
         rebuilt Array[\[FormalLambda], k] from 1, so a second round
         reused \[FormalLambda][1], collapsing distinct multipliers into
         one variable.  A "MultiplierCount" state key now numbers them
         globally.

     C8  Inconsistency detection.  A nonzero candidate constraint free
         of the phase-space variables halts with
         "MatrixStatus" -> "Inconsistent" and issues
         BorderedFJMatrix::incons.  v0.1.2 had no inconsistent branch
         and could loop into a false gauge verdict.

     C9  Summary-box coherence on every halt.  The structural counters
         ("ExtendedMatrixRank", "ConsistencyCheck", "OneFormLength",
         "VariablesLength") and the matrix itself were written only on
         extension passes, so a system halting at the FIRST pass
         displayed Missing[KeyAbsent, ...]; a first-pass regular system
         even broke DetermineRegularizationStatus, which looked up the
         never-stored "ExtendedMatrix".  All halts now record the
         halt-stage matrix, its rank and the counters, and the renderer
         degrades a missing value to an em-dash.

     C10 Every halt stores "ExtendedMatrix" -> f^(m)
         ("PartialExtendedMatrix" survives as an alias), and candidates
         discarded as weakly zero are accumulated under
         "RedundantConstraints" instead of surviving only as prose.
         "ConstraintsPerStage" records how many constraints were
         adjoined in each round, which together with
         (IterationCount, PassCount, MultiplierCount) resolves the
         rounds-versus-multipliers accounting.

     C11 Reload hygiene.  The public symbols carried the Locked
         attribute, which forbids Unprotect: re-loading the package in a
         live kernel failed at the Unprotect/ClearAll header.  Locked is
         dropped; ReadProtected and Protected are kept.

     C12 Ergonomics.  BorderedFJMatrix accepts a declarative
         Association <|"kinetic-energy" -> ..., "symplectic-potential"
         -> ..., "vars" -> ...|> (the rule is guarded by those three
         keys, so the inert result wrapper is never re-evaluated); the
         option "TraceStages" records a per-pass trace under
         "StageData"; FJSymplecticFrame validates the presence of
         "InverseExtendedMatrix" against the association itself and
         issues FJSymplecticFrame::noinv instead of returning a bare
         string.

     Deliberately NOT ported from the companion engine: gauge generator
     records, canonical charges, independence and degeneracy analysis,
     GaugeReport, FaddeevJackiwLagrangian, the comparison utilities and
     the extended ToSubscript formatter.
*)

BeginPackage["BorderedFJReduction`"];

Unprotect @@ Names["BorderedFJReduction`*"];
ClearAll @@ Names["BorderedFJReduction`*"];

(* =====================USAGE MESSAGES===================== *)

BorderedFJMatrix::usage =
"BorderedFJMatrix[kinetic, potential, vars, opts] performs the symbolic \
Faddeev-Jackiw reduction of the first-order Lagrangian L = kinetic - \
potential over the phase-space variables vars, using geometrically \
constrained matrix bordering, and returns an opaque symbolic object \
queryable by key (see \"Properties\"). The recursion stops when the \
extended matrix is regularized, when an inconsistency is produced, or \
when it stalls on a kernel whose consistency contractions vanish \
weakly, in which case a GAUGE CANDIDATE is reported \
(\"GaugeSymmetry\" -> \"CandidateFound\"); no gauge generator is \
constructed or verified. BorderedFJMatrix[<|\"kinetic-energy\" -> ..., \
\"symplectic-potential\" -> ..., \"vars\" -> ...|>, opts] is \
equivalent. Options: \"MaxIterations\" (5, bounds bordering rounds) and \
\"TraceStages\" (False).";

FaddeevJackiwMatrix::usage =
"FaddeevJackiwMatrix[oneForm, vars] constructs the pre-symplectic matrix \
f_ij = D[a_j, vars_i] - D[a_i, vars_j] associated with a first-order \
Lagrangian whose canonical one-form has components oneForm.";

FJSymplecticFrame::usage =
"FJSymplecticFrame[obj, divColor, backColor] displays a labeled \
visualization of the inverse extended symplectic matrix (the \
generalized brackets) of a regularized BorderedFJMatrix object.";

ToSubscript::usage =
"ToSubscript[expr] converts symbolic variable names into subscripted \
form for display purposes. The function is Listable.";

(* =====================MESSAGES===================== *)

BorderedFJMatrix::iter =
"After `1` bordering round(s), the Faddeev-Jackiw matrix remains \
unregularized. Try increasing \"MaxIterations\".";

BorderedFJMatrix::lin =
"The kinetic energy is not linear in the velocities Derivative[1][q]; \
the Lagrangian is not first-order.";

BorderedFJMatrix::nonpoly =
"Non-algebraic constraint data (beyond polynomial or trigonometric \
polynomial form): ideal-membership tests fall back to generic gradient \
rank over the function field. Redundancy and candidate verdicts are \
generic, not ideal-theoretic.";

BorderedFJMatrix::incons =
"Inconsistent system: the consistency condition generated the \
nonvanishing variable-free constraint `1`.";

BorderedFJMatrix::maxit =
"The value `1` of \"MaxIterations\" is not a positive integer or \
Infinity.";

FJSymplecticFrame::noinv =
"The object carries no \"InverseExtendedMatrix\": generalized brackets \
exist only for a regularized reduction.";

Options[BorderedFJMatrix] = {
  "MaxIterations" -> 5,   (* bounds BORDERING ROUNDS, not passes *)
  "TraceStages"   -> False
};

(* =====================IMPLEMENTATION===================== *)

Begin["`Private`"];

ClearAll @@ Names["BorderedFJReduction`Private`*"];

(* The non-algebraic fallback notice is emitted at most once per driver
   run; the driver resets the flag. *)
$NonPolyNotified = False;

notifyNonPoly[] := If[! TrueQ[$NonPolyNotified],
  Message[BorderedFJMatrix::nonpoly];
  $NonPolyNotified = True
];

(* Property lists advertised by each halt.  Only keys actually stored
   are advertised: a "Properties" entry pointing to an absent key is a
   documentation bug, not a feature. *)
$regularProperties = {
  "Constraints", "ExtendedMatrix", "ExtendedMatrixRank", "ExtendedOneForm",
  "ExtendedSymplecticVariables", "InverseExtendedMatrix", "IterationCount",
  "PassCount", "ConstraintsPerStage", "MultiplierCount",
  "RedundantConstraints", "MatrixStatus", "Diagnostics", "StageData"
};

$candidateProperties = {
  "Constraints", "ExtendedMatrix", "ExtendedMatrixRank", "ExtendedOneForm",
  "ExtendedSymplecticVariables", "GaugeSymmetry", "GaugeCandidateBranch",
  "GaugeCandidateReason", "GaugeCandidateMethod", "KernelDimension",
  "CandidateMultiplicity", "GaugeAnalysis", "IterationCount", "PassCount",
  "ConstraintsPerStage", "MultiplierCount", "RedundantConstraints",
  "MatrixStatus", "Diagnostics", "StageData"
};

$inconsistentProperties = {
  "Constraints", "ExtendedMatrix", "ExtendedMatrixRank", "ExtendedOneForm",
  "ExtendedSymplecticVariables", "InconsistencyWitness", "IterationCount",
  "PassCount", "ConstraintsPerStage", "MultiplierCount",
  "RedundantConstraints", "MatrixStatus", "Diagnostics", "StageData"
};

$noGaugeAnalysis = Missing["NotAvailable",
  "Gauge generators are out of scope for BorderedFJReduction: this \
engine identifies candidates only."];

(*==================================================================*)
(*  Main function 1: the driver                                     *)
(*==================================================================*)

BorderedFJMatrix[kineticEnergy_, symplecticPotential_, vars_List,
    OptionsPattern[]] := Module[
  {maxIterations, traceQ, velocities, oneForm, potentialDerivatives,
   initialSystem, stepFunction, finalSystem, regularizationStatus},

  maxIterations = OptionValue["MaxIterations"];
  traceQ        = TrueQ @ OptionValue["TraceStages"];

  If[! Or[SameQ[maxIterations, Infinity],
          And[IntegerQ[maxIterations], Positive[maxIterations]]],
    Message[BorderedFJMatrix::maxit, maxIterations];
    Return[$Failed]
  ];

  (* C3: the one-form must exhaust the kinetic term. *)
  velocities = Map[Derivative[1], vars];
  oneForm    = Simplify[Map[Coefficient[kineticEnergy, #] &, velocities]];
  If[Or[! FreeQ[oneForm, Derivative[1][_]],
        ! PossibleZeroQ @ Simplify[kineticEnergy - oneForm . velocities]],
    Message[BorderedFJMatrix::lin];
    Return[$Failed]
  ];

  potentialDerivatives = Map[D[symplecticPotential, #] &, vars];

  $NonPolyNotified = False;

  initialSystem = <|
    "ExtendedSymplecticVariables" -> vars,
    "ExtendedOneForm"             -> oneForm,
    "Constraints"                 -> {},
    "IterationCount"              -> 0,
    "PassCount"                   -> 0,
    "GaugeSymmetry"               -> "NotCandidateFound",
    "GaugeCheck"                  -> "None",
    "Halt"                        -> None,
    "RedundantConstraints"        -> {},
    "ConstraintsPerStage"         -> {},
    "MultiplierCount"             -> 0,
    "StageData"                   -> {},
    "Diagnostics"                 -> {},
    "TraceStages"                 -> traceQ
  |>;

  stepFunction = BFJStep[kineticEnergy, symplecticPotential, vars,
    potentialDerivatives, traceQ];

  (* C2: no look-ahead evaluation; the halt lives in the state.  The
     readout pass after the last allowed bordering round is granted
     before declaring failure. *)
  finalSystem = NestWhile[stepFunction, initialSystem,
    Function[current,
      And[SameQ[Lookup[current, "Halt", None], None],
          Less[Lookup[current, "IterationCount", 0], maxIterations]]]];

  If[SameQ[Lookup[finalSystem, "Halt", None], None],
    finalSystem = stepFunction @ finalSystem
  ];

  If[SameQ[Lookup[finalSystem, "Halt", None], None],
    Message[BorderedFJMatrix::iter, maxIterations];
    Return[$Failed]
  ];

  regularizationStatus = DetermineRegularizationStatus @ finalSystem;

  If[SameQ[regularizationStatus, "NotRegularized"],
    Message[BorderedFJMatrix::iter, maxIterations];
    Return[$Failed]
  ];

  BorderedFJMatrix @ FilterNullConstraints @
    Append[finalSystem, "MatrixStatus" -> regularizationStatus]
];

(* C12: declarative interface.  The guard on the three system keys is
   essential: the engine's own result is the INERT expression
   BorderedFJMatrix[resultAssociation], which must not be re-evaluated
   by this rule (result associations never carry "kinetic-energy"). *)
BorderedFJMatrix[system_Association, opts___Rule] /;
    AllTrue[{"kinetic-energy", "symplectic-potential", "vars"},
      KeyExistsQ[system, #] &] :=
  BorderedFJMatrix[system["kinetic-energy"], system["symplectic-potential"],
    system["vars"], opts];

(* Accessor for the association wrapped in the head BorderedFJMatrix. *)
BorderedFJMatrix[assoc_Association][key_] := assoc @ key;

(* Final status.  Reads the halt, never re-derives it. *)
DetermineRegularizationStatus[system_] :=
  Switch[Lookup[system, "Halt", None],
    "GaugeCandidate", "GaugeCandidate",
    "Inconsistent",   "Inconsistent",
    _,
      If[SameQ[MatrixRank @ Lookup[system, "ExtendedMatrix"],
               Length @ Lookup[system, "ExtendedSymplecticVariables"]],
        "Regularized", "NotRegularized"]
  ];

(* Post-processing: filters constraints that simplify to 0.  With C4 the
   zeros are already discarded during the step; this is kept as a safety
   net so the v0.1.2 output contract is preserved verbatim. *)
FilterNullConstraints[system_] := Module[
  {cleanedConstraints, cleanedConstraintsLength},
  cleanedConstraints = Select[Lookup[system, "Constraints"], UnsameQ[#, 0] &];
  cleanedConstraintsLength = Length @ cleanedConstraints;
  Join[system,
    <|"Constraints"       -> cleanedConstraints,
      "ConstraintsLength" -> cleanedConstraintsLength|>]
];

(*==================================================================*)
(*  BFJStep: one pass of the bordered reduction                     *)
(*==================================================================*)

BFJStep[kineticEnergy_, symplecticPotential_, vars_, potentialDerivatives_,
    traceQ_ : False][system_] := Module[
  {oneForm, constraints, extMatrix, nullSpace, classification, rawPhiList,
   nonzeroPhi, zeroEvents, diagnostics, inconsistentWitness, novelty,
   novelPhi, redundantPhi, result, currentPass, extendedOneForm,
   extendedVariables, extendedMatrix},

  (* C2: idempotent on halted states. *)
  If[UnsameQ[Lookup[system, "Halt", None], None], Return[system]];

  (* 1. Extract system data *)
  {oneForm, constraints} = extractSystemData @ system;

  (* 2. Compute the extended matrix f^(m) *)
  extMatrix = computeExtendedMatrix[system, oneForm, vars];

  (* 3. Compute its kernel *)
  nullSpace = computeNullSpace @ extMatrix;

  (* Empty kernel: regular halt (a readout pass, not a round). *)
  If[SameQ[Length @ nullSpace, 0],
    result = updateSystemIteration[system, extMatrix];
    Return @ updateInverseExtendedMatrix[result, extMatrix]
  ];

  (* 3b. Structural classification of the null vectors into transient
     (constraint-generating) and persistent (candidate) modes. *)
  classification = classifyNullVectors[nullSpace, vars, potentialDerivatives];
  rawPhiList     = classification["Contractions"];

  result      = Append[Association @ system,
    "PassCount" -> Lookup[system, "PassCount", 0] + 1];
  currentPass = Lookup[result, "PassCount", 0];
  If[traceQ,
    result = recordStage[result, currentPass, nullSpace, classification]
  ];

  (* 4. Every contraction identically zero: ZeroContraction candidate. *)
  If[allConstraintsZeroQ[rawPhiList],
    Return @ setGaugeCandidateZero[result, extMatrix, nullSpace]
  ];

  (* C4: discard identically-zero candidates; never border with them. *)
  nonzeroPhi  = Select[rawPhiList, ! PossibleZeroQ[Simplify[#]] &];
  zeroEvents  = Length[rawPhiList] - Length[nonzeroPhi];
  diagnostics = Lookup[result, "Diagnostics", {}];
  If[Positive[zeroEvents],
    diagnostics = Append[diagnostics, StringJoin[
      "Null constraint event (x", ToString @ zeroEvents,
      "): consistency identically satisfied along part of the kernel."]]
  ];

  (* C8: inconsistency detection. *)
  inconsistentWitness = SelectFirst[nonzeroPhi,
    FreeQ[#, Alternatives @@ vars] &, Missing["NoWitness"]];
  If[! MissingQ[inconsistentWitness],
    Message[BorderedFJMatrix::incons, inconsistentWitness];
    Return @ setInconsistentHalt[result, extMatrix, inconsistentWitness,
      diagnostics]
  ];

  (* 5. C5: constraint novelty by ideal membership. *)
  novelty      = constraintNoveltySplit[constraints, nonzeroPhi, vars];
  novelPhi     = novelty["Novel"];
  redundantPhi = novelty["Redundant"];
  If[Positive[Length @ redundantPhi],
    diagnostics = Append[diagnostics, StringJoin[
      "Redundant constraint event (x", ToString[Length @ redundantPhi],
      ", method ", novelty["Method"],
      "): candidate lies in the ideal of the accumulated constraints."]];
    result = Append[result, "RedundantConstraints" ->
      Join[Lookup[result, "RedundantConstraints", {}], redundantPhi]]
  ];
  result = Append[result, "Diagnostics" -> diagnostics];

  (* Every informative candidate is redundant: DependentConstraints
     candidate branch. *)
  If[SameQ[novelPhi, {}],
    Return @ setGaugeCandidateDependent[result, extMatrix, nullSpace, vars,
      potentialDerivatives, constraints]
  ];

  (* 6. Border with the novel constraints only. *)
  {extendedOneForm, extendedVariables, extendedMatrix} =
    computeExtendedObjects[result, novelPhi, vars];

  (* 7. Update the system with the new extended objects. *)
  result = updateExtendedSystem[result, novelPhi, extendedOneForm,
    extendedVariables, extendedMatrix];

  (* 8. Generalized brackets, if the round already regularized f^(m). *)
  updateInverseExtendedMatrix[result, extendedMatrix]
];

(*------------------------------------------------------------------*)
(*  Helper functions for BFJStep                                    *)
(*------------------------------------------------------------------*)

extractSystemData[system_] := {
  Lookup[system, "ExtendedOneForm"],
  Lookup[system, "Constraints"]
};

(* Main function 2: the pre-symplectic (Faddeev-Jackiw) matrix. *)
FaddeevJackiwMatrix[oneForm_, vars_] := Simplify[
  Transpose[Outer[D, oneForm, vars]] - Outer[D, oneForm, vars]
];

computeExtendedMatrix[system_, oneForm_, vars_] := Lookup[system,
  "ExtendedMatrix",
  FaddeevJackiwMatrix[oneForm, vars]
];

computeNullSpace[matrix_] := NullSpace @ matrix;

(* Regular halt (C9): stores the halt-stage matrix and the structural
   counters, so the state is coherent even when the system is regular at
   the FIRST pass and no extension ever ran. *)
updateSystemIteration[system_, extMatrix_] := Module[
  {res = Association @ system},
  res = Append[res, "PassCount" -> Lookup[res, "PassCount", 0] + 1];
  res = Append[res, "GaugeSymmetry" -> "NotCandidateFound"];
  res = Append[res, "ExtendedMatrix" -> extMatrix];
  res = Append[res, "ExtendedMatrixRank" -> MatrixRank[extMatrix]];
  res = Append[res, "ConsistencyCheck" -> True];
  res = Append[res, "OneFormLength" ->
    Length @ Lookup[res, "ExtendedOneForm", {}]];
  res = Append[res, "VariablesLength" ->
    Length @ Lookup[res, "ExtendedSymplecticVariables", {}]];
  Append[res, "Halt" -> "Regular"]
];

(* C7: globally numbered multipliers.  The bordering keeps the -Omega
   sign convention of v0.1.2 (-newPhiList). *)
computeExtendedObjects[system_, newPhiList_, vars_] := Module[
  {oneForm, offset, newMultipliers, extendedOneForm, extendedVariables,
   extendedMatrix},
  oneForm = Lookup[system, "ExtendedOneForm"];
  offset  = Lookup[system, "MultiplierCount", 0];
  newMultipliers = Table[\[FormalLambda][offset + j], {j, Length @ newPhiList}];
  extendedOneForm   = Join[oneForm, -newPhiList];
  extendedVariables = Join[
    Lookup[system, "ExtendedSymplecticVariables"], newMultipliers];
  extendedMatrix = Simplify[
    Transpose[Outer[D, extendedOneForm, extendedVariables]] -
      Outer[D, extendedOneForm, extendedVariables]];
  {extendedOneForm, extendedVariables, extendedMatrix}
];

updateExtendedSystem[system_, newPhiList_, extendedOneForm_,
    extendedVariables_, extendedMatrix_] := Module[
  {res = Association @ system, constraints},
  constraints = Lookup[res, "Constraints"];
  res = Append[res, "ExtendedSymplecticVariables" -> extendedVariables];
  res = Append[res, "ExtendedOneForm" -> extendedOneForm];
  res = Append[res, "ExtendedMatrix" -> extendedMatrix];
  res = Append[res, "Constraints" -> Join[constraints, newPhiList]];
  res = Append[res, "ConsistencyCheck" -> True];
  res = Append[res, "ConstraintsLength" ->
    Length[Join[constraints, newPhiList]]];
  res = Append[res, "MultiplierCount" ->
    Lookup[res, "MultiplierCount", 0] + Length @ newPhiList];
  res = Append[res, "IterationCount" ->
    Lookup[res, "IterationCount", 0] + 1];
  res = Append[res, "ConstraintsPerStage" ->
    Append[Lookup[res, "ConstraintsPerStage", {}], Length @ newPhiList]];
  res = Append[res, "ExtendedMatrixRank" -> MatrixRank[extendedMatrix]];
  res = Append[res, "OneFormLength" -> Length[extendedOneForm]];
  Append[res, "VariablesLength" -> Length[extendedVariables]]
];

allConstraintsZeroQ[newPhiList_] :=
  AllTrue[newPhiList, PossibleZeroQ[Simplify[#]] &];

(*==================================================================*)
(*  Weak-vanishing toolkit                                          *)
(*==================================================================*)

(* Gradient rows over the function field.  Replaces the linear
   coefficients CoefficientArrays[..., vars][[2]] of v0.1.2, which
   captured only the linear part and silently degenerated to zero rows
   on non-polynomial (e.g. trigonometric) data.  Gradient rows are the
   correct generic linearization at a generic point and coincide with
   the linear coefficients on linear data. *)
gradientRows[exprList_, vars_] := Module[{nRows, nCols},
  nRows = Length @ exprList;
  nCols = Length @ vars;
  If[Or[SameQ[nRows, 0], SameQ[nCols, 0]],
    Return @ ConstantArray[0, {nRows, nCols}]];
  Map[Function[e, Map[D[e, #] &, vars]], exprList]
];

(* For polynomial data, redundancy is decided by the Groebner normal
   form: c lies in <phi_1, ..., phi_k> iff its remainder under
   PolynomialReduce with respect to a Groebner basis vanishes.
   GroebnerBasis treats all non-vars symbols as coefficients in the
   fraction field, so parametric dependence is preserved. *)
polynomialDataQ[exprList_, vars_] :=
  AllTrue[Flatten @ {exprList}, PolynomialQ[#, vars] &];

idealNormalForm[expr_, generators_List, vars_] := Module[{gb},
  If[SameQ[generators, {}], Return[Simplify @ expr]];
  gb = GroebnerBasis[generators, vars];
  Simplify @ Last @ PolynomialReduce[expr, gb, vars]
];

(* Coefficient rows of a list of polynomials in their joint monomial
   basis; the normal-form map is linear, so constant-coefficient ideal
   membership of a combination is the null space of this matrix. *)
monomialCoefficientMatrix[polys_List, vars_] := Module[
  {ruleSets, monomials},
  ruleSets  = Map[Association @ CoefficientRules[#, vars] &, polys];
  monomials = Union @@ Map[Keys, ruleSets];
  If[SameQ[monomials, {}],
    Return @ ConstantArray[0, {Length @ polys, 1}]];
  Map[Function[rules, Lookup[rules, monomials, 0]], ruleSets]
];

(* Exact algebraic model of an expression list: either the expressions
   are already polynomial in vars, or they are trigonometric
   polynomials, in which case Cos[v] -> c_i, Sin[v] -> s_i with the
   Pythagorean relations adjoined.  Membership modulo the relations in
   the extended ring is exactly weak vanishing on the torus of the
   physical phase space.  Missing["NotAlgebraic"] when no exact model
   exists. *)
algebraicModel[exprList_List, vars_List] := Module[{attempt},
  attempt = algebraicModelAttempt[exprList, vars];
  If[! MissingQ[attempt], Return @ attempt];
  (* compound angles (Cos[v1 - v2], ...) may atomize under TrigExpand *)
  algebraicModelAttempt[TrigExpand[exprList], vars]
];

algebraicModelAttempt[exprList_, vars_List] := Module[
  {args, cs, ss, rules, embedded, polyVars, relations},
  If[polynomialDataQ[exprList, vars],
    Return @ <|"Exprs" -> exprList, "Vars" -> vars, "Relations" -> {},
      "Method" -> "GroebnerNormalForm"|>];
  args = DeleteDuplicates @ Cases[exprList, (Sin | Cos)[a_] :> a, Infinity];
  If[Or[SameQ[args, {}], ! SubsetQ[vars, args]],
    Return @ Missing["NotAlgebraic"]];
  cs = Table[\[FormalC][i], {i, Length @ args}];
  ss = Table[\[FormalS][i], {i, Length @ args}];
  rules = Flatten @ Table[
    {Cos[args[[i]]] -> cs[[i]], Sin[args[[i]]] -> ss[[i]]},
    {i, Length @ args}];
  embedded = exprList /. rules;
  polyVars = Join[vars, cs, ss];
  If[! polynomialDataQ[embedded, polyVars],
    Return @ Missing["NotAlgebraic"]];
  relations = Table[cs[[i]]^2 + ss[[i]]^2 - 1, {i, Length @ args}];
  <|"Exprs" -> embedded, "Vars" -> polyVars, "Relations" -> relations,
    "Method" -> "TrigAlgebraicGroebner"|>
];

(* C5: constraint novelty split.  Incremental: each candidate is tested
   against the ideal of (accumulated constraints + previously accepted
   candidates).  Returns <|"Novel", "Redundant", "Method"|>. *)
constraintNoveltySplit[constraints_List, candidates_List, vars_] := Module[
  {model, method, acc, novel = {}, redundant = {}, remainder, rows, oldRank,
   polyVars, relations, embeddedCandidates},
  (* With no accumulated constraints and at most one candidate the
     membership question is trivial -- the candidate is already
     certified nonzero and variable-dependent upstream -- so both
     methods coincide exactly and no fallback notice is due. *)
  If[And[SameQ[constraints, {}], LessEqual[Length[candidates], 1]],
    Return @ <|"Novel" -> candidates, "Redundant" -> {},
      "Method" -> "TrivialNonzero"|>];
  model = algebraicModel[Join[constraints, candidates], vars];
  If[! MissingQ[model],
    (*--- exact path: polynomial or trigonometric-polynomial ideal ---*)
    method    = model["Method"];
    polyVars  = model["Vars"];
    relations = model["Relations"];
    embeddedCandidates = Drop[model["Exprs"], Length @ constraints];
    acc = Take[model["Exprs"], Length @ constraints];
    MapThread[
      Function[{c, ce},
        remainder = idealNormalForm[ce, Join[acc, relations], polyVars];
        If[PossibleZeroQ[remainder],
          AppendTo[redundant, c],
          AppendTo[novel, c]; AppendTo[acc, ce]]],
      {candidates, embeddedCandidates}],
    (*--- generic differential fallback ------------------------------*)
    method = "GenericGradientRank";
    notifyNonPoly[];
    acc = constraints;
    Do[
      rows    = gradientRows[Append[acc, c], vars];
      oldRank = If[SameQ[acc, {}], 0, MatrixRank @ gradientRows[acc, vars]];
      If[Greater[MatrixRank[rows], oldRank],
        AppendTo[novel, c]; AppendTo[acc, c],
        AppendTo[redundant, c]],
      {c, candidates}]
  ];
  <|"Novel" -> novel, "Redundant" -> redundant, "Method" -> method|>
];

(* Classify the null vectors into transient (constraint-generating) and
   persistent (candidate) modes by evaluating v.dV on the physical
   block. *)
classifyNullVectors[nullSpace_, vars_, potentialDerivatives_] := Module[
  {nVars, physicalBlock, contractions, mask, persistentIdx, transientIdx},
  nVars         = Length @ vars;
  physicalBlock = Take[nullSpace, All, nVars];
  contractions  = Simplify @ Dot[physicalBlock, potentialDerivatives];
  mask = Map[Function[c, TrueQ @ PossibleZeroQ @ Simplify @ c], contractions];
  persistentIdx = Flatten @ Position[mask, True];
  transientIdx  = Flatten @ Position[mask, False];
  <|
    "PhysicalBlock"     -> physicalBlock,
    "Contractions"      -> contractions,
    "PersistentIndices" -> persistentIdx,
    "TransientIndices"  -> transientIdx,
    "PersistentVectors" -> Part[nullSpace, persistentIdx],
    "TransientVectors"  -> Part[nullSpace, transientIdx]
  |>
];

(* C6: candidate multiplicity.  The constant combinations w with
   Sum_a w_a (v^(a).dV) in the ideal <phi_k> form a linear space; only
   its DIMENSION is reported.  The combinations themselves are the raw
   material of generator construction and are deliberately not exposed
   by this engine. *)
candidateKernelData[nullSpace_, vars_, potentialDerivatives_,
    existingConstraints_] := Module[
  {nVars, physicalBlock, contractions, model, generators, normalForms,
   coefficientMatrix, combinations, contractionRows, oldRows, augmented,
   leftNull},
  If[SameQ[Length @ nullSpace, 0],
    Return @ <|"Multiplicity" -> 0, "Method" -> "None"|>];
  nVars         = Length @ vars;
  physicalBlock = Take[nullSpace, All, nVars];
  contractions  = Simplify @ Dot[physicalBlock, potentialDerivatives];
  model = algebraicModel[Join[existingConstraints, contractions], vars];
  If[! MissingQ[model],
    (*--- ideal-theoretic path (exact, incl. trigonometric) ----------*)
    generators = Join[
      Take[model["Exprs"], Length @ existingConstraints],
      model["Relations"]];
    normalForms = Map[idealNormalForm[#, generators, model["Vars"]] &,
      Drop[model["Exprs"], Length @ existingConstraints]];
    combinations = If[AllTrue[normalForms, PossibleZeroQ],
      IdentityMatrix[Length @ nullSpace],
      coefficientMatrix =
        monomialCoefficientMatrix[normalForms, model["Vars"]];
      NullSpace @ Transpose @ coefficientMatrix];
    <|"Multiplicity" -> Length @ combinations,
      "Method"       -> model["Method"]|>,
    (*--- generic differential fallback ------------------------------*)
    notifyNonPoly[];
    contractionRows = gradientRows[contractions, vars];
    oldRows = If[SameQ[Length @ existingConstraints, 0],
      ConstantArray[0, {0, nVars}],
      gradientRows[existingConstraints, vars]];
    augmented = If[SameQ[Length @ oldRows, 0],
      contractionRows,
      Join[contractionRows, oldRows]];
    leftNull = NullSpace @ Transpose @ augmented;
    combinations = If[SameQ[Length @ leftNull, 0],
      {},
      (* drop the all-zero w-blocks contributed by internal dependencies
         of the constraint rows themselves (reducibility artifacts) *)
      DeleteCases[Take[leftNull, All, Length @ contractionRows], {0 ..}]];
    <|"Multiplicity" -> Length @ combinations,
      "Method"       -> "GenericGradientRows"|>
  ]
];

(* Per-pass trace, enabled by "TraceStages". *)
recordStage[system_, pass_, nullSpace_, classification_] := Module[
  {prior, entry},
  prior = Lookup[system, "StageData", {}];
  entry = <|
    "Pass"              -> pass,
    "IterationCount"    -> Lookup[system, "IterationCount", 0],
    "NullSpace"         -> nullSpace,
    "PersistentIndices" -> classification["PersistentIndices"],
    "TransientIndices"  -> classification["TransientIndices"],
    "Contractions"      -> classification["Contractions"]
  |>;
  Append[Association @ system, "StageData" -> Append[prior, entry]]
];

(*==================================================================*)
(*  Halting branches                                                *)
(*==================================================================*)

(* Shared structural bookkeeping written on every halt (C9/C10). *)
haltBookkeeping[system_, extendedMatrix_] := <|
  "PartialExtendedMatrix" -> extendedMatrix,   (* deprecated alias *)
  "ExtendedMatrix"        -> extendedMatrix,
  "ExtendedMatrixRank"    -> MatrixRank[extendedMatrix],
  "OneFormLength"         ->
    Length @ Lookup[Association @ system, "ExtendedOneForm", {}],
  "VariablesLength"       ->
    Length @ Lookup[Association @ system,
      "ExtendedSymplecticVariables", {}]
|>;

(* Candidate branch A: every consistency contraction of the kernel of
   f^(m) vanishes identically. *)
setGaugeCandidateZero[system_, extendedMatrix_, nullSpace_] := Module[
  {stage, reason, base},
  stage  = ToString @ Lookup[Association @ system, "IterationCount", 0];
  reason = StringJoin[
    "Null constraint event at stage f^(", stage, "): every consistency ",
    "contraction of the ", ToString @ Length @ nullSpace,
    "-dimensional kernel vanishes identically. This is a gauge ",
    "CANDIDATE; no generator is constructed or verified by this engine."];
  base = Join[Association @ system,
    haltBookkeeping[system, extendedMatrix],
    <|
      "GaugeSymmetry"         -> "CandidateFound",
      "Halt"                  -> "GaugeCandidate",
      "GaugeCandidateBranch"  -> "ZeroContraction",
      "GaugeCandidateReason"  -> reason,
      "GaugeDetectionReason"  -> reason,     (* deprecated alias *)
      "GaugeCandidateMethod"  -> "ZeroContraction",
      "GaugeCheck"            -> "ZeroContraction",
      "KernelDimension"       -> Length @ nullSpace,
      "CandidateMultiplicity" -> Length @ nullSpace,
      "GaugeAnalysis"         -> $noGaugeAnalysis,
      "ConsistencyCheck"      -> True
    |>];
  Append[base, "Properties" -> $candidateProperties]
];

(* Candidate branch B: every informative candidate constraint lies in
   the ideal of the accumulated constraints. *)
setGaugeCandidateDependent[system_, extendedMatrix_, nullSpace_, vars_,
    potentialDerivatives_, existingConstraints_] := Module[
  {stage, kernelData, reason, base},
  stage      = ToString @ Lookup[Association @ system, "IterationCount", 0];
  kernelData = candidateKernelData[nullSpace, vars, potentialDerivatives,
    existingConstraints];
  reason = StringJoin[
    "Dependent constraint event at stage f^(", stage, "): every ",
    "informative candidate of the ", ToString @ Length @ nullSpace,
    "-dimensional kernel lies in the ideal of the accumulated ",
    "constraints (method ", kernelData["Method"], "). This is a gauge ",
    "CANDIDATE; no generator is constructed or verified by this engine."];
  base = Join[Association @ system,
    haltBookkeeping[system, extendedMatrix],
    <|
      "GaugeSymmetry"         -> "CandidateFound",
      "Halt"                  -> "GaugeCandidate",
      "GaugeCandidateBranch"  -> "DependentConstraints",
      "GaugeCandidateReason"  -> reason,
      "GaugeDetectionReason"  -> reason,     (* deprecated alias *)
      "GaugeCandidateMethod"  -> kernelData["Method"],
      "GaugeCheck"            -> kernelData["Method"],
      "KernelDimension"       -> Length @ nullSpace,
      "CandidateMultiplicity" -> kernelData["Multiplicity"],
      "GaugeAnalysis"         -> $noGaugeAnalysis,
      "ConsistencyCheck"      -> True
    |>];
  Append[base, "Properties" -> $candidateProperties]
];

(* C8: inconsistent halt. *)
setInconsistentHalt[system_, extendedMatrix_, witness_, diagnostics_] :=
  Module[{base},
    base = Join[Association @ system,
      haltBookkeeping[system, extendedMatrix],
      <|
        "Halt"                 -> "Inconsistent",
        "GaugeSymmetry"        -> "NotCandidateFound",
        "InconsistencyWitness" -> witness,
        "ConsistencyCheck"     -> False,
        "Diagnostics"          -> diagnostics
      |>];
    Append[base, "Properties" -> $inconsistentProperties]
  ];

(*------------------------------------------------------------------*)
(*  Inverse of the extended matrix (generalized brackets)           *)
(*------------------------------------------------------------------*)

updateInverseExtendedMatrix[system_, extendedMatrix_] := Module[
  {res = Association @ system, invMatrix},
  Which[
    (* A candidate was reported: no brackets.  Cheapest test first. *)
    SameQ[Lookup[res, "GaugeSymmetry", "NotCandidateFound"],
      "CandidateFound"],
    res,
    (* Already inverted at this very stage: the extension pass and the
       readout pass see the same f^(m), and a symbolic Inverse followed
       by Simplify is the dominant cost of the whole reduction. *)
    And[KeyExistsQ[res, "InverseExtendedMatrix"],
        SameQ[Lookup[res, "ExtendedMatrix", None], extendedMatrix]],
    Append[res, "Properties" -> $regularProperties],
    (* Still singular: the recursion has not finished. *)
    Less[MatrixRank @ extendedMatrix, Length @ extendedMatrix],
    res,
    (* Regular: compute the generalized brackets. *)
    True,
    invMatrix = Quiet @ Simplify @ Inverse @ extendedMatrix;
    res = Append[res, "InverseExtendedMatrix" -> invMatrix];
    res = Append[res, "GaugeSymmetry" -> "NotCandidateFound"];
    Append[res, "Properties" -> $regularProperties]
  ]
];

(*==================================================================*)
(*  Presentation layer                                              *)
(*==================================================================*)

BorderedFJMatrix /: MakeBoxes[ifun : BorderedFJMatrix[assoc_Association],
    fmt_] := BoxForm`ArrangeSummaryBox[
  BorderedFJMatrix, ifun, myicon,
  {
    mylabel["ExtendedMatrixRank", assoc @ "ExtendedMatrixRank"],
    mylabel["GaugeSymmetry", assoc @ "GaugeSymmetry"]
  },
  {
    mylabel["MatrixStatus", assoc @ "MatrixStatus"],
    mylabel["ConsistencyCheck", assoc @ "ConsistencyCheck"],
    mylabel["ConstraintsLength", assoc @ "ConstraintsLength"],
    mylabel["OneFormLength", assoc @ "OneFormLength"],
    mylabel["VariablesLength", assoc @ "VariablesLength"],
    mylabel["IterationCount", assoc @ "IterationCount"],
    mylabel["PassCount", assoc @ "PassCount"]
  },
  fmt
];

(* Icon for summary box display *)
myicon := MatrixPlot[
  {{1, 1, 2}, {3, 5, 8}, {13, 21, 34}},
  ColorRules -> {0 -> LightOrange, 1 -> Purple, 2 -> LightBlue},
  Frame -> False,
  ImageSize -> Dynamic[
    {Automatic,
     Times[3.5,
       CurrentValue["FontCapHeight"] / AbsoluteCurrentValue[Magnification]]}],
  AspectRatio -> 1
];

(* Label function for the summary box.  C9: a missing value degrades to
   an em-dash instead of printing Missing[KeyAbsent, ...]. *)
mylabel[lbl_, v_] := Row @ {
  Style[StringJoin[lbl, ": "], "SummaryItemAnnotation"],
  Style[If[MissingQ @ v, "\[LongDash]", ToString @ v], "SummaryItem"]
};

(*==================================================================*)
(*  Main function 3: ToSubscript                                    *)
(*==================================================================*)

ToSubscript[sym_Symbol] /; UnsameQ[Context @ sym, "System`"] := Fold[
  ReverseApplied @ Subscript,
  Reverse @ ToExpression @ Characters @ ToString @ sym
];

ToSubscript[expr_] /; SameQ[Head @ expr, Subscript] := expr;

(* Fallback: anything not covered above is returned unchanged, so the
   function never leaks unevaluated heads into typeset output. *)
ToSubscript[expr_] := expr;

SetAttributes[ToSubscript, Listable];

(*==================================================================*)
(*  Main function 4: FJSymplecticFrame                              *)
(*==================================================================*)

FJSymplecticFrame[BorderedFJMatrix[assoc_Association],
    divColor_ : Darker @ Blue, backColor_ : LightBlue] := Module[
  {mat, vars, labels, newMat, divStyle, grd},
  If[! KeyExistsQ[assoc, "InverseExtendedMatrix"],
    Message[FJSymplecticFrame::noinv];
    Return[$Failed]
  ];
  mat  = assoc @ "InverseExtendedMatrix";
  vars = assoc @ "ExtendedSymplecticVariables";
  labels = ToSubscript[
    ReplaceAll[vars, sym_Symbol[n_] :> Subscript[sym, n]]];
  newMat   = Prepend[MapThread[Prepend, {mat, labels}], Prepend[labels, ""]];
  divStyle = Directive[divColor, Dashed, Thickness @ 1];
  grd = Grid[newMat,
    Alignment  -> Center,
    Dividers   -> {{2 -> divStyle}, {2 -> divStyle}},
    Background -> {1 -> backColor, 1 -> backColor},
    ItemStyle  -> Automatic];
  MatrixForm @ {{grd}}
];

End[];

Protect @@ Names["BorderedFJReduction`*"];

(* C11: ReadProtected and Protected only.  Locked would forbid the
   Unprotect at the head of this file, breaking every reload. *)
SetAttributes[BorderedFJMatrix,     {ReadProtected, Protected}];
SetAttributes[FaddeevJackiwMatrix,  {ReadProtected, Protected}];
SetAttributes[ToSubscript,          {ReadProtected, Protected}];
SetAttributes[FJSymplecticFrame,    {ReadProtected, Protected}];

EndPackage[];
