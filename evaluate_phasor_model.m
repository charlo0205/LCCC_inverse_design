function y = evaluate_phasor_model(design, options)
%EVALUATE_PHASOR_MODEL Run one frequency-domain Simulink evaluation.

arguments
    design (1,1) struct
    options.Load (1,1) double {mustBePositive} = design.RL
    options.Frequency (1,1) double {mustBePositive} = design.f
    options.Coupling (1,1) double {mustBePositive} = design.k
end

parameters = [options.Frequency, options.Load, design.L1, design.L2, ...
    design.R1, design.R2, options.Coupling, design.L, design.C, ...
    design.C1, design.C2];
set_param("SerialLink_phasor/Parameters", "Value", mat2str(parameters, 17));
simOut = sim("SerialLink_phasor", StopTime="0", ReturnWorkspaceOutputs="on");
raw = simOut.get("phasorResult");
if isstruct(raw)
    y = raw.signals.values(end, :);
else
    y = raw(end, :);
end
assert(numel(y) == 11 && all(isfinite(y)), "Invalid phasor simulation result.");
end
