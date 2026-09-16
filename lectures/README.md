# Lecture sources and organization

The class-meeting decks for Lauren's Units 4–7 use unit.meeting identifiers,
for example `lecture4.1.qmd`. The integer `order` field controls the listing;
calendar dates and preparation assignments remain in `2026/schedule.qmd`.

## Source map

| Deck | Main PowerPoint source | Added or expanded material |
|---|---|---|
| 4.1 | Unit 4, slides 3–22 | Cheng discussion; irrigation model; framework workshop |
| 4.2 | Unit 4, slides 23–28 | Chouinard writing guidance; theory-to-evidence workshop |
| 5.1 | Unit 5, slides 3–19 | Champ discussion; questionnaire exercise |
| 5.2 | Unit 5, slides 20–25 | Dominitz–Manski discussion; supplied ZBP/API materials |
| 5.3 | Unit 5, slides 26–30 | Git practice and reading discussion, Sections 1–4 |
| 5.4 | Unit 5, slides 31–33 | Keys, collaboration, management, and code-style exercises |
| 5.5 | Unit 5 themes | Data-reporting workshop from the course data checklists |
| 6.1 | Unit 6, slides 3–28 | Jurajda discussion; editable potential-outcome equations |
| 6.2 | Unit 6, slides 29–39 | Design-specific discussions and credibility checks |
| 6.3 | Unit 6, slides 40–45 | 2019 ML reading; leakage and evaluation exercises |
| 6.4 | Unit 6, slides 46–60 | Falk–Heckman discussion; mixed-methods workshop |
| 6.5 | Unit 6, slides 61–90 | Corrected inference explanations; evidence audit |
| 7.1 | Unit 7, slides 3–10 | Discussions of all four assigned reviewer readings |
| 7.2 | Unit 7, slides 11–19 | Fryer response exercise; revision workshop |

PowerPoints remain in `pptx/`; readings remain in their unit folders under
`../readings/`. Students access the assigned readings and handouts through Canvas.
The source map describes adaptations, not a verbatim slide-for-slide conversion.
Repeated material is consolidated; new numerical examples are labeled illustrative.

## Editing and rendering

Shared bibliography and execution settings are in `_metadata.yml`. Each deck
declares its Reveal.js format directly; shared slide styles are in
`lecture-slides.css`. Each second-level heading starts a slide.
Speaker notes use `::: notes` blocks. Examples use non-executing code fences;
rendering does not retrieve data or run the practice commands.

From the project root:

```sh
quarto render lectures/lecture4.1.qmd
quarto render lectures
quarto render 2026/schedule.qmd
```

The lecture listing explicitly renders to HTML. Decks render to Reveal.js.
The project writes its generated website to `docs/`.

## Source and teaching notes

- Bibliography keys use `../readings.bib`. Each deck lists its assigned preparation.
- The file labeled AER refereeing guidelines contains Berk, Harvey, and
  Hirshleifer's *Preparing a Referee Report*.
- Some local readings are working-paper versions (including Athey–Imbens on
  the state of applied econometrics); the bibliography uses the course's
  published references. Avoid assuming PDF page numbers equal journal pages.
- Selected source figures are extracted without modification into
  `assets/unit5/` and `assets/unit6/`, with visible attribution and alt text.
- Equations were rewritten as editable math. The random-assignment explanation
  refers to potential outcomes. The inference discussion distinguishes nominal
  Type I error, power, bias, and economic significance.
- The API notebook is historical. Check endpoints, variable availability,
  file paths, and credentials before a live demonstration. The decks do not
  copy the credentials stored in the original example files.
- The course introduction, Amanda's units, and final presentation meetings
  are not converted in this batch. Their schedule entries remain intact.
- The retired Gang He sources remain recoverable in Git history.
