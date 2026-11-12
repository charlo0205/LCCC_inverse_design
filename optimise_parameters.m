function design = optimise_parameters()
% Simulation-driven inverse design. Every efficiency/impedance objective
% comes from sim('LCCC_phasor'), not from a MATLAB-only circuit calculation.
f=13.56e6; w=2*pi*f; L1=486.02e-9; L2=L1; Rtarget=12.5;
R1=w*L1/951.1; R2=w*L2/931;
C2=1/(w*w*L2);
rows=zeros(0,15); stages=strings(0,1); iter=0;
fprintf('[4] Running coupling coefficient and load sweep through Simulink\n');
ks=linspace(0.05,0.6,12); Rs=logspace(log10(0.3),log10(45),45);
eta=zeros(numel(ks),numel(Rs)); rbest=zeros(size(ks));
for ik=1:numel(ks)
    for ir=1:numel(Rs)
        y=eval_at(ks(ik),200e-9,1/(w*w*200e-9),1/(w*w*(L1-200e-9)),C2,Rs(ir),'coupling_sweep');
        eta(ik,ir)=y(11);
    end
    [~,idx]=max(eta(ik,:)); rbest(ik)=Rs(idx);
    fprintf('    k=%.4f: simulated R_opt grid=%.3f ohm, peak coil efficiency=%.5f\n',ks(ik),rbest(ik),max(eta(ik,:)));
end
fig=figure('Visible','off'); plot(Rs,eta','LineWidth',1); set(gca,'XScale','log'); grid on;
xlabel('Load resistance (ohm)'); ylabel('Coil-to-coil efficiency'); title('Simulink efficiency sweeps at candidate coupling');
legend(compose('k=%.2f',ks),'Location','eastoutside'); exportgraphics(fig,'efficiency_sweeps.png','Resolution',160); close(fig);
fig=figure('Visible','off'); plot(ks,rbest,'o-'); yline(Rtarget,'--'); grid on;
xlabel('Coupling coefficient k'); ylabel('Grid-optimal load (ohm)'); title('Optimum-load matching criterion');
exportgraphics(fig,'optimum_load.png','Resolution',160); close(fig);
fprintf('[5] Numerically matching the simulated optimum load to 12.5 ohm\n');
optsR=optimset('TolX',1e-4,'Display','off');
rootfun=@(k) r_optimum(k)-Rtarget;
k=fzero(rootfun,[0.05 0.6],optimset('TolX',1e-6,'Display','off'));
Ropt=r_optimum(k); M=k*sqrt(L1*L2);
fprintf('    k=%.9f, M=%.6f nH, simulated R_opt=%.6f ohm\n',k,M*1e9,Ropt);
Rfine=linspace(8,17,61); efine=zeros(size(Rfine));
for j=1:numel(Rfine)
    y=eval_at(k,200e-9,1/(w*w*200e-9),1/(w*w*(L1-200e-9)),C2,Rfine(j),'coupling_refine');
    efine(j)=y(11);
end
fig=figure('Visible','off'); plot(Rfine,efine,'LineWidth',1.5); xline(Rtarget,'--'); grid on;
xlabel('Load resistance (ohm)'); ylabel('Coil-to-coil efficiency'); title('Refined load sweep at matched coupling');
exportgraphics(fig,'efficiency_refined.png','Resolution',160); close(fig);

fprintf('[6] Running L and C parameter sweep using the Simulink evaluator\n');
Lgrid=linspace(80e-9,400e-9,25); Zgrid=zeros(size(Lgrid));
for j=1:numel(Lgrid)
    Lj=Lgrid(j); Cj=1/(w*w*Lj); C1j=1/(w*w*(L1-Lj));
    y=eval_at(k,Lj,Cj,C1j,C2,Rtarget,'LC_sweep'); Zgrid(j)=y(1);
    if mod(j,5)==0, fprintf('    L=%.2f nH C=%.3f nF simulated Zin=%.3f%+.3fj ohm\n',Lj*1e9,Cj*1e9,y(1),y(2)); end
end
fig=figure('Visible','off'); plot(Lgrid*1e9,Zgrid,'o-'); yline(30,'--'); grid on;
xlabel('L (nH)'); ylabel('Real input impedance (ohm)'); title('Resonant L sweep, C and C1 retuned');
exportgraphics(fig,'impedance_sweep.png','Resolution',160); close(fig);
fprintf('[7] Refining L and C from three independent starting points\n');
starts=[110e-9,1/(w*w*110e-9)*0.8; 230e-9,1/(w*w*230e-9)*1.2; 360e-9,1/(w*w*360e-9)*0.9];
solutions=zeros(3,3);
for s=1:3
    x0=log(starts(s,:)./[1e-9 1e-9]);
    [x,v,exitflag]=fminsearch(@lc_objective,x0,optimset('TolX',1e-9,'TolFun',1e-10,'MaxFunEvals',220,'MaxIter',150,'Display','off'));
    solutions(s,:)=[exp(x(1))*1e-9 exp(x(2))*1e-9 v];
    fprintf('    start %d status=%d L=%.6f nH C=%.9f nF objective=%.4g\n',s,exitflag,solutions(s,1)*1e9,solutions(s,2)*1e9,v);
end
[~,ib]=min(solutions(:,3)); L=solutions(ib,1); C=solutions(ib,2);
C1=1/(w*w*(L1-L)); y=eval_at(k,L,C,C1,C2,Rtarget,'final');
design=struct('f',f,'R',Rtarget,'L1',L1,'L2',L2,'R1',R1,'R2',R2,'Q1',951.1,'Q2',931, ...
    'k',k,'M',M,'L',L,'C',C,'C1',C1,'C2',C2,'Ropt',Ropt,'phasor',y,'starts',solutions);
T=array2table(rows,'VariableNames',{'iteration','k','R_ohm','L_H','C_F','C1_F','C2_F','M_H','Zreal_ohm','Zimag_ohm','efficiency','coil_efficiency','Pin_W','Pload_W','objective'});
T.stage=stages; T=movevars(T,'stage','Before',1); writetable(T,'results.csv');
save('design_results.mat','design','T');
fprintf('    Final simulated Zin=%.9f%+.9fj ohm; efficiency=%.6f\n',y(1),y(2),y(3));

    function y=eval_at(kk,LL,CC,CC1,CC2,RR,stage)
        y=lccc_evaluate([kk LL CC CC1 CC2 RR f]);
        iter=iter+1;
        obj=((y(1)-30)/30)^2+(y(2)/30)^2+(w*w*LL*CC-1)^2;
        rows(end+1,:)=[iter kk RR LL CC CC1 CC2 kk*sqrt(L1*L2) y(1) y(2) y(3) y(11) y(8) y(9) obj];
        stages(end+1,1)=string(stage);
        if mod(iter,100)==0
            fprintf('    iteration=%d k=%.5f L=%.3f nH C=%.4f nF R=%.3f Zin=%.3f%+.3fj eta=%.5f error=%.4g solver=OK\n',iter,kk,LL*1e9,CC*1e9,RR,y(1),y(2),y(3),obj);
        end
    end
    function ro=r_optimum(kk)
        [ro,negE,flag]=fminbnd(@(RR) -coil_eta(kk,RR),0.2,40,optsR);
        fprintf('    root trial k=%.8f R_opt=%.6f eta=%.6f status=%d\n',kk,ro,-negE,flag);
    end
    function z=coil_eta(kk,RR)
        yy=eval_at(kk,200e-9,1/(w*w*200e-9),1/(w*w*(L1-200e-9)),C2,RR,'coupling_root');
        z=yy(11);
    end
    function e=lc_objective(x)
        LL=exp(x(1))*1e-9; CC=exp(x(2))*1e-9;
        if LL<20e-9 || LL>L1-10e-9 || CC<0.05e-9 || CC>10e-9
            e=1e4+norm(x)^2; return
        end
        CC1=1/(w*w*(L1-LL));
        yy=eval_at(k,LL,CC,CC1,C2,Rtarget,'LC_optimisation');
        e=((yy(1)-30)/30)^2+(yy(2)/30)^2+3*(w*w*LL*CC-1)^2;
        if mod(iter,25)==0
            fprintf('    iteration=%d L=%.6f nH C=%.6f nF Zin=%.5f%+.5fj eta=%.5f error=%.4g solver=OK\n',iter,LL*1e9,CC*1e9,yy(1),yy(2),yy(3),e);
        end
    end
end
