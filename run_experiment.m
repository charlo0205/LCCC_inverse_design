function run_experiment()
% One-command reproducible runner.
diary('simulation_log.txt'); diary on;
try
    vv=ver;
    simVersion=vv(strcmp({vv.Name},'Simulink')).Version;
    elecVersion=vv(strcmp({vv.Name},'Simscape Electrical')).Version;
    optVersion=vv(strcmp({vv.Name},'Optimization Toolbox')).Version;
    fprintf('[1] MATLAB %s; Simulink %s; Simscape Electrical %s; Optimization Toolbox %s\n', ...
        version,simVersion,elecVersion,optVersion);
    fprintf('    Entry point: run_experiment; working folder: %s\n',pwd);
    fprintf('    Source check: technical bg.pdf available=%d; handwritten image supplied=%d\n', ...
        isfile('technical bg.pdf'),isfile('handwritten.png'));
    build_model;
    design=optimise_parameters;
    validation=validate_design(design);
    fprintf('[9] Comparing independent theoretical predictions with simulation-derived parameters\n');
    w=2*pi*design.f;
    kTheory=sqrt((design.R^2-design.R2^2)*design.R1/design.R2)/(w*sqrt(design.L1*design.L2));
    MTheory=kTheory*sqrt(design.L1*design.L2);
    Reff=design.R1+(w*design.M)^2/(design.R2+design.R);
    LTheory=sqrt(30*Reff)/w; CTheory=1/(w*w*LTheory);
    fprintf('    theory k=%.9f M=%.6f nH L=%.6f nH C=%.6f nF\n',kTheory,MTheory*1e9,LTheory*1e9,CTheory*1e9);
    fprintf('    simulation k=%.9f M=%.6f nH L=%.6f nH C=%.6f nF\n',design.k,design.M*1e9,design.L*1e9,design.C*1e9);
    write_report(design,validation,kTheory,MTheory,LTheory,CTheory);
    write_full_reports;
    fprintf('[10] Saving experiment results: model, CSV, log, report and PNG figures\n');
    set_param('LCCC_phasor/Parameters','Value',mat2str([design.k design.L design.C design.C1 design.C2 design.R design.f],17));
    save_system('LCCC_phasor','LCCC_phasor.slx');
    close_system('LCCC_inverse_design',0); load_system('LCCC_inverse_design.slx');
    set_param('LCCC_inverse_design','SimulationCommand','update');
    close_system('LCCC_phasor',0); load_system('LCCC_phasor.slx');
    set_param('LCCC_phasor','SimulationCommand','update');
    fprintf('    Reopened and compiled both .slx models successfully\n');
    fprintf('    Actual execution status: complete\n');
catch ME
    fprintf(2,'    MATLAB ERROR: %s\n',getReport(ME,'extended','hyperlinks','off'));
    diary off; rethrow(ME);
end
diary off;
end

function write_report(d,v,kT,MT,LT,CT)
fid=fopen('experiment_report.md','w');
fprintf(fid,'# LCC-C wireless power inverse design\n\n');
fprintf(fid,'Executed with MATLAB %s. Source limitation: `technical bg.pdf` and the handwritten image were not present in the supplied folder; topology follows the written task specification.\n\n',version);
fprintf(fid,'## Circuit and assumptions\n\n');
fprintf(fid,'1 V rms AC source -> series L -> shunt C -> series C1 -> R1 + L1; mutually coupled L2 -> R2 + C2 + 12.5 ohm load. Both windings share only electrical reference, not a series electrical connection. M is an inferred design target under this coil model, not a measurement of a coil pair. R1 = %.9g ohm, R2 = %.9g ohm from unloaded Q at 13.56 MHz. Compensation components and coupling are otherwise ideal; no capacitor ESR, core, proximity, switching, rectifier or radiation loss is included.\n\n',d.R1,d.R2);
fprintf(fid,'## Experiment A: simulated optimum-load matching\n\n');
fprintf(fid,'For each candidate k, Simulink evaluated real input and load power while load varied. Coil-to-coil efficiency was load power divided by real power entering the primary coil including R1 and reflected secondary loss. Numerical minimization of negative efficiency located R_opt(k); a root solve matched R_opt to 12.5 ohm. This criterion does not maximize efficiency over k. Matched k = %.10f; R_opt = %.8f ohm; inferred M = %.9f nH. See `efficiency_sweeps.png`, `efficiency_refined.png` and `optimum_load.png`.\n\n',d.k,d.Ropt,d.M*1e9);
fprintf(fid,'## Experiment B: simulated impedance optimization\n\n');
fprintf(fid,'The phasor Simulink model evaluated the complete coupled network at each L and C candidate. Three independent Nelder-Mead starts optimized real and imaginary Zin with an LC resonance penalty. For each L, C1 was selected so the branch reactance equals omega L (C1 = 1/[omega^2(L1-L)]); C2 cancels receiver L2 at 13.56 MHz (C2 = 1/[omega^2 L2]). These constraints guide the search, while the reported L and C minimize simulated results.\n\n');
fprintf(fid,'| Parameter | Simulated design |\n|---|---:|\n| L | %.9f nH |\n| C | %.9f nF |\n| M | %.9f nH |\n| k | %.10f |\n| C1 | %.9f nF |\n| C2 | %.9f nF |\n',d.L*1e9,d.C*1e9,d.M*1e9,d.k,d.C1*1e9,d.C2*1e9);
fprintf(fid,'\nPhasor Simulink Zin = %.9f %+.9fj ohm; predicted end-to-end efficiency = %.7f. LC resonance ratio omega^2 L C = %.10f.\n\n',d.phasor(1),d.phasor(2),d.phasor(3),(2*pi*d.f)^2*d.L*d.C);
fprintf(fid,'## Independent physical validation\n\n');
fprintf(fid,'Physical Simscape ode23t with max step T/25, extended until adjacent 20-cycle phasor windows changed by less than 0.1%% (or five runs). Converged=%d, window change=%.5g, duration=%.3f us. Zin=%.9f %+.9fj ohm, phase=%.6f deg, input V=%.7f V rms, input I=%.7f A rms, Tx coil I=%.7f A rms, Rx I=%.7f A rms, load V=%.7f V rms, input power=%.7f W, load power=%.7f W, efficiency=%.7f.\n\n',v.converged,v.convergence_error,v.duration_s*1e6,real(v.Zin),imag(v.Zin),v.phase_deg,v.V_input_rms,v.I_input_rms,v.I_tx_rms,v.I_rx_rms,v.V_load_rms,v.P_input_W,v.P_load_W,v.efficiency);
fprintf(fid,'Acceptance: real impedance error <1%%: %d; |Imag Zin| <0.3 ohm: %d; converged: %d; finite positive powers: %d.\n\n',abs(real(v.Zin)-30)/30<0.01,abs(imag(v.Zin))<0.3,v.converged,isfinite(v.P_input_W)&&isfinite(v.P_load_W)&&v.P_input_W>0&&v.P_load_W>0);
fprintf(fid,'## Theory cross-check and sensitivity\n\n');
fprintf(fid,'Independent optimum-load expression predicts k=%.10f, M=%.9f nH. Ideal tuned impedance predicts L=%.9f nH, C=%.9f nF. Differences (sim minus theory): k=%+.4g, M=%+.4g nH, L=%+.4g nH, C=%+.4g nF.\n\n',kT,MT*1e9,LT*1e9,CT*1e9,d.k-kT,(d.M-MT)*1e9,(d.L-LT)*1e9,(d.C-CT)*1e9);
fprintf(fid,'Across 6-25 ohm load, simulated Tx coil current varied by at most %.4g relative to nominal. Frequency response appears in `frequency_resonance.png`; load behavior in `load_sensitivity.png`; physical steady waveforms in `physical_waveforms.png`. Sensitivity with k multiplied by 0.9 and 1.1, and both winding resistances multiplied by 0.8 and 1.2, is tabulated below.\n\n',v.load_current_variation);
fprintf(fid,'| k multiplier | R multiplier | Re Zin (ohm) | Im Zin (ohm) | Efficiency |\n|---:|---:|---:|---:|---:|\n');
for j=1:size(v.sensitivity,1), s=v.sensitivity(j,:); fprintf(fid,'| %.2f | %.2f | %.6f | %.6f | %.6f |\n',s(1),s(2),s(3),s(4),s(5)); end
fprintf(fid,'\n`results.csv` contains every search evaluation, with stage and objective. `simulation_log.txt` is the MATLAB diary from the actual run. Reproduce in PowerShell with `& ''C:\\Program Files\\MATLAB\\R2026b\\bin\\matlab.exe'' -batch "cd(''C:\\Users\\charl\\Documents\\LCCC_inverse_design''); run_experiment"`.\n');
fclose(fid);
end
