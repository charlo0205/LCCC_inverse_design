function build_model(design)
% Programmatic Simulink and physical Simscape construction.
if nargin==0
    design=struct('k',0.2,'L',200e-9,'C',1/(2*pi*13.56e6)^2/200e-9, ...
       'C1',1/(2*pi*13.56e6)^2/(486.02e-9-200e-9),'C2',1/(2*pi*13.56e6)^2/486.02e-9);
end
f=13.56e6; w=2*pi*f; L1=486.02e-9; L2=L1; R1=w*L1/951.1; R2=w*L2/931;
fprintf('[2] Building Simulink models; initial k=%.4f L=%.3f nH\n',design.k,design.L*1e9);
for name={'LCCC_phasor','LCCC_inverse_design'}
    if bdIsLoaded(name{1}), close_system(name{1},0); end
end
new_system('LCCC_phasor');
add_block('simulink/Sources/Constant','LCCC_phasor/Parameters','Value',mat2str([design.k design.L design.C design.C1 design.C2 12.5 f],17),'Position',[60 70 200 100]);
add_block('simulink/User-Defined Functions/Interpreted MATLAB Function','LCCC_phasor/Network equations','MATLABFcn','phasor_network(u)','OutputDimensions','11','Position',[270 60 460 110]);
add_block('simulink/Sinks/To Workspace','LCCC_phasor/Results','VariableName','phasor_result','SaveFormat','Array','Position',[540 70 680 100]);
add_line('LCCC_phasor','Parameters/1','Network equations/1'); add_line('LCCC_phasor','Network equations/1','Results/1');
set_param('LCCC_phasor','Solver','FixedStepDiscrete','FixedStep','1','StopTime','0');
save_system('LCCC_phasor','LCCC_phasor.slx');

load_system('fl_lib'); load_system('nesl_utility');
new_system('LCCC_inverse_design'); mdl='LCCC_inverse_design';
add_block('fl_lib/Electrical/Electrical Sources/AC Voltage Source',[mdl '/AC source'],'amp',num2str(sqrt(2),17),'frequency',num2str(f,17),'Position',[35 220 80 270]);
add_block('fl_lib/Electrical/Electrical Sensors/Current Sensor',[mdl '/Input current'],'Position',[115 205 155 245]);
add_block('fl_lib/Electrical/Electrical Elements/Inductor',[mdl '/L compensation'],'l',num2str(design.L,17),'r','0','Position',[195 205 235 245]);
add_block('fl_lib/Electrical/Electrical Elements/Capacitor',[mdl '/C shunt'],'c',num2str(design.C,17),'r','0','Position',[280 315 320 355]);
add_block('fl_lib/Electrical/Electrical Elements/Capacitor',[mdl '/C1 series'],'c',num2str(design.C1,17),'r','0','Position',[360 205 400 245]);
add_block('fl_lib/Electrical/Electrical Sensors/Current Sensor',[mdl '/Tx coil current'],'Position',[435 205 475 245]);
add_block('fl_lib/Electrical/Electrical Elements/Resistor',[mdl '/R1 winding'],'R',num2str(R1,17),'Position',[510 205 550 245]);
add_block('fl_lib/Electrical/Electrical Elements/Mutual Inductor',[mdl '/Coupled coils'],'L1',num2str(L1,17),'L2',num2str(L2,17),'k',num2str(design.k,17),'Position',[595 195 665 300]);
add_block('fl_lib/Electrical/Electrical Elements/Resistor',[mdl '/R2 winding'],'R',num2str(R2,17),'Position',[710 205 750 245]);
add_block('fl_lib/Electrical/Electrical Elements/Capacitor',[mdl '/C2 series'],'c',num2str(design.C2,17),'r','0','Position',[790 205 830 245]);
add_block('fl_lib/Electrical/Electrical Sensors/Current Sensor',[mdl '/Rx current'],'Position',[865 205 905 245]);
add_block('fl_lib/Electrical/Electrical Elements/Resistor',[mdl '/Load'],'R','12.5','Position',[950 300 990 340]);
add_block('fl_lib/Electrical/Electrical Sensors/Voltage Sensor',[mdl '/Input voltage'],'Position',[50 350 90 390]);
add_block('fl_lib/Electrical/Electrical Sensors/Voltage Sensor',[mdl '/Load voltage'],'Position',[1020 300 1060 340]);
add_block('fl_lib/Electrical/Electrical Elements/Electrical Reference',[mdl '/Ground'],'Position',[420 440 460 480]);
add_block('nesl_utility/Solver Configuration',[mdl '/Solver Configuration'],'Position',[300 440 340 480]);
% Physical port handles: LConn is left, RConn is right; mutual has two of each.
wire(mdl,'AC source','RConn',1,'Input current','LConn',1);
wire(mdl,'Input current','RConn',2,'L compensation','LConn',1);
wire(mdl,'L compensation','RConn',1,'C shunt','LConn',1);
wire(mdl,'L compensation','RConn',1,'C1 series','LConn',1);
wire(mdl,'C1 series','RConn',1,'Tx coil current','LConn',1);
wire(mdl,'Tx coil current','RConn',2,'R1 winding','LConn',1);
wire(mdl,'R1 winding','RConn',1,'Coupled coils','LConn',1);
wire(mdl,'Coupled coils','LConn',2,'Ground','LConn',1);
wire(mdl,'Coupled coils','RConn',1,'R2 winding','LConn',1);
wire(mdl,'R2 winding','RConn',1,'C2 series','LConn',1);
wire(mdl,'C2 series','RConn',1,'Rx current','LConn',1);
wire(mdl,'Rx current','RConn',2,'Load','LConn',1);
wire(mdl,'Load','RConn',1,'Ground','LConn',1);
wire(mdl,'Coupled coils','RConn',2,'Ground','LConn',1);
wire(mdl,'C shunt','RConn',1,'Ground','LConn',1);
wire(mdl,'AC source','LConn',1,'Ground','LConn',1);
wire(mdl,'AC source','RConn',1,'Input voltage','LConn',1);
wire(mdl,'Input voltage','RConn',2,'Ground','LConn',1);
wire(mdl,'Load','LConn',1,'Load voltage','LConn',1);
wire(mdl,'Load voltage','RConn',2,'Ground','LConn',1);
wire(mdl,'Solver Configuration','RConn',1,'Ground','LConn',1);
signals={'Input voltage','v_input';'Input current','i_input';'Tx coil current','i_tx';'Rx current','i_rx';'Load voltage','v_load'};
for j=1:size(signals,1)
    src=signals{j,1}; var=signals{j,2};
    cv=[mdl '/Convert ' var]; to=[mdl '/Save ' var];
    add_block(sprintf('nesl_utility/PS-Simulink\nConverter'),cv,'Position',[230+160*j 35 270+160*j 65]);
    add_block('simulink/Sinks/To Workspace',to,'VariableName',var,'SaveFormat','StructureWithTime','Position',[300+160*j 35 420+160*j 65]);
    hs=get_param([mdl '/' src],'PortHandles'); hc=get_param(cv,'PortHandles'); ht=get_param(to,'PortHandles');
    ps=hs.RConn(1);
    add_line(mdl,ps,hc.LConn(1),'autorouting','on');
    add_line(mdl,hc.Outport(1),ht.Inport(1),'autorouting','on');
end
set_param(mdl,'Solver','ode23t','RelTol','1e-6','AbsTol','1e-9','MaxStep',num2str(1/(f*25),17),'StopTime','5e-5','ReturnWorkspaceOutputs','on');
save_system(mdl,[mdl '.slx']);
fprintf('[3] Checking circuit connectivity and compiling both models\n');
set_param('LCCC_phasor','SimulationCommand','update');
set_param(mdl,'SimulationCommand','update');
fprintf('    Build and compile passed. R1=%.6f ohm R2=%.6f ohm\n',R1,R2);
end

function wire(mdl,a,pa,ia,b,pb,ib)
ha=get_param([mdl '/' a],'PortHandles'); hb=get_param([mdl '/' b],'PortHandles');
add_line(mdl,ha.(pa)(ia),hb.(pb)(ib),'autorouting','on');
end
