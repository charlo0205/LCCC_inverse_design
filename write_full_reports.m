function write_full_reports()
% Create readable English and bilingual Markdown from saved experiment data.
% This function reports existing simulations; it does not rerun them.
S=load('design_results.mat'); V=load('validation_results.mat');
d=S.design; T=S.T; v=V.validation;
assert(height(T)>0 && size(v.frequency_sweep,1)>0 && size(v.load_sweep,1)>0);
write_one('simulation_results_EN.md',false,d,v,T);
write_one('simulation_results_EN_ZH.md',true,d,v,T);
fprintf('Created simulation_results_EN.md and simulation_results_EN_ZH.md from %d search evaluations, %d frequency points and %d load points.\n', ...
    height(T),size(v.frequency_sweep,1),size(v.load_sweep,1));
end

function write_one(path,bilingual,d,v,T)
fid=fopen(path,'w','n','UTF-8');
if fid<0, error('Cannot create %s',path); end
if bilingual
    fprintf(fid,'# LCC-C Wireless Power Transfer: Complete Simulation Results / LCC-C 无线电能传输：完整仿真结果\n\n');
else
    fprintf(fid,'# LCC-C Wireless Power Transfer: Complete Simulation Results\n\n');
end
paragraph(fid,'This document was generated from the saved MATLAB/Simulink experiment data. It includes every recorded parameter-search evaluation, every saved frequency and load sweep point, the physical validation, and sensitivity results.', ...
    '本文件根据已保存的 MATLAB/Simulink 实验数据生成，包含全部参数搜索记录、全部已保存的扫频和负载扫描点、物理电路验证以及敏感度结果。',bilingual);
paragraph(fid,'Source limitation: `technical bg.pdf` and the handwritten reference image were unavailable in the supplied project folder. The implemented topology follows the written task specification. No values from the handwritten answer were used as optimizer inputs.', ...
    '资料限制：项目文件夹中没有 `technical bg.pdf` 或手写参考图。因此电路按任务文字描述搭建；优化器没有使用手写答案中的数值作为输入。',bilingual);
fprintf(fid,'**Software:** MATLAB R2026b Update 1; Simulink 26.2; Simscape Electrical 26.2; Optimization Toolbox 26.2.  \n');
if bilingual, fprintf(fid,'**软件：** MATLAB R2026b Update 1；Simulink 26.2；Simscape Electrical 26.2；Optimization Toolbox 26.2。  \n'); end
fprintf(fid,'**Data:** [results.csv](results.csv), [design_results.mat](design_results.mat), [validation_results.mat](validation_results.mat), [simulation_log.txt](simulation_log.txt).\n\n');

heading(fid,'1. Circuit, fixed inputs, and assumptions','1. 电路、固定输入与假设',bilingual);
paragraph(fid,'Topology: 1 V rms AC source -> series compensation inductor L -> shunt capacitor C -> series capacitor C1 -> transmitter winding resistance R1 and coil L1. The magnetically coupled receiver coil L2 drives its own series winding resistance R2, series capacitor C2, and resistive load R. The two windings are electrically separate. The mutual-inductor block has no additional winding resistance.', ...
    '拓扑：1 V 有效值交流电源 → 串联补偿电感 L → 并联电容 C → 串联电容 C1 → 发射线圈等效串联电阻 R1 和电感 L1。磁耦合的接收线圈 L2 串联自身电阻 R2、电容 C2 与负载 R。两侧线圈在电气上彼此隔离；互感模块内不再添加绕组电阻。',bilingual);
fprintf(fid,'| %s | %s |\n|---|---:|\n',label('Fixed quantity','固定量',bilingual),label('Value','数值',bilingual));
fprintf(fid,'| Operating frequency / 工作频率 | %.6f MHz |\n',d.f/1e6);
fprintf(fid,'| Target/load resistance / 目标负载 | %.6f ohm |\n',d.R);
fprintf(fid,'| Transmitter self-inductance L1 / 发射线圈自感 | %.6f nH |\n',d.L1*1e9);
fprintf(fid,'| Receiver self-inductance L2 / 接收线圈自感 | %.6f nH |\n',d.L2*1e9);
fprintf(fid,'| Unloaded Q1 / 发射线圈空载品质因数 | %.6f |\n',d.Q1);
fprintf(fid,'| Unloaded Q2 / 接收线圈空载品质因数 | %.6f |\n',d.Q2);
fprintf(fid,'| R1 = 2 pi f L1 / Q1 | %.9f ohm |\n',d.R1);
fprintf(fid,'| R2 = 2 pi f L2 / Q2 | %.9f ohm |\n\n',d.R2);
paragraph(fid,'Compensation components are ideal in this first design: no inductor/capacitor ESR, dielectric loss, core loss, switching loss, rectifier loss, radiation loss, or frequency-dependent winding resistance is included. These omissions limit the efficiency prediction.', ...
    '本次初始设计将补偿元件视为理想器件；未计入补偿电感和电容的等效串联电阻、介质损耗、磁芯损耗、开关与整流损耗、辐射损耗，也未计入绕组电阻随频率变化。这些假设会限制效率预测的适用范围。',bilingual);

heading(fid,'2. Experiment A: coupling from simulated optimum-load matching','2. 实验 A：通过仿真最优负载匹配识别耦合',bilingual);
paragraph(fid,'The frequency-domain Simulink model evaluated input power, load power, and coil-to-coil efficiency for 12 candidate k values and 45 load values per candidate. Coil-to-coil efficiency is load power divided by real power entering the primary coil branch. A numerical load optimization and root search then solved R_opt(k) = 12.5 ohm. The search did not maximize efficiency over k.', ...
    '频域 Simulink 模型对 12 个候选 k 值分别计算 45 个负载点的输入功率、负载功率及线圈到线圈效率。该效率定义为负载功率除以进入发射线圈支路的有功功率。随后用数值负载优化和求根求解 R_opt(k) = 12.5 Ω；这里没有对 k 直接做效率最大化。',bilingual);
fprintf(fid,'| %s | %s |\n|---|---:|\n',label('Matched result','匹配结果',bilingual),label('Value','数值',bilingual));
fprintf(fid,'| Simulated optimum load R_opt / 仿真最优负载 | %.9f ohm |\n',d.Ropt);
fprintf(fid,'| Coupling coefficient k / 耦合系数 | %.10f |\n',d.k);
fprintf(fid,'| Inferred mutual inductance M / 推断互感 | %.9f nH |\n',d.M*1e9);
fprintf(fid,'| Coil-to-coil efficiency at design / 设计点线圈间效率 | %.8f (%.5f%%) |\n\n',d.phasor(11),100*d.phasor(11));
paragraph(fid,'M is an inferred design target under the stated coil model. It is not a measurement of an existing coil pair.', ...
    'M 是在所给线圈模型下推断出的设计目标，并非对现有线圈实物的测量值。',bilingual);
fprintf(fid,'![%s](efficiency_sweeps.png)\n\n',label('Efficiency curves for candidate coupling values','不同耦合值下的效率曲线',bilingual));
fprintf(fid,'![%s](optimum_load.png)\n\n',label('Optimum load versus coupling','最优负载与耦合系数',bilingual));
fprintf(fid,'![%s](efficiency_refined.png)\n\n',label('Refined efficiency sweep near the matched load','匹配负载附近的精细效率扫描',bilingual));
fprintf(fid,'| k | %s | %s |\n|---:|---:|---:|\n',label('Grid R_opt (ohm)','网格最优负载 (Ω)',bilingual),label('Peak coil efficiency','峰值线圈效率',bilingual));
A=T(T.stage=="coupling_sweep",:); ks=unique(A.k);
for j=1:numel(ks)
    B=A(A.k==ks(j),:); [peak,ix]=max(B.coil_efficiency);
    fprintf(fid,'| %.6f | %.9f | %.9f |\n',ks(j),B.R_ohm(ix),peak);
end
fprintf(fid,'\n');

heading(fid,'3. Experiment B: simulation-driven L and C inverse design','3. 实验 B：基于仿真的 L、C 逆向设计',bilingual);
paragraph(fid,'At each candidate L and C, Simulink evaluated the complete coupled-network phasors and complex input impedance. C2 was tuned to cancel L2 at 13.56 MHz. For each L, C1 was set by the LCC series-compensation constraint C1 = 1/[omega^2(L1-L)]. The objective penalized error in real Zin, imaginary Zin, and omega^2 L C - 1. Three independent starting points were refined with Nelder-Mead.', ...
    '对每一组候选 L、C，Simulink 计算完整耦合电路的相量与复输入阻抗。C2 在 13.56 MHz 下抵消 L2 的感抗；对每个 L，按 LCC 串联补偿约束 C1 = 1/[omega²(L1-L)] 设定 C1。目标函数同时惩罚输入阻抗实部误差、虚部误差和 omega²LC − 1 的谐振误差，并从三个独立初始点使用 Nelder–Mead 方法细化。',bilingual);
fprintf(fid,'| %s | %s |\n|---|---:|\n',label('Optimized parameter','优化参数',bilingual),label('Value','数值',bilingual));
fprintf(fid,'| L | %.9f nH |\n| C | %.9f nF |\n| M | %.9f nH |\n| k | %.10f |\n| C1 | %.9f nF |\n| C2 | %.9f nF |\n', ...
    d.L*1e9,d.C*1e9,d.M*1e9,d.k,d.C1*1e9,d.C2*1e9);
fprintf(fid,'| omega^2 L C / 谐振比值 | %.12f |\n\n',(2*pi*d.f)^2*d.L*d.C);
fprintf(fid,'| %s | %s | %s | %s |\n|---:|---:|---:|---:|\n',label('Start','初始点',bilingual),label('Final L (nH)','最终 L (nH)',bilingual),label('Final C (nF)','最终 C (nF)',bilingual),label('Final objective','最终目标函数值',bilingual));
for j=1:size(d.starts,1), fprintf(fid,'| %d | %.9f | %.9f | %.9g |\n',j,d.starts(j,1)*1e9,d.starts(j,2)*1e9,d.starts(j,3)); end
fprintf(fid,'\n');
fprintf(fid,'| %s | %s |\n|---|---:|\n',label('Nominal phasor Simulink result','标称频域 Simulink 结果',bilingual),label('Value','数值',bilingual));
fprintf(fid,'| Real Zin / 输入阻抗实部 | %.9f ohm |\n| Imag Zin / 输入阻抗虚部 | %+.9f ohm |\n',d.phasor(1),d.phasor(2));
fprintf(fid,'| Input phase angle / 输入相角 | %.9f deg |\n',d.phasor(10));
fprintf(fid,'| Input current / 输入电流 | %.9f A rms |\n| Tx coil current / 发射线圈电流 | %.9f A rms |\n| Rx current / 接收电流 | %.9f A rms |\n',d.phasor(4),d.phasor(5),d.phasor(6));
fprintf(fid,'| Load voltage / 负载电压 | %.9f V rms |\n| Input real power / 输入有功功率 | %.9f W |\n| Load real power / 负载有功功率 | %.9f W |\n',d.phasor(7),d.phasor(8),d.phasor(9));
fprintf(fid,'| End-to-end efficiency / 端到端效率 | %.9f (%.6f%%) |\n\n',d.phasor(3),100*d.phasor(3));
fprintf(fid,'![%s](impedance_sweep.png)\n\n',label('Input impedance versus resonant L candidates','谐振 L 候选值与输入阻抗',bilingual));

heading(fid,'4. Independent physical Simscape validation','4. 独立的物理 Simscape 电路验证',bilingual);
paragraph(fid,'The physical model used the ode23t solver with a maximum step of T/25. The transient was extended from 20 to 40 microseconds because the first comparison did not meet the 0.1% criterion. The final measurement compared adjacent 20-cycle phasor windows; their largest relative change was below 0.1%.', ...
    '物理模型采用 ode23t 求解器，最大步长为周期 T/25。首次 20 微秒仿真的稳态比较未达到 0.1% 判据，因此延长到 40 微秒。最终将相邻两个 20 周期窗口的相量进行比较，最大相对变化小于 0.1%。',bilingual);
fprintf(fid,'| %s | %s |\n|---|---:|\n',label('Physical measurement','物理仿真测量',bilingual),label('Value','数值',bilingual));
fprintf(fid,'| Stop time / 仿真终止时间 | %.3f microseconds |\n| Window change / 窗口相量变化 | %.9g |\n',v.duration_s*1e6,v.convergence_error);
fprintf(fid,'| Input voltage / 输入电压 | %.9f V rms |\n| Input current / 输入电流 | %.9f A rms |\n',v.V_input_rms,v.I_input_rms);
fprintf(fid,'| Input phase angle / 输入相角 | %.9f deg |\n',v.phase_deg);
fprintf(fid,'| Real Zin / 输入阻抗实部 | %.9f ohm |\n| Imag Zin / 输入阻抗虚部 | %+.9f ohm |\n',real(v.Zin),imag(v.Zin));
fprintf(fid,'| Tx coil current / 发射线圈电流 | %.9f A rms |\n| Rx current / 接收电流 | %.9f A rms |\n',v.I_tx_rms,v.I_rx_rms);
fprintf(fid,'| Load voltage / 负载电压 | %.9f V rms |\n| Input real power / 输入有功功率 | %.9f W |\n| Load real power / 负载有功功率 | %.9f W |\n',v.V_load_rms,v.P_input_W,v.P_load_W);
fprintf(fid,'| End-to-end efficiency / 端到端效率 | %.9f (%.6f%%) |\n\n',v.efficiency,100*v.efficiency);
fprintf(fid,'| %s | %s | %s |\n|---|---:|---|\n',label('Acceptance criterion','验收判据',bilingual),label('Measured','实测值',bilingual),label('Status','状态',bilingual));
fprintf(fid,'| Relative Real Zin error < 1%% / 输入阻抗实部误差 < 1%% | %.6f%% | %s |\n',100*abs(real(v.Zin)-30)/30,passfail(abs(real(v.Zin)-30)/30<0.01,bilingual));
fprintf(fid,'| Absolute Imag Zin < 0.3 ohm / 输入阻抗虚部绝对值 < 0.3 Ω | %.9f ohm | %s |\n',abs(imag(v.Zin)),passfail(abs(imag(v.Zin))<0.3,bilingual));
fprintf(fid,'| Converged phasors / 稳态相量收敛 | %.9g | %s |\n',v.convergence_error,passfail(v.converged,bilingual));
fprintf(fid,'| Finite positive powers / 有限且为正的功率 | %.9f / %.9f W | %s |\n\n',v.P_input_W,v.P_load_W,passfail(all(isfinite([v.P_input_W v.P_load_W]))&&v.P_input_W>0&&v.P_load_W>0,bilingual));
fprintf(fid,'![%s](physical_waveforms.png)\n\n',label('Last five cycles of physical waveforms','物理电路最后五个周期的波形',bilingual));

heading(fid,'5. Theoretical cross-check','5. 理论值交叉核对',bilingual);
w=2*pi*d.f; kTheory=sqrt((d.R^2-d.R2^2)*d.R1/d.R2)/(w*sqrt(d.L1*d.L2));
MTheory=kTheory*sqrt(d.L1*d.L2); Reff=d.R1+(w*d.M)^2/(d.R2+d.R);
LTheory=sqrt(30*Reff)/w; CTheory=1/(w*w*LTheory);
paragraph(fid,'Theory was calculated independently after the simulation search. It is a cross-check, not the source of optimizer initial values or the final reported simulation-derived parameters.', ...
    '理论值是在仿真搜索后独立计算的，仅用于交叉核对；它不是优化器初始值或最终仿真参数的来源。',bilingual);
fprintf(fid,'| %s | %s | %s | %s |\n|---|---:|---:|---:|\n',label('Parameter','参数',bilingual),label('Simulation','仿真值',bilingual),label('Theory','理论值',bilingual),label('Simulation minus theory','仿真减理论',bilingual));
fprintf(fid,'| k | %.10f | %.10f | %+.9g |\n',d.k,kTheory,d.k-kTheory);
fprintf(fid,'| M (nH) | %.9f | %.9f | %+.9g |\n',d.M*1e9,MTheory*1e9,(d.M-MTheory)*1e9);
fprintf(fid,'| L (nH) | %.9f | %.9f | %+.9g |\n',d.L*1e9,LTheory*1e9,(d.L-LTheory)*1e9);
fprintf(fid,'| C (nF) | %.9f | %.9f | %+.9g |\n\n',d.C*1e9,CTheory*1e9,(d.C-CTheory)*1e9);

heading(fid,'6. Frequency, load, and component sensitivity','6. 频率、负载与器件敏感度',bilingual);
paragraph(fid,'The frequency sweep contains 81 Simulink evaluations from 10.848 to 16.272 MHz. The load sweep contains 41 evaluations from 6 to 25 ohm. The complete numeric values appear in Appendices A and B below. With ideal LCC compensation, simulated transmitter coil current was effectively load independent within numerical precision.', ...
    '扫频包含从 10.848 到 16.272 MHz 的 81 次 Simulink 评估；负载扫描包含从 6 到 25 Ω 的 41 次评估。全部数值列于下方附录 A 和 B。理想 LCC 补偿条件下，发射线圈电流在数值精度范围内基本不随负载变化。',bilingual);
fprintf(fid,'| %s | %s |\n|---|---:|\n',label('Sensitivity summary','敏感度摘要',bilingual),label('Value','数值',bilingual));
fprintf(fid,'| Maximum relative Tx current change across load sweep / 负载扫描中发射电流最大相对变化 | %.9g |\n',v.load_current_variation);
fprintf(fid,'| Frequency sweep point count / 扫频点数 | %d |\n| Load sweep point count / 负载扫描点数 | %d |\n\n',size(v.frequency_sweep,1),size(v.load_sweep,1));
fprintf(fid,'![%s](frequency_resonance.png)\n\n',label('Frequency response and resonance','频率响应与谐振',bilingual));
fprintf(fid,'![%s](load_sensitivity.png)\n\n',label('Load dependence of impedance and transmitter current','输入阻抗与发射电流的负载依赖性',bilingual));
fprintf(fid,'| %s | %s | %s | %s | %s |\n|---:|---:|---:|---:|---:|\n',label('k multiplier','k 倍率',bilingual),label('R1/R2 multiplier','R1/R2 倍率',bilingual),label('Real Zin (ohm)','输入阻抗实部 (Ω)',bilingual),label('Imag Zin (ohm)','输入阻抗虚部 (Ω)',bilingual),label('Efficiency','效率',bilingual));
for j=1:size(v.sensitivity,1)
    x=v.sensitivity(j,:);
    fprintf(fid,'| %.2f | %.2f | %.9f | %+.9f | %.9f |\n',x(1),x(2),x(3),x(4),x(5));
end
fprintf(fid,'\n');

heading(fid,'Appendix A. All saved frequency-sweep points','附录 A：全部扫频数据点',bilingual);
fprintf(fid,'| %s | %s | %s | %s |\n|---:|---:|---:|---:|\n',label('Frequency (MHz)','频率 (MHz)',bilingual),label('Real Zin (ohm)','输入阻抗实部 (Ω)',bilingual),label('Imag Zin (ohm)','输入阻抗虚部 (Ω)',bilingual),label('End-to-end efficiency','端到端效率',bilingual));
for j=1:size(v.frequency_sweep,1)
    x=v.frequency_sweep(j,:); fprintf(fid,'| %.6f | %.9f | %+.9f | %.9f |\n',x(1)/1e6,x(2),x(3),x(4));
end
fprintf(fid,'\n');

heading(fid,'Appendix B. All saved load-sweep points','附录 B：全部负载扫描数据点',bilingual);
fprintf(fid,'| %s | %s | %s | %s | %s |\n|---:|---:|---:|---:|---:|\n',label('Load (ohm)','负载 (Ω)',bilingual),label('Real Zin (ohm)','输入阻抗实部 (Ω)',bilingual),label('Imag Zin (ohm)','输入阻抗虚部 (Ω)',bilingual),label('Tx current (A rms)','发射电流 (A 有效值)',bilingual),label('End-to-end efficiency','端到端效率',bilingual));
for j=1:size(v.load_sweep,1)
    x=v.load_sweep(j,:); fprintf(fid,'| %.6f | %.9f | %+.9f | %.9f | %.9f |\n',x(1),x(2),x(3),x(4),x(5));
end
fprintf(fid,'\n');

heading(fid,'Appendix C. Complete parameter-search history','附录 C：完整参数搜索历史',bilingual);
paragraph(fid,'The table below reproduces every row in `results.csv`, including coupling/load sweeps, coupling root trials, refined load sweep, L/C sweep, optimization evaluations, and the final evaluation. SI units are used in this appendix. The stage identifies the experiment step; the objective is the recorded mismatch measure for that evaluation. Solver failures would have raised an error and stopped the run; all saved rows are finite.', ...
    '下表逐行重现 `results.csv` 中的全部记录，包括耦合及负载扫描、耦合求根尝试、精细负载扫描、L/C 扫描、优化评估和最终评估。本附录使用 SI 单位。stage 表示实验阶段，objective 是该次评估记录的不匹配指标。如果求解器失败，程序会报错并停止；已保存的记录均为有限值。',bilingual);
fprintf(fid,'| %s | %s |\n|---|---:|\n',label('Stage','阶段',bilingual),label('Evaluations','评估次数',bilingual));
stageNames=unique(T.stage,'stable');
for j=1:numel(stageNames), fprintf(fid,'| %s | %d |\n',stageNames(j),sum(T.stage==stageNames(j))); end
fprintf(fid,'| %s | **%d** |\n\n',label('**Total**','**合计**',bilingual),height(T));
heads={label('Stage','阶段',bilingual),label('Iter','序号',bilingual),'k',label('R (ohm)','R (Ω)',bilingual), ...
    'L (H)','C (F)','C1 (F)','C2 (F)','M (H)',label('Re Zin (ohm)','输入阻抗实部 (Ω)',bilingual), ...
    label('Im Zin (ohm)','输入阻抗虚部 (Ω)',bilingual),label('End-to-end eta','端到端效率',bilingual), ...
    label('Coil eta','线圈间效率',bilingual),label('Pin (W)','输入功率 (W)',bilingual), ...
    label('Pload (W)','负载功率 (W)',bilingual),label('Objective','目标函数值',bilingual)};
fprintf(fid,'| %s |\n',strjoin(heads,' | '));
fprintf(fid,'| %s |\n',strjoin(repmat({'---:'},1,numel(heads)),' | '));
vars={'iteration','k','R_ohm','L_H','C_F','C1_F','C2_F','M_H','Zreal_ohm','Zimag_ohm','efficiency','coil_efficiency','Pin_W','Pload_W','objective'};
for i=1:height(T)
    fprintf(fid,'| %s',T.stage(i));
    for j=1:numel(vars), fprintf(fid,' | %.17g',T.(vars{j})(i)); end
    fprintf(fid,' |\n');
end
fprintf(fid,'\n');

heading(fid,'Reproduction and saved files','复现方法与已保存文件',bilingual);
paragraph(fid,'The physical model `LCCC_inverse_design.slx` and the phasor evaluator `LCCC_phasor.slx` were reopened and compiled after the full experiment. The scripts `build_model.m`, `optimise_parameters.m`, `validate_design.m`, `phasor_network.m`, and `lccc_evaluate.m` implement the workflow; `write_full_reports.m` generates these two Markdown documents from saved data. The MATLAB execution diary is `simulation_log.txt`. Running the command below rebuilds the models and overwrites the generated result files.', ...
    '完整实验结束后，物理模型 `LCCC_inverse_design.slx` 和频域模型 `LCCC_phasor.slx` 均已重新打开并成功编译。`build_model.m`、`optimise_parameters.m`、`validate_design.m`、`phasor_network.m` 和 `lccc_evaluate.m` 实现了整个流程；`write_full_reports.m` 根据保存的数据生成这两份 Markdown 文档。MATLAB 的实际执行日志保存在 `simulation_log.txt`。执行以下命令会重建模型并覆盖生成的结果文件。',bilingual);
fprintf(fid,'```powershell\n& ''C:\\Program Files\\MATLAB\\R2026b\\bin\\matlab.exe'' -batch "cd(''C:\\Users\\charl\\Documents\\LCCC_inverse_design''); run_experiment"\n```\n');
fclose(fid);
if ~bilingual
    fr=fopen(path,'r','n','UTF-8'); content=fread(fr,'*char')'; fclose(fr);
    content=regexprep(content,' / [\x{4E00}-\x{9FFF}][^|\r\n]*',' ');
    assert(isempty(regexp(content,'[\x{4E00}-\x{9FFF}]','once')),'English report still contains Chinese text');
    fw=fopen(path,'w','n','UTF-8'); fwrite(fw,content,'char'); fclose(fw);
end
end

function heading(fid,en,zh,bilingual)
if bilingual, fprintf(fid,'## %s / %s\n\n',en,zh); else, fprintf(fid,'## %s\n\n',en); end
end

function paragraph(fid,en,zh,bilingual)
fprintf(fid,'%s\n\n',en);
if bilingual, fprintf(fid,'%s\n\n',zh); end
end

function out=label(en,zh,bilingual)
if bilingual, out=[en ' / ' zh]; else, out=en; end
end

function out=passfail(tf,bilingual)
if tf, out='PASS'; else, out='FAIL'; end
if bilingual
    if tf, out='PASS / 通过'; else, out='FAIL / 未通过'; end
end
end
