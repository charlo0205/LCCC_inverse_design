# LCC–C Wireless Power Transfer Inverse Design / LCC–C 无线电能传输逆向设计

Simulation driven inverse design of an LCC–C wireless power transfer circuit at 13.56 MHz. The coupling is selected by matching the **simulated efficiency maximizing load** to 12.5 Ω. The compensation values are then optimized using Simulink evaluations of complex input impedance and checked with an independent physical Simscape Electrical circuit.

本项目在 13.56 MHz 下对 LCC–C 无线电能传输电路进行基于仿真的逆向设计。通过使**仿真效率最优负载**等于 12.5 Ω 来确定耦合，再利用 Simulink 输入阻抗仿真优化补偿参数，并使用独立的 Simscape Electrical 物理电路验证。

## Results / 结果

| Parameter / 参数 | Simulation derived value / 仿真识别值 |
|---|---:|
| Transmitter compensation inductance L / 发射端补偿电感 | 224.873462 nH |
| Shunt capacitance C / 并联补偿电容 | 0.612608019 nF |
| Inferred mutual inductance M / 推断互感 | 145.154277 nH |
| Coupling coefficient k / 耦合系数 | 0.298659062 |
| Transmitter series capacitor C1 / 发射端串联电容 | 0.527517185 nF |
| Receiver series capacitor C2 / 接收端串联电容 | 0.283443657 nF |

The physical Simscape model measured **Zin = 29.992296 − j0.001736 Ω** and **99.2742% end to end efficiency** after the steady state phasors converged. M is an inferred design target under the stated coil model; it is not a measurement of an existing coil pair.

物理 Simscape 模型在稳态相量收敛后测得 **Zin = 29.992296 − j0.001736 Ω**，**端到端效率为 99.2742%**。M 是所给线圈模型下推断的设计目标，并非现有线圈实物的测量值。

## Files / 文件

| File / 文件 | Purpose / 用途 |
|---|---|
| [LCCC_inverse_design.slx](LCCC_inverse_design.slx) | Physical Simscape circuit / 物理电路 |
| [LCCC_phasor.slx](LCCC_phasor.slx) | Frequency domain optimization model / 频域优化模型 |
| [run_experiment.m](run_experiment.m) | One command experiment runner / 一键运行入口 |
| [build_model.m](build_model.m), [optimise_parameters.m](optimise_parameters.m), [validate_design.m](validate_design.m) | Build, optimize, validate / 建模、优化、验证 |
| [simulation_results_EN.md](simulation_results_EN.md) | Complete English report / 完整英文报告 |
| [simulation_results_EN_ZH.md](simulation_results_EN_ZH.md) | Complete bilingual report / 完整中英双语报告 |
| [results.csv](results.csv) | All 1202 saved parameter search evaluations / 全部 1202 条参数搜索记录 |
| [simulation_log.txt](simulation_log.txt) | Actual MATLAB execution log / MATLAB 实际执行日志 |
| [design_results.mat](design_results.mat), [validation_results.mat](validation_results.mat) | Machine readable results / MATLAB 结果数据 |
| PNG files / PNG 图片 | Efficiency, impedance, resonance, load and waveform plots / 效率、阻抗、谐振、负载及波形图 |

## Reproduce / 复现

Requires MATLAB R2026b with Simulink, Simscape, Simscape Electrical and Optimization Toolbox. In the MATLAB Command Window, change to this directory and run:

需要 MATLAB R2026b、Simulink、Simscape、Simscape Electrical 和 Optimization Toolbox。在 MATLAB 命令窗口进入此目录后运行：

```matlab
cd('path/to/LCCC_inverse_design')
run_experiment
```

The runner rebuilds both models, repeats the simulation based search and physical validation, and regenerates the reports, CSV data, log, and figures. To inspect the physical circuit, run `open_system('LCCC_inverse_design.slx')` from this directory.

运行脚本会重新搭建两个模型，重复仿真搜索与物理验证，并更新报告、CSV 数据、日志和图片。要查看物理电路，可在此目录运行 `open_system('LCCC_inverse_design.slx')`。

## Source and modeling limits / 资料与模型限制

The original `technical bg.pdf` and handwritten reference image were unavailable in the supplied project directory, so the circuit follows the written topology specification. Winding resistance is calculated from unloaded Q and included once as an external series resistor on each coil. Compensation components are ideal in this first model; switching, rectification, radiation, and other component losses are omitted.

原始 `technical bg.pdf` 和手写参考图未出现在所提供的项目目录中，因此电路按文字拓扑要求建立。绕组电阻由空载品质因数计算，并在每侧线圈外部串联一次。当前初始模型将补偿元件视为理想器件，未计入开关、整流、辐射及其他器件损耗。
