function build_models(design)
%BUILD_MODELS Build the phasor evaluator and physical Simscape model.

arguments
    design (1,1) struct
end

modelNames = ["SerialLink_phasor", "SerialLink_physical"];
for modelName = modelNames
    if bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
    modelFile = modelName + ".slx";
    if isfile(modelFile)
        delete(modelFile);
    end
end

buildPhasorModel(design);
buildPhysicalModel(design);

set_param("SerialLink_phasor", "SimulationCommand", "update");
set_param("SerialLink_physical", "SimulationCommand", "update");
fprintf("    Both models compiled successfully.\n");
end

function buildPhasorModel(design)
model = "SerialLink_phasor";
new_system(model);
parameters = [design.f, design.RL, design.L1, design.L2, design.R1, ...
    design.R2, design.k, design.L, design.C, design.C1, design.C2];

add_block("simulink/Sources/Constant", model + "/Parameters", ...
    Value=mat2str(parameters, 17), Position=[55 70 210 105]);
add_block("simulink/User-Defined Functions/Interpreted MATLAB Function", ...
    model + "/Network equations", MATLABFcn="phasor_network(u)", ...
    OutputDimensions="11", Position=[280 60 475 115]);
add_block("simulink/Sinks/To Workspace", model + "/Results", ...
    VariableName="phasorResult", SaveFormat="Array", Position=[550 72 690 103]);
add_line(model, "Parameters/1", "Network equations/1");
add_line(model, "Network equations/1", "Results/1");
set_param(model, Solver="FixedStepDiscrete", FixedStep="1", StopTime="0");
save_system(model, model + ".slx");
end

function buildPhysicalModel(design)
load_system("fl_lib");
load_system("nesl_utility");
model = "SerialLink_physical";
new_system(model);

add_block("fl_lib/Electrical/Electrical Sources/AC Voltage Source", model + "/AC source", ...
    amp=num2str(sqrt(2), 17), frequency=num2str(design.f, 17), Position=[35 220 80 270]);
add_block("fl_lib/Electrical/Electrical Sensors/Current Sensor", model + "/Input current", ...
    Position=[115 205 155 245]);
add_block("fl_lib/Electrical/Electrical Elements/Inductor", model + "/Compensation L", ...
    l=num2str(design.L, 17), r="0", Position=[195 205 235 245]);
add_block("fl_lib/Electrical/Electrical Elements/Capacitor", model + "/Shunt C", ...
    c=num2str(design.C, 17), r="0", Position=[280 315 320 355]);
add_block("fl_lib/Electrical/Electrical Elements/Capacitor", model + "/Series C1", ...
    c=num2str(design.C1, 17), r="0", Position=[360 205 400 245]);
add_block("fl_lib/Electrical/Electrical Sensors/Current Sensor", model + "/Tx current", ...
    Position=[435 205 475 245]);
add_block("fl_lib/Electrical/Electrical Elements/Resistor", model + "/Winding R1", ...
    R=num2str(design.R1, 17), Position=[510 205 550 245]);
add_block("fl_lib/Electrical/Electrical Elements/Mutual Inductor", model + "/Coupled coils", ...
    L1=num2str(design.L1, 17), L2=num2str(design.L2, 17), ...
    k=num2str(design.k, 17), Position=[595 195 665 300]);
add_block("fl_lib/Electrical/Electrical Elements/Resistor", model + "/Winding R2", ...
    R=num2str(design.R2, 17), Position=[710 205 750 245]);
add_block("fl_lib/Electrical/Electrical Elements/Capacitor", model + "/Series C2", ...
    c=num2str(design.C2, 17), r="0", Position=[790 205 830 245]);
add_block("fl_lib/Electrical/Electrical Sensors/Current Sensor", model + "/Rx current", ...
    Position=[865 205 905 245]);
add_block("fl_lib/Electrical/Electrical Elements/Resistor", model + "/Load RL", ...
    R=num2str(design.RL, 17), Position=[950 300 990 340]);
add_block("fl_lib/Electrical/Electrical Sensors/Voltage Sensor", model + "/Input voltage", ...
    Position=[50 350 90 390]);
add_block("fl_lib/Electrical/Electrical Sensors/Voltage Sensor", model + "/Load voltage", ...
    Position=[1020 300 1060 340]);
add_block("fl_lib/Electrical/Electrical Elements/Electrical Reference", model + "/Ground", ...
    Position=[420 440 460 480]);
add_block("nesl_utility/Solver Configuration", model + "/Solver Configuration", ...
    Position=[300 440 340 480]);

wirePhysicalPort(model, "AC source", "RConn", 1, "Input current", "LConn", 1);
wirePhysicalPort(model, "Input current", "RConn", 2, "Compensation L", "LConn", 1);
wirePhysicalPort(model, "Compensation L", "RConn", 1, "Shunt C", "LConn", 1);
wirePhysicalPort(model, "Compensation L", "RConn", 1, "Series C1", "LConn", 1);
wirePhysicalPort(model, "Series C1", "RConn", 1, "Tx current", "LConn", 1);
wirePhysicalPort(model, "Tx current", "RConn", 2, "Winding R1", "LConn", 1);
wirePhysicalPort(model, "Winding R1", "RConn", 1, "Coupled coils", "LConn", 1);
wirePhysicalPort(model, "Coupled coils", "LConn", 2, "Ground", "LConn", 1);
wirePhysicalPort(model, "Coupled coils", "RConn", 1, "Winding R2", "LConn", 1);
wirePhysicalPort(model, "Winding R2", "RConn", 1, "Series C2", "LConn", 1);
wirePhysicalPort(model, "Series C2", "RConn", 1, "Rx current", "LConn", 1);
wirePhysicalPort(model, "Rx current", "RConn", 2, "Load RL", "LConn", 1);
wirePhysicalPort(model, "Load RL", "RConn", 1, "Ground", "LConn", 1);
wirePhysicalPort(model, "Coupled coils", "RConn", 2, "Ground", "LConn", 1);
wirePhysicalPort(model, "Shunt C", "RConn", 1, "Ground", "LConn", 1);
wirePhysicalPort(model, "AC source", "LConn", 1, "Ground", "LConn", 1);
wirePhysicalPort(model, "AC source", "RConn", 1, "Input voltage", "LConn", 1);
wirePhysicalPort(model, "Input voltage", "RConn", 2, "Ground", "LConn", 1);
wirePhysicalPort(model, "Load RL", "LConn", 1, "Load voltage", "LConn", 1);
wirePhysicalPort(model, "Load voltage", "RConn", 2, "Ground", "LConn", 1);
wirePhysicalPort(model, "Solver Configuration", "RConn", 1, "Ground", "LConn", 1);

signals = {"Input voltage", "vInput"; "Input current", "iInput"; ...
    "Tx current", "iTx"; "Rx current", "iRx"; "Load voltage", "vLoad"};
for signalIndex = 1:size(signals, 1)
    sensorName = signals{signalIndex, 1};
    variableName = signals{signalIndex, 2};
    converterPath = model + "/Convert " + variableName;
    savePath = model + "/Save " + variableName;
    xPosition = 230 + 160*signalIndex;
    add_block(sprintf("nesl_utility/PS-Simulink\nConverter"), converterPath, ...
        Position=[xPosition 35 xPosition + 40 65]);
    add_block("simulink/Sinks/To Workspace", savePath, ...
        VariableName=variableName, SaveFormat="StructureWithTime", ...
        Position=[xPosition + 70 35 xPosition + 190 65]);
    sensorPorts = get_param(model + "/" + sensorName, "PortHandles");
    converterPorts = get_param(converterPath, "PortHandles");
    savePorts = get_param(savePath, "PortHandles");
    add_line(model, sensorPorts.RConn(1), converterPorts.LConn(1), Autorouting="on");
    add_line(model, converterPorts.Outport(1), savePorts.Inport(1), Autorouting="on");
end

maxStep = 1/(design.f*25);
set_param(model, Solver="ode23t", RelTol="1e-6", AbsTol="1e-9", ...
    MaxStep=num2str(maxStep, 17), StopTime="5e-5", ReturnWorkspaceOutputs="on");
save_system(model, model + ".slx");
end

function wirePhysicalPort(model, source, sourcePortType, sourceIndex, ...
        destination, destinationPortType, destinationIndex)
sourcePorts = get_param(model + "/" + source, "PortHandles");
destinationPorts = get_param(model + "/" + destination, "PortHandles");
add_line(model, sourcePorts.(sourcePortType)(sourceIndex), ...
    destinationPorts.(destinationPortType)(destinationIndex), Autorouting="on");
end
