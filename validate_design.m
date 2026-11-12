function validation = validate_design(design)
%VALIDATE_DESIGN Verify k, impedance, frequency response, and time domain.

arguments
    design (1,1) struct
end

fprintf("[6] Verifying the derived k and M with a Simulink load sweep.\n");
loadValues = linspace(8, 17, 73);
coilEfficiency = zeros(size(loadValues));
for index = 1:numel(loadValues)
    result = evaluate_phasor_model(design, Load=loadValues(index));
    coilEfficiency(index) = result(11);
end
[~, optimumIndex] = max(coilEfficiency);
simulatedOptimumLoad = loadValues(optimumIndex);
fprintf("    Sweep peak: RL = %.4f ohm; required RL = %.4f ohm.\n", ...
    simulatedOptimumLoad, design.RL);

plotCouplingVerification(design, loadValues, coilEfficiency, optimumIndex);

fprintf("[7] Verifying the final design over frequency with Simulink.\n");
frequencyValues = linspace(0.8*design.f, 1.2*design.f, 81);
frequencyResults = zeros(numel(frequencyValues), 3);
for index = 1:numel(frequencyValues)
    result = evaluate_phasor_model(design, Frequency=frequencyValues(index));
    frequencyResults(index, :) = result(1:3);
end
plotFrequencyVerification(design, frequencyValues, frequencyResults);

fprintf("[8] Running the independent physical Simscape validation.\n");
physical = runPhysicalValidation(design);
plotPhysicalVerification(design, physical.simulationOutput, physical.duration);
physical = rmfield(physical, "simulationOutput");

validation = physical;
validation.simulatedOptimumLoad = simulatedOptimumLoad;
validation.loadSweep = [loadValues(:), coilEfficiency(:)];
validation.frequencySweep = [frequencyValues(:), frequencyResults];
loadGridStep = loadValues(2) - loadValues(1);
validation.kCheckPassed = abs(simulatedOptimumLoad - design.RL) <= loadGridStep;
validation.realImpedancePassed = ...
    abs(real(validation.Zin) - design.ZinTarget)/design.ZinTarget < 0.01;
validation.imagImpedancePassed = abs(imag(validation.Zin)) < 0.3;
validation.powerPassed = all(isfinite([validation.Pin, validation.Pload])) && ...
    validation.Pin > 0 && validation.Pload > 0;
validation.accepted = validation.kCheckPassed && validation.realImpedancePassed && ...
    validation.imagImpedancePassed && validation.converged && validation.powerPassed;

fprintf("    Physical Zin = %.9f %+.9fj ohm.\n", ...
    real(validation.Zin), imag(validation.Zin));
fprintf("    Pin = %.9f W, Pload = %.9f W, efficiency = %.6f%%.\n", ...
    validation.Pin, validation.Pload, 100*validation.efficiency);
fprintf("    Overall acceptance: %s.\n", passFail(validation.accepted));
end

function physical = runPhysicalValidation(design)
model = "SerialLink_physical";
period = 1/design.f;
duration = 20e-6;
converged = false;
convergenceError = Inf;
signalNames = ["vInput", "iInput", "iTx", "iRx", "vLoad"];

for runIndex = 1:5
    fprintf("    Transient run %d: stop time %.1f us.\n", runIndex, duration*1e6);
    simulationOutput = sim(model, StopTime=num2str(duration, 17), ...
        ReturnWorkspaceOutputs="on");
    latePhasor = zeros(1, numel(signalNames));
    previousPhasor = zeros(size(latePhasor));
    for signalIndex = 1:numel(signalNames)
        data = simulationOutput.get(signalNames(signalIndex));
        latePhasor(signalIndex) = windowPhasor(data.time, data.signals.values, ...
            duration - 20*period, duration, design.f);
        previousPhasor(signalIndex) = windowPhasor(data.time, data.signals.values, ...
            duration - 40*period, duration - 20*period, design.f);
    end
    convergenceError = max(abs(latePhasor - previousPhasor)./max(abs(latePhasor), 1e-9));
    fprintf("    Adjacent-window phasor change = %.6g.\n", convergenceError);
    if convergenceError < 1e-3
        converged = true;
        break;
    end
    duration = 2*duration;
end

Vinput = latePhasor(1);
Iinput = latePhasor(2);
Itx = latePhasor(3);
Irx = latePhasor(4);
Vload = latePhasor(5);
Zin = Vinput/Iinput;
Pin = real(Vinput*conj(Iinput));
Pload = abs(Vload)^2/design.RL;

physical = struct( ...
    "converged", converged, ...
    "convergenceError", convergenceError, ...
    "duration", duration, ...
    "Zin", Zin, ...
    "VinputRms", abs(Vinput), ...
    "IinputRms", abs(Iinput), ...
    "ItxRms", abs(Itx), ...
    "IrxRms", abs(Irx), ...
    "VloadRms", abs(Vload), ...
    "Pin", Pin, ...
    "Pload", Pload, ...
    "efficiency", Pload/Pin, ...
    "simulationOutput", simulationOutput);
end

function plotCouplingVerification(design, loadValues, coilEfficiency, optimumIndex)
kValues = linspace(0.1, 0.5, 161);
mutualValues = kValues*sqrt(design.L1*design.L2);
optimumLoads = sqrt(design.R2^2 + ...
    (design.omega*mutualValues).^2*design.R2/design.R1);

figureHandle = figure(Visible="off", Color="white", Position=[100 100 1000 720]);
layout = tiledlayout(2, 1, TileSpacing="compact", Padding="compact");

axesHandle = nexttile(layout);
plot(axesHandle, kValues, optimumLoads, LineWidth=1.6);
hold(axesHandle, "on");
referenceLine = yline(axesHandle, design.RL, "--", "Required R_L", LineWidth=1.2);
styleReferenceLine(referenceLine);
referenceLine = xline(axesHandle, design.k, "--", ...
    sprintf("k = %.6f", design.k), LineWidth=1.2);
styleReferenceLine(referenceLine);
plot(axesHandle, design.k, design.optimumLoadCheck, "o", MarkerSize=7, ...
    MarkerFaceColor=[0.85 0.2 0.2]);
grid(axesHandle, "on");
xlabel(axesHandle, "Coupling coefficient, k");
ylabel(axesHandle, "Efficiency-optimum load (ohm)");
title(axesHandle, "Step 2: k and M from the optimum-load condition");
styleAxes(axesHandle);

axesHandle = nexttile(layout);
plot(axesHandle, loadValues, coilEfficiency, LineWidth=1.6);
hold(axesHandle, "on");
referenceLine = xline(axesHandle, design.RL, "--", "Required R_L", LineWidth=1.2);
styleReferenceLine(referenceLine);
plot(axesHandle, loadValues(optimumIndex), coilEfficiency(optimumIndex), "o", ...
    MarkerSize=7, MarkerFaceColor=[0.85 0.2 0.2]);
grid(axesHandle, "on");
xlabel(axesHandle, "Load resistance (ohm)");
ylabel(axesHandle, "Coil-to-coil efficiency");
title(axesHandle, "Simulink verification at the derived coupling");
styleAxes(axesHandle);

exportgraphics(figureHandle, "01_k_and_M_verification.png", Resolution=180);
close(figureHandle);
end

function plotFrequencyVerification(design, frequencyValues, frequencyResults)
figureHandle = figure(Visible="off", Color="white", Position=[100 100 1000 760]);
layout = tiledlayout(3, 1, TileSpacing="compact", Padding="compact");
frequencyMHz = frequencyValues/1e6;

axesHandle = nexttile(layout);
plot(axesHandle, frequencyMHz, frequencyResults(:, 1), LineWidth=1.5);
hold(axesHandle, "on");
referenceLine = yline(axesHandle, design.ZinTarget, "--", "Target", LineWidth=1.1);
styleReferenceLine(referenceLine);
referenceLine = xline(axesHandle, design.f/1e6, "--", "13.56 MHz", LineWidth=1.1);
styleReferenceLine(referenceLine);
ylabel(axesHandle, "Re(Zin) (ohm)");
title(axesHandle, "Step 3 verification: final L and C");
grid(axesHandle, "on");
styleAxes(axesHandle);

axesHandle = nexttile(layout);
plot(axesHandle, frequencyMHz, frequencyResults(:, 2), LineWidth=1.5);
hold(axesHandle, "on");
referenceLine = yline(axesHandle, 0, "--", "Zero reactance", LineWidth=1.1);
styleReferenceLine(referenceLine);
referenceLine = xline(axesHandle, design.f/1e6, "--", LineWidth=1.1);
styleReferenceLine(referenceLine);
ylabel(axesHandle, "Im(Zin) (ohm)");
grid(axesHandle, "on");
styleAxes(axesHandle);

axesHandle = nexttile(layout);
plot(axesHandle, frequencyMHz, 100*frequencyResults(:, 3), LineWidth=1.5);
hold(axesHandle, "on");
referenceLine = xline(axesHandle, design.f/1e6, "--", LineWidth=1.1);
styleReferenceLine(referenceLine);
xlabel(axesHandle, "Frequency (MHz)");
ylabel(axesHandle, "Efficiency (%)");
grid(axesHandle, "on");
styleAxes(axesHandle);

exportgraphics(figureHandle, "02_frequency_verification.png", Resolution=180);
close(figureHandle);
end

function plotPhysicalVerification(design, simulationOutput, duration)
period = 1/design.f;
signalNames = ["vInput", "iInput", "vLoad"];
signalLabels = ["Input voltage (V)", "Input current (A)", "Load voltage (V)"];

figureHandle = figure(Visible="off", Color="white", Position=[100 100 1000 720]);
layout = tiledlayout(3, 1, TileSpacing="compact", Padding="compact");
for signalIndex = 1:numel(signalNames)
    data = simulationOutput.get(signalNames(signalIndex));
    keep = data.time > duration - 5*period;
    timeNs = (data.time(keep) - (duration - 5*period))*1e9;
    axesHandle = nexttile(layout);
    plot(axesHandle, timeNs, data.signals.values(keep), LineWidth=1.2);
    ylabel(axesHandle, signalLabels(signalIndex));
    grid(axesHandle, "on");
    styleAxes(axesHandle);
    if signalIndex == 1
        title(axesHandle, "Independent Simscape check: last five steady-state cycles");
    end
end
xlabel(axesHandle, "Time within final five cycles (ns)");

exportgraphics(figureHandle, "03_physical_Simscape_verification.png", Resolution=180);
close(figureHandle);
end

function phasor = windowPhasor(time, signal, startTime, endTime, frequency)
sampleTime = linspace(startTime, endTime, 801)';
sampleSignal = interp1(time, signal, sampleTime, "linear");
phasor = sqrt(2)*trapz(sampleTime, ...
    sampleSignal.*exp(-1i*2*pi*frequency*sampleTime))/(endTime - startTime);
end

function styleAxes(axesHandle)
axesHandle.Color = "white";
axesHandle.XColor = "black";
axesHandle.YColor = "black";
axesHandle.GridColor = [0.72 0.72 0.72];
axesHandle.MinorGridColor = [0.85 0.85 0.85];
axesHandle.Title.Color = "black";
axesHandle.XLabel.Color = "black";
axesHandle.YLabel.Color = "black";
end

function styleReferenceLine(lineHandle)
lineHandle.Color = [0.35 0.35 0.35];
lineHandle.LabelColor = [0.20 0.20 0.20];
end

function text = passFail(condition)
if condition
    text = "PASS";
else
    text = "FAIL";
end
end
