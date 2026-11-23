function [loadSummary, loadWaveforms] = compare_lcc_loads(out, frequencyHz)
%COMPARE_LCC_LOADS Tabulate measurements from the three-circuit LCC_C run.
%   [loadSummary, loadWaveforms] = compare_lcc_loads(out) uses 13.56 MHz.
%   Pass frequencyHz as a second input if the drive frequency changes.
%   Peak columns use the entire run. RMS, ripple RMS and mean load power
%   use the final ten periods and account for variable solver time steps.

arguments
    out (1,1) Simulink.SimulationOutput
    frequencyHz (1,1) double {mustBePositive, mustBeFinite} = 13.56e6
end

if ~ismember("simlog", string(who(out))) || ~isprop(out.simlog, "Resistor2")
    error("Run the three-circuit LCC_C model with Simscape logging set to All, then pass the new out.");
end

% Each row lists source, primary coil, load, shunt C, series C1, series C2.
blocks = [
    "AC_Voltage_Source",  "Mutual_Inductor",  "Resistor",  "Capacitor1", "Capacitor",  "Capacitor2"
    "AC_Voltage_Source1", "Mutual_Inductor1", "Resistor1", "Capacitor4", "Capacitor3", "Capacitor5"
    "AC_Voltage_Source2", "Mutual_Inductor2", "Resistor2", "Capacitor7", "Capacitor6", "Capacitor8"
];
blockColumns = [1 2 3 3 4 4 5 5 6 6];
variables = ["i", "v1", "v", "i", "v", "i", "v", "i", "v", "i"];
units = ["A", "V", "V", "A", "V", "A", "V", "A", "V", "A"];
signals = ["I_In", "V_Primary", "V_Load", "I_Load", ...
    "V_C", "I_C", "V_C1", "I_C1", "V_C2", "I_C2"];
capacitorCurrents = [6 8 10];

t = reshape(out.simlog.Resistor.v.series.time, [], 1);
modelInfo = out.SimulationMetadata.ModelInfo;
assert(t(1) <= modelInfo.StartTime && t(end) >= modelInfo.StopTime, ...
    "The log must cover the complete run. Check stop time and the Simscape logging history limit.");
assert(all(diff(t) > 0), "The logged time vector must be strictly increasing.");
windowStart = t(end) - 10 / frequencyHz;
assert(windowStart >= t(1), "The run must contain at least ten drive periods.");
inWindow = t > windowStart;
tWindow = [windowStart; t(inWindow)];
windowDuration = tWindow(end) - tWindow(1);

summaryNames = ["R_Load_Ohm", "P_Load_Avg_W", ...
    signals + "_Peak_" + units, signals + "_RMS_" + units, ...
    signals(capacitorCurrents) + "_Ripple_RMS_A"];
summaryData = zeros(size(blocks, 1), numel(summaryNames));
waveformTables = cell(size(blocks, 1), 1);

for circuit = 1:size(blocks, 1)
    data = zeros(numel(t), numel(signals));
    for signal = 1:numel(signals)
        node = out.simlog.(blocks(circuit, blockColumns(signal)));
        series = node.(variables(signal)).series;
        assert(isequal(reshape(series.time, [], 1), t), ...
            "All logged signals must share the same solver time vector.");
        data(:, signal) = reshape(series.values(units(signal)), [], 1);
    end

    % Source current is logged into its positive terminal. I_In is delivered
    % to the transmitter, matching the model's input current sensor.
    data(:, 1) = -data(:, 1);
    assert(all(isfinite(data(:))), "Voltage and current samples must be finite.");
    finalData = [interp1(t, data, windowStart); data(inWindow, :)];
    peaks = max(abs(data), [], 1);
    rmsValues = sqrt(trapz(tWindow, finalData.^2, 1) / windowDuration);

    loadVoltage = finalData(:, 3);
    loadCurrent = finalData(:, 4);
    loadPower = trapz(tWindow, loadVoltage .* loadCurrent) / windowDuration;
    assert(rmsValues(4) > 0, "The run must have nonzero load current to identify the load resistance.");
    % For the ideal Simscape resistors P = R * I_RMS^2. Read the load
    % from the same simulation data as the voltages and currents.
    loadOhm = round(loadPower / rmsValues(4)^2, 12, "significant");

    capCurrent = finalData(:, capacitorCurrents);
    capMean = trapz(tWindow, capCurrent, 1) / windowDuration;
    rippleRms = sqrt(trapz(tWindow, (capCurrent - capMean).^2, 1) / windowDuration);

    summaryData(circuit, :) = [loadOhm, loadPower, peaks, rmsValues, rippleRms];
    waveformTables{circuit} = array2table([repmat(loadOhm, numel(t), 1), t, data], ...
        VariableNames=["R_Load_Ohm", "Time_s", signals + "_" + units]);
end

loadSummary = array2table(summaryData, VariableNames=summaryNames);
loadWaveforms = vertcat(waveformTables{:});
end
