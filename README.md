# BorderedFJReduction
Symbolic engine for the Faddeev–Jackiw reduction based on geometrically constrained matrix bordering.

___

📦 BorderedFJReduction
<p align="center"> <img src="assets/BFJ_logo.png" alt="BorderedFJReduction logo" width="180"/> </p> <p align="center"> <b>A symbolic engine for the Faddeev–Jackiw reduction of singular Lagrangians,<br> grounded in geometrically constrained matrix bordering.</b> </p>

___

🔍 Overview

BorderedFJReduction is a Wolfram Language paclet that provides a fully symbolic implementation of the Faddeev–Jackiw (FJ) reduction for singular Lagrangian systems.

The core contribution of this project is the realization that the FJ iterative extension of phase space is not a heuristic procedure, but a geometrically constrained instance of the Matrix Bordering Technique (MBT).
This insight enables a deterministic, transparent, and automatable reduction process, preserving full parametric dependence throughout the computation.

The engine returns an opaque symbolic object encapsulating the complete symplectic hierarchy, while exposing its internal structure through a controlled, queryable interface.
