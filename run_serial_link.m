function run_serial_link()
%RUN_SERIAL_LINK Reproduce the complete serial-link design and validation.

logFile = "simulation_log.txt";
fileIdentifier = fopen(logFile, "w");
assert(fileIdentifier >= 0, "Cannot create %s.", logFile);
fclose(fileIdentifier);
diary(logFile);
diary on;
cleanupObject = onCleanup(@() diary("off"));

fprintf("Serial-link reproducible design run\n");
fprintf("MATLAB %s\n\n", version);

% Known circuit parameters and one design requirement.
inputs = struct( ...
    "f", 13.56e6, ...
    "RL", 12.5, ...
    "L1", 486.02e-9, ...
    "L2", 486.02e-9, ...
    "Q1", 951.1, ...
    "Q2", 931, ...
    "ZinTarget", 30);

fprintf("[0] Known inputs: f, RL, L1, L2, Q1, Q2.\n");
fprintf("    f = %.6f MHz, RL = %.6f ohm.\n", inputs.f/1e6, inputs.RL);
fprintf("    L1 = %.6f nH, L2 = %.6f nH.\n", inputs.L1*1e9, inputs.L2*1e9);
fprintf("    Q1 = %.6f, Q2 = %.6f.\n", inputs.Q1, inputs.Q2);
fprintf("    Design requirement: Zin = %.6f + j0 ohm at f.\n\n", inputs.ZinTarget);

design = calculate_design(inputs);

fprintf("[1] Q -> winding resistances.\n");
fprintf("    R1 = omega*L1/Q1 = %.9f ohm.\n", design.R1);
fprintf("    R2 = omega*L2/Q2 = %.9f ohm.\n\n", design.R2);

fprintf("[2] R1, R2 and RL -> coupling k -> mutual inductance M.\n");
fprintf("    k = %.10f.\n", design.k);
fprintf("    M = k*sqrt(L1*L2) = %.9f nH.\n", design.M*1e9);
fprintf("    Optimum-load equation returns %.9f ohm.\n\n", design.optimumLoadCheck);

fprintf("[3] M and the input-impedance requirement -> L and C.\n");
fprintf("    L = %.9f nH.\n", design.L*1e9);
fprintf("    C = %.9f nF.\n", design.C*1e9);
fprintf("    Supporting tuning: C1 = %.9f nF, C2 = %.9f nF.\n\n", ...
    design.C1*1e9, design.C2*1e9);

fprintf("[4] Building the frequency-domain Simulink model and physical Simscape model.\n");
build_models(design);

fprintf("[5] Checking the nominal point with the Simulink phasor model.\n");
phasor = evaluate_phasor_model(design);
design.phasor = phasor;
fprintf("    Zin = %.12f %+.12fj ohm.\n", phasor(1), phasor(2));
fprintf("    End-to-end efficiency = %.9f%%.\n\n", 100*phasor(3));

validation = validate_design(design);

fprintf("[9] Writing the compact audit files.\n");
writeDesignSummary(design);
writeVerificationSummary(design, validation);
save("serial_link_results.mat", "design", "validation");

phasorPassed = abs(phasor(1) - design.ZinTarget)/design.ZinTarget < 1e-6 && ...
    abs(phasor(2)) < 1e-6;
assert(phasorPassed, "The nominal phasor check failed.");
assert(validation.accepted, "The independent Simscape acceptance checks failed.");

% Leave the saved phasor model at the nominal design point after the sweeps.
evaluate_phasor_model(design);
save_system("SerialLink_phasor", "SerialLink_phasor.slx");
save_system("SerialLink_physical", "SerialLink_physical.slx");
fprintf("    Saved design_summary.csv, verification_summary.csv and serial_link_results.mat.\n");
fprintf("    Final status: ALL CHECKS PASSED.\n");
clear cleanupObject;
end

function writeDesignSummary(design)
stage = [repmat("Given input", 6, 1); "Design requirement"; repmat("Derived", 8, 1)];
symbol = ["f"; "RL"; "L1"; "L2"; "Q1"; "Q2"; "ZinTarget"; ...
    "R1"; "R2"; "k"; "M"; "L"; "C"; "C1"; "C2"];
value = [design.f; design.RL; design.L1; design.L2; design.Q1; design.Q2; ...
    design.ZinTarget; design.R1; design.R2; design.k; design.M; ...
    design.L; design.C; design.C1; design.C2];
unit = ["Hz"; "ohm"; "H"; "H"; "-"; "-"; "ohm"; "ohm"; "ohm"; ...
    "-"; "H"; "H"; "F"; "F"; "F"];
sourceOrEquation = ["specified"; "specified"; "specified"; "specified"; ...
    "specified"; "specified"; "target"; "omega*L1/Q1"; "omega*L2/Q2"; ...
    "optimum-load condition"; "k*sqrt(L1*L2)"; ...
    "sqrt(ZinTarget*branchResistance)/omega"; "1/(omega^2*L)"; ...
    "1/(omega^2*(L1-L))"; "1/(omega^2*L2)"];
summaryTable = table(stage, symbol, value, unit, sourceOrEquation);
writetable(summaryTable, "design_summary.csv");
end

function writeVerificationSummary(design, validation)
check = ["Derived optimum load equals RL"; "Phasor Re(Zin)"; ...
    "Phasor Im(Zin)"; "Physical Re(Zin)"; "Physical Im(Zin)"; ...
    "Physical steady-state convergence"; "Finite positive powers"; ...
    "Overall independent validation"];
measured = [design.optimumLoadCheck; design.phasor(1); design.phasor(2); ...
    real(validation.Zin); imag(validation.Zin); validation.convergenceError; ...
    min(validation.Pin, validation.Pload); double(validation.accepted)];
requirement = ["12.5 ohm"; "30 ohm"; "absolute value < 1e-6 ohm"; ...
    "within 1% of 30 ohm"; "absolute value < 0.3 ohm"; ...
    "window change < 0.001"; "both powers > 0 W"; "all checks pass"];
passed = [abs(design.optimumLoadCheck - design.RL) < 1e-9; ...
    abs(design.phasor(1) - design.ZinTarget)/design.ZinTarget < 1e-6; ...
    abs(design.phasor(2)) < 1e-6; validation.realImpedancePassed; ...
    validation.imagImpedancePassed; validation.converged; ...
    validation.powerPassed; validation.accepted];
status = repmat("FAIL", size(passed));
status(passed) = "PASS";
verificationTable = table(check, measured, requirement, status);
writetable(verificationTable, "verification_summary.csv");
end
