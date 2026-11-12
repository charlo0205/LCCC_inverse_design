function validation = validate_design(design)
% Independent physical Simscape time-domain validation plus phasor sweeps.
fprintf('[8] Running final physical circuit validation\n');
mdl='LCCC_inverse_design'; f=design.f; T=1/f;
set_param([mdl '/L compensation'],'l',num2str(design.L,17));
set_param([mdl '/C shunt'],'c',num2str(design.C,17));
set_param([mdl '/C1 series'],'c',num2str(design.C1,17));
set_param([mdl '/C2 series'],'c',num2str(design.C2,17));
set_param([mdl '/Coupled coils'],'k',num2str(design.k,17));
save_system(mdl,[mdl '.slx']);
duration=20e-6; converged=false; err=Inf;
for run=1:5
    fprintf('    transient run %d: stop time %.1f us, solver ode23t, max step %.3f ns\n',run,duration*1e6,T/25*1e9);
    out=sim(mdl,'StopTime',num2str(duration,17),'ReturnWorkspaceOutputs','on');
    names={'v_input','i_input','i_tx','i_rx','v_load'};
    zlate=zeros(1,5); zprev=zlate;
    for j=1:5
        d=out.get(names{j}); t=d.time; x=d.signals.values;
        zlate(j)=window_phasor(t,x,duration-20*T,duration,f);
        zprev(j)=window_phasor(t,x,duration-40*T,duration-20*T,f);
    end
    err=max(abs(zlate-zprev)./max(abs(zlate),1e-9));
    fprintf('    steady-state phasor window change %.5g; samples=%d\n',err,numel(t));
    if err<1e-3, converged=true; break; end
    duration=duration*2;
end
V=zlate(1); I=zlate(2); Itx=zlate(3); Irx=zlate(4); Vl=zlate(5);
Zin=V/I; Pin=real(V*conj(I)); Pload=abs(Vl)^2/design.R;
validation=struct('converged',converged,'convergence_error',err,'duration_s',duration, ...
    'V_input_rms',abs(V),'I_input_rms',abs(I),'phase_deg',angle(V/I)*180/pi, ...
    'Zin',Zin,'I_tx_rms',abs(Itx),'I_rx_rms',abs(Irx),'V_load_rms',abs(Vl), ...
    'P_input_W',Pin,'P_load_W',Pload,'efficiency',Pload/Pin);
fprintf('    physical Zin=%.8f%+.8fj ohm, phase=%.5f deg, eta=%.6f\n',real(Zin),imag(Zin),validation.phase_deg,validation.efficiency);
fprintf('    Vrms=%.6f Irms=%.6f Itx=%.6f Irx=%.6f Vload=%.6f Pin=%.6f Pload=%.6f\n',abs(V),abs(I),abs(Itx),abs(Irx),abs(Vl),Pin,Pload);
fprintf('    accepted real-error=%d imag-error=%d converged=%d finite=%d\n',abs(real(Zin)-30)/30<0.01,abs(imag(Zin))<0.3,converged,all(isfinite([real(Zin) imag(Zin) Pin Pload])));
% Plot late physical waveforms (last 5 cycles).
fig=figure('Visible','off');
for j=1:5
    d=out.get(names{j}); ii=d.time>duration-5*T;
    subplot(5,1,j); plot((d.time(ii)-(duration-5*T))*1e9,d.signals.values(ii)); grid on;
    ylabel(strrep(names{j},'_','\_'));
end
xlabel('Time in last five cycles (ns)'); exportgraphics(fig,'physical_waveforms.png','Resolution',160); close(fig);

% Frequency and load sensitivity: each point is a fresh Simulink evaluation.
freqs=linspace(0.8*f,1.2*f,81); zf=zeros(size(freqs)); ef=zeros(size(freqs));
for j=1:numel(freqs)
    y=lccc_evaluate([design.k design.L design.C design.C1 design.C2 design.R freqs(j)]);
    zf(j)=complex(y(1),y(2)); ef(j)=y(3);
end
fig=figure('Visible','off'); subplot(2,1,1); plot(freqs/1e6,real(zf),freqs/1e6,imag(zf));
yline(30,'--'); grid on; ylabel('Zin (ohm)'); legend('Real','Imaginary','Target real');
subplot(2,1,2); plot(freqs/1e6,ef); grid on; xlabel('Frequency (MHz)'); ylabel('Efficiency');
exportgraphics(fig,'frequency_resonance.png','Resolution',160); close(fig);
loads=linspace(6,25,41); zl=zeros(size(loads)); il=zeros(size(loads)); el=zeros(size(loads));
for j=1:numel(loads)
    y=lccc_evaluate([design.k design.L design.C design.C1 design.C2 loads(j) f]);
    zl(j)=complex(y(1),y(2)); il(j)=y(5); el(j)=y(3);
end
fig=figure('Visible','off'); subplot(2,1,1); plot(loads,real(zl),loads,imag(zl)); grid on;
ylabel('Zin (ohm)'); legend('Real','Imaginary');
subplot(2,1,2); plot(loads,il); grid on; xlabel('Load (ohm)'); ylabel('Tx coil current (A rms)');
exportgraphics(fig,'load_sensitivity.png','Resolution',160); close(fig);
validation.load_current_variation=max(abs(il-design.phasor(5)))/design.phasor(5);
validation.load_sweep=[loads(:) real(zl(:)) imag(zl(:)) il(:) el(:)];
validation.frequency_sweep=[freqs(:) real(zf(:)) imag(zf(:)) ef(:)];
% Coupling and resistance perturbations, evaluated in Simulink.
variations=[0.9 1 1; 1.1 1 1; 1 0.8 0.8; 1 1.2 1.2];
sens=zeros(size(variations,1),5);
for j=1:size(variations,1)
    q=variations(j,:); y=lccc_evaluate([design.k*q(1) design.L design.C design.C1 design.C2 design.R f q(2) q(3)]);
    sens(j,:)=[q(1) q(2) y(1) y(2) y(3)];
end
validation.sensitivity=sens;
save('validation_results.mat','validation');
end

function z=window_phasor(t,x,t0,t1,f)
grid=linspace(t0,t1,801)';
y=interp1(t,x,grid,'linear');
z=sqrt(2)*trapz(grid,y.*exp(-1i*2*pi*f*grid))/(t1-t0);
end
