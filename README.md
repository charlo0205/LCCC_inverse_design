# LCC-C 无线电能传输实验

## Weekly log (2026-11-23)

I updated the LCC-C Simulink model to measure voltage and current for all three compensation capacitors. I used the simulated waveforms to check peak voltage and RMS ripple current. After a capacitor failed during lab testing, these results will help me choose suitable RF voltage and current ratings for the replacement before soldering it onto the board.

## 当前进度（2026-11-19）

已保存 MATLAB R2026b Update 1 中当前打开的 `LCC_C.slx`，包括此前未保存的模型修改。

- 初始化参数中的电压峰值 `V` 从 `20` 改为 `173.2` V。
- 新增 `L21 = 90e-9` H，接收侧串联电容计算更新为 `C_2 = 1/(omega^2*(L_2+L21))`。
- 新增两个电压传感器、三个 PS-Simulink Converter 和 `Scope1`；原 `Scope` 改为四路输入，并移除原 `Mux`。
- 求解器配置保持 `ode23t`，停止时间为 `5e-6` s。

保存时仿真已停止。当前会话中保留的上一次仿真输出记录显示：2026-11-18 运行达到 `5e-6` s 停止时间，`tout` 含 2874 个采样点，无错误或警告，包含 `receiver_i2`、`transmitter_i1` 和 `simlog`。本次保存未重新运行仿真，因此该历史输出不作为本次保存模型的重新验证结果。

按要求，仓库不包含工作区快照或仿真输出数据。

## 继续实验

在 MATLAB 中打开仓库内的 `LCC_C.slx`。模型的 `InitFcn` 包含参数初始化代码；运行模型时会执行该初始化。需要 MATLAB、Simulink 及模型使用的 Simscape 组件。
