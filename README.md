# BorderedFJReduction
Symbolic engine for the Faddeev–Jackiw reduction based on geometrically constrained matrix bordering.

___

📦 BorderedFJReduction
<p align="center"> <img src="assets/BFJ_logo.png" alt="BorderedFJReduction logo" width="180"/> </p> <p align="center"> <b>A symbolic engine for the Faddeev–Jackiw reduction of singular Lagrangians,<br> grounded in geometrically constrained matrix bordering.</b> </p>

___

## 🔍 Overview

BorderedFJReduction is a Wolfram Language paclet that provides a fully symbolic implementation of the Faddeev–Jackiw (FJ) reduction for singular Lagrangian systems.

The core contribution of this project is the realization that the FJ iterative extension of phase space is not a heuristic procedure, but a geometrically constrained instance of the Matrix Bordering Technique (MBT).
This insight enables a deterministic, transparent, and automatable reduction process, preserving full parametric dependence throughout the computation.

The engine returns an opaque symbolic object encapsulating the complete symplectic hierarchy, while exposing its internal structure through a controlled, queryable interface.

___

## ✨ Key Features

- Fully symbolic Faddeev–Jackiw reduction

- Matrix Bordering–based formulation (theorem-driven, not procedural)

- Automatic detection of:

- Regular symplectic manifolds

- Constraint hierarchies

- Gauge symmetries (null or dependent constraints)

- Preservation of parametric dependence (essential for bifurcation and stability analysis)

- Structured output via Wolfram SummaryBox

- Queryable association interface for downstream analysis

- Publication-ready visualization of Dirac brackets

___

## 📐 Conceptual Architecture

The reduction process is internally organized as a causal graph of symbolic states, rather than a linear algorithm.
Each iteration corresponds to a bordered extension of the symplectic 2-form until regularity or gauge redundancy is detected.

This mirrors the interpretation developed in the accompanying manuscript:

> The Faddeev–Jackiw procedure is a geometrically constrained matrix bordering process acting on symbolic symplectic data.
___

## 🚀 Installation
### Option 1: Install directly from GitHub (recommended)

```mathematica
PacletInstall[
  "https://github.com/RECHAN-DYNAMICS/BorderedFJReduction/raw/main/BorderedFJReduction-0.1.0.paclet",
  ForceVersionInstall -> True
]
```
Then load the package:

```mathematica
Needs["BorderedFJReduction`"]
```
### Option 2: Local installation (development)

```mathematica
PacletInstall["/path/to/BorderedFJReduction-0.1.0.paclet"]
```
___

## 🧪 Basic Usage

```mathematica
bfj = BorderedFJMatrix[kinetic, potential, vars];
```
The returned object is **opaque** by design, but fully queryable:

```mathematica
bfj["Constraints"]
bfj["ExtendedMatrix"]
bfj["ExtendedOneForm"]
bfj["ExtendedSymplecticVariables"]
bfj["InverseExtendedMatrix"]
bfj["IterationCount"]
bfj["MatrixStatus"]
```
To visualize the Dirac brackets in a structured, publication-ready format:

```mathematica
FJSymplecticFrame[bfj]
```
___

## 🧭 Gauge Symmetry Detection

If the reduction fails to reach a regular symplectic manifold, the engine automatically diagnoses gauge redundancy:

- **Null constraints** (identically zero)

- **Dependent constraints** (no further restriction of phase space)

In such cases, the final pre-symplectic matrix and its null vectors are preserved, providing direct access to the generators of gauge transformations.

___

## 📚 Scientific Context

This package accompanies the theoretical development presented in:

> **Faddeev–Jackiw Reduction of Singular Lagrangians:
A Matrix Bordering Approach with Symbolic Implementation**

The implementation has been validated on:

- The Hojman–Urrutia model

- Singular mechanical systems analyzed within the Dirac–Bergmann framework

- Systems exhibiting gauge symmetry

___

## 👥 Authors

- Ramón Eduardo Chan López

- José Alberto Martín Ruiz

- Jaime Manuel Cabrera

- Jorge Mauricio Paulin Fuentes

___

## 🔮 Future Directions

The current engine targets finite-dimensional systems (point mechanics).
However, its algebraic architecture is designed as a kernel for future extensions toward:

- Field theories

- Symbolic tensor calculus

- Infinite-dimensional constraint surfaces

- Gauge theories (Maxwell, Yang–Mills)

The long-term vision is a Tensor Faddeev–Jackiw Engine, where constraint handling emerges directly from the algebraic structure of the symplectic form.

___

## 📄 License

This project is released for academic and research use.
License details will be specified upon stable release.

___

## ⭐ A note to reviewers

This repository is not merely a code base.
It is a computational manifestation of a structural theorem, designed to make constrained Hamiltonian dynamics transparent, reproducible, and symbolically inspectable.
