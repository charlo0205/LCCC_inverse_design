# LCC-C wireless power inverse design

Executed with MATLAB 26.2.0.3433840 (R2026b) Update 1. Source limitation: `technical bg.pdf` and the handwritten image were not present in the supplied folder; topology follows the written task specification.

## Circuit and assumptions

1 V rms AC source -> series L -> shunt C -> series C1 -> R1 + L1; mutually coupled L2 -> R2 + C2 + 12.5 ohm load. Both windings share only electrical reference, not a series electrical connection. M is an inferred design target under this coil model, not a measurement of a coil pair. R1 = 0.043537904 ohm, R2 = 0.0444778738 ohm from unloaded Q at 13.56 MHz. Compensation components and coupling are otherwise ideal; no capacitor ESR, core, proximity, switching, rectifier or radiation loss is included.

## Experiment A: simulated optimum-load matching

For each candidate k, Simulink evaluated real input and load power while load varied. Coil-to-coil efficiency was load power divided by real power entering the primary coil including R1 and reflected secondary loss. Numerical minimization of negative efficiency located R_opt(k); a root solve matched R_opt to 12.5 ohm. This criterion does not maximize efficiency over k. Matched k = 0.2986590621; R_opt = 12.50000000 ohm; inferred M = 145.154277361 nH. See `efficiency_sweeps.png`, `efficiency_refined.png` and `optimum_load.png`.

## Experiment B: simulated impedance optimization

The phasor Simulink model evaluated the complete coupled network at each L and C candidate. Three independent Nelder-Mead starts optimized real and imaginary Zin with an LC resonance penalty. For each L, C1 was selected so the branch reactance equals omega L (C1 = 1/[omega^2(L1-L)]); C2 cancels receiver L2 at 13.56 MHz (C2 = 1/[omega^2 L2]). These constraints guide the search, while the reported L and C minimize simulated results.

| Parameter | Simulated design |
|---|---:|
| L | 224.873462335 nH |
| C | 0.612608019 nF |
| M | 145.154277361 nH |
| k | 0.2986590621 |
| C1 | 0.527517185 nF |
| C2 | 0.283443657 nF |

Phasor Simulink Zin = 29.999999992 +0.000000005j ohm; predicted end-to-end efficiency = 0.9929088. LC resonance ratio omega^2 L C = 0.9999999998.

## Independent physical validation

Physical Simscape ode23t with max step T/25, extended until adjacent 20-cycle phasor windows changed by less than 0.1% (or five runs). Converged=1, window change=0.00017928, duration=40.000 us. Zin=29.992295774 -0.001735641j ohm, phase=-0.003316 deg, input V=0.9999733 V rms, input I=0.0333410 A rms, Tx coil I=0.0521922 A rms, Rx I=0.0514573 A rms, load V=0.6432158 V rms, input power=0.0333401 W, load power=0.0330981 W, efficiency=0.9927417.

Acceptance: real impedance error <1%: 1; |Imag Zin| <0.3 ohm: 1; converged: 1; finite positive powers: 1.

## Theory cross-check and sensitivity

Independent optimum-load expression predicts k=0.2986587990, M=145.154149499 nH. Ideal tuned impedance predicts L=224.873462401 nH, C=0.612608019 nF. Differences (sim minus theory): k=+2.631e-07, M=+0.0001279 nH, L=-6.636e-08 nH, C=+7.791e-11 nF.

Across 6-25 ohm load, simulated Tx coil current varied by at most 3.988e-16 relative to nominal. Frequency response appears in `frequency_resonance.png`; load behavior in `load_sensitivity.png`; physical steady waveforms in `physical_waveforms.png`. Sensitivity with k multiplied by 0.9 and 1.1, and both winding resistances multiplied by 0.8 and 1.2, is tabulated below.

| k multiplier | R multiplier | Re Zin (ohm) | Im Zin (ohm) | Efficiency |
|---:|---:|---:|---:|---:|
| 0.90 | 1.00 | 37.006150 | 0.000000 | 0.992081 |
| 1.10 | 1.00 | 24.808709 | 0.000000 | 0.993522 |
| 1.00 | 0.80 | 30.000136 | 0.000000 | 0.994323 |
| 1.00 | 1.20 | 29.999834 | 0.000000 | 0.991497 |

`results.csv` contains every search evaluation, with stage and objective. `simulation_log.txt` is the MATLAB diary from the actual run. Reproduce in PowerShell with `& 'C:\Program Files\MATLAB\R2026b\bin\matlab.exe' -batch "cd('C:\Users\charl\Documents\LCCC_inverse_design'); run_experiment"`.
