(* ::Package:: *)

(* ::Package:: *)

(*Load the main package*)
Get["BorderedFJReduction`BorderedFJReduction`"]
(*Welcome!*)
With[
	{
		icon = Graphics[
			{
				Antialiasing -> True, RGBColor[0.2, 0.4, 0.6],
				Disk[{0, 0}, 1.95],
				White, Thickness @ 0.08, Circle[{0, 0}, 1.75, {0.15 * Pi, 1.85 * Pi}],
				White, Text[
					Style["BFJ",
						FontFamily -> "Source Sans Pro", FontWeight -> "Bold", FontSize -> 28
					],
					{0, -0.05}
				]
			},
			ImageSize -> 70, Background -> None
		]
	},
	Print[
		Panel[
			Column[
				{
					Grid[
						{
							{
								Show @ icon,
								Column[
									{
										Style[
											"BorderedFJReduction", "Section", FontSize -> 24, FontFamily -> "Source Sans Pro",
											FontColor -> RGBColor[0.2, 0.4, 0.6],
											Bold
										],
										Style[
											"A symbolic engine for the Faddeev\[Dash]Jackiw reduction of singular Lagrangians,\nformulated as a geometrically constrained instance of matrix bordering.",
											12, Italic, FontFamily -> "Source Sans Pro"
										]
									},
									Alignment -> Left, Spacings -> 0.2
								]
							}
						},
						Alignment -> {Left, Center},
						Spacings -> {1.5, 0}
					],
					Graphics[
						{GrayLevel @ 0.85, Thickness @ 0.002, Line @ {{0, 0}, {1, 0}}},
						ImageSize -> {550, 8},
						AspectRatio -> Full
					],
					Row @ {
						Style["Scope: ", 10, GrayLevel @ 0.45, Bold],
						Style[
							"regularization, weak-vanishing constraint analysis, and structural identification of gauge candidates.",
							10, GrayLevel @ 0.45, FontFamily -> "Source Sans Pro"
						]
					},
					Style[
						"Gauge generators are not constructed or verified by this engine.",
						10, Italic, GrayLevel @ 0.45, FontFamily -> "Source Sans Pro"
					],
					Graphics[
						{GrayLevel @ 0.85, Thickness @ 0.002, Line @ {{0, 0}, {1, 0}}},
						ImageSize -> {550, 8},
						AspectRatio -> Full
					],
					Column[
						{
							Style["Authored by:", 10, GrayLevel @ 0.5, Bold],
							Style[
								"Ram\[OAcute]n Eduardo Chan L\[OAcute]pez \[CenterDot] Jos\[EAcute] Alberto Mart\[IAcute]n Ruiz", 11, FontFamily -> "Source Sans Pro"
							],
							Style[
								"Jaime Manuel Cabrera \[CenterDot] Jorge Mauricio Paulin Fuentes", 11, FontFamily -> "Source Sans Pro"
							]
						},
						Alignment -> Center, Spacings -> 0.3
					],
					Column[
						{
							Style[
								"BorderedFJReduction v0.1.3", 10, GrayLevel @ 0.6, Bold,
								FontFamily -> "Source Sans Pro"
							],
							Row @ {
								Style["Latest Release  |  ", 10, GrayLevel @ 0.6],
								Style[
									StringJoin["Mathematica ", ToString @ $VersionNumber, "  |  "],
									10, GrayLevel @ 0.6
								],
								Style[
									DateString @ {"Day", " ", "MonthName", " ", "Year"},
									10, GrayLevel @ 0.6
								]
							}
						},
						Alignment -> Center, Spacings -> 0.3
					]
				},
				Alignment -> Center, Spacings -> 0.8
			],
			FrameMargins -> 25,
			Background -> GrayLevel[0.98],
			ImageSize -> {650, Automatic}
		]
	]
];
