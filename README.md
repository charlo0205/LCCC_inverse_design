# Serial-link simulation: auditable submission package

[Download the final submission ZIP](https://github.com/charlo0205/LCCC_inverse_design/raw/refs/heads/main/LCCC_inverse_design.zip) · [Read the English report](LCCC_calculation_report_EN.pdf)

The ZIP contains the 18 current project files directly at its root, with no nested folder. Extract it into one `LCCC_inverse_design` folder before running MATLAB. The files below are the same final version.

This folder is a compact, reproducible MATLAB/Simulink submission. It follows one calculation chain only:

`known f, R_L, L1, L2, Q1, Q2 -> R1, R2 -> k -> M -> L, C -> Simulink/Simscape verification`

The design target is a real input impedance of 30 ohm at 13.56 MHz. It is a requirement, not an extra measured circuit parameter.

For the concise English calculation report, open `LCCC_calculation_report_EN.pdf`. Its editable LaTeX source is `LCCC_calculation_report_EN.tex`. Both files are directly in this folder. The report follows the calculation chain and records the existing simulation results.

## How to reproduce the work

Open MATLAB in this folder and run:

```matlab
run_serial_link
```

The command rebuilds both models, repeats the checks, regenerates the three figures, and overwrites the result tables and log. Required products are MATLAB, Simulink, Simscape, and Simscape Electrical. No numerical optimizer is required.

## Calculation chain and current values

### 0. Known values

| Quantity | Value |
|---|---:|
| Operating frequency, f | 13.56 MHz |
| Load, R_L | 12.5 ohm |
| Transmitter self-inductance, L1 | 486.02 nH |
| Receiver self-inductance, L2 | 486.02 nH |
| Unloaded Q1 | 951.1 |
| Unloaded Q2 | 931 |
| Required input impedance | 30 + j0 ohm |

### 1. Derive winding resistances from Q

At angular frequency `omega = 2*pi*f`:

```text
R1 = omega*L1/Q1 = 0.043537904 ohm
R2 = omega*L2/Q2 = 0.044477874 ohm
```

### 2. Derive k and mutual inductance M

For a series-tuned receiver, the efficiency-optimum load is

```text
R_opt = sqrt(R2^2 + (omega*M)^2*R2/R1)
```

Impose `R_opt = R_L`, then solve for M and k:

```text
M = sqrt((R_L^2 - R2^2)*R1/R2)/omega = 145.154149 nH
k = M/sqrt(L1*L2)                         = 0.298658799
```

Figure `01_k_and_M_verification.png` contains both the equation-based selection and a Simulink load sweep at the derived k. This is the only k-selection figure needed.

### 3. Derive L and C

The receiver is tuned with `C2 = 1/(omega^2*L2)`. The resistance seen in the transmitter branch is

```text
R_branch = R1 + (omega*M)^2/(R2 + R_L)
```

For the LCC input to be 30 + j0 ohm:

```text
L  = sqrt(30*R_branch)/omega = 224.873265 nH
C  = 1/(omega^2*L)           = 0.612608557 nF
C1 = 1/(omega^2*(L1 - L))    = 0.527516786 nF
C2 = 1/(omega^2*L2)          = 0.283443657 nF
```

`C1` and `C2` are supporting tuning components fixed by the topology; they are not independently optimised variables.

### 4. Verify, do not redesign

The frequency-domain Simulink model checks the complex network at the nominal point and over frequency. The physical Simscape model independently checks the steady-state waveforms, input impedance, powers, and efficiency. See `verification_summary.csv` for explicit pass/fail criteria.

## Why there are only three figures

| Figure | What it proves | Needed? |
|---|---|---|
| `01_k_and_M_verification.png` | The calculated k makes 12.5 ohm the optimum load, and the Simulink sweep agrees. | Yes |
| `02_frequency_verification.png` | The final L and C give 30 + j0 ohm at 13.56 MHz and show the nearby response. | Yes |
| `03_physical_Simscape_verification.png` | The independent physical model reaches sinusoidal steady state. | Yes |

The previous broad k sweep, refined k sweep, separate optimum-load plot, L sweep, and load-sensitivity plot were removed from this submission. They repeated the same argument or explored behaviour outside the required derivation chain.

## File-by-file guide

| File | Purpose |
|---|---|
| `README.md` | This audit trail: equations, sequence, figure justification, and file map. |
| `LCCC_calculation_report_EN.pdf` | Concise English report with each calculation, intermediate result, and simulation check. |
| `LCCC_calculation_report_EN.tex` | Editable LaTeX source for the English report; compile with pdfLaTeX or Tectonic. |
| `run_serial_link.m` | One-command entry point. Prints every numbered step and creates all result files. |
| `calculate_design.m` | Implements only the ordered calculations R1/R2 -> k -> M -> L/C/C1/C2. |
| `build_models.m` | Programmatically builds the two inspectable models. |
| `phasor_network.m` | Complex circuit equations executed inside the frequency-domain Simulink model. |
| `evaluate_phasor_model.m` | Passes one parameter set to Simulink and returns its measured outputs. |
| `validate_design.m` | Runs the minimal verification sweeps, the physical transient, acceptance checks, and three figures. |
| `SerialLink_phasor.slx` | Fast frequency-domain Simulink evaluator used by all sweep points. |
| `SerialLink_physical.slx` | Independent Simscape Electrical circuit for time-domain checking. |
| `design_summary.csv` | Known values, derived values, units, and the equation/source for every row. |
| `verification_summary.csv` | Teacher-facing checks with measured value, requirement, and PASS/FAIL. |
| `serial_link_results.mat` | Machine-readable MATLAB structures for the final design and validation. |
| `simulation_log.txt` | Actual console transcript showing every numbered step and solver status. |
| Three PNG files | Only the three pieces of graphical evidence listed above. |

## Main modelling assumptions

- The source is 1 V rms and the load is purely resistive.
- R1 and R2 are derived from unloaded Q at 13.56 MHz and included once each.
- Compensation components are ideal; capacitor ESR, core loss, switching, rectifier, radiation, and frequency-dependent winding loss are not included.
- M is a design value inferred from the stated coil model, not a physical measurement of a fabricated coil pair.
