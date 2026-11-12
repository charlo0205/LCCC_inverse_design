function y = phasor_network(u)
% Exact single-frequency network equations evaluated inside Simulink.
% u = [k L C C1 C2 R f], output uses 1 V rms excitation.
k=u(1); L=u(2); C=u(3); C1=u(4); C2=u(5); R=u(6); f=u(7);
L1=486.02e-9; L2=486.02e-9; Q1=951.1; Q2=931;
w=2*pi*f; w0=2*pi*13.56e6; R1=w0*L1/Q1; R2=w0*L2/Q2;
if numel(u)>=9, R1=R1*u(8); R2=R2*u(9); end
M=k*sqrt(L1*L2);
Z2=R2+R+1i*(w*L2-1/(w*C2));
Zref=(w*M)^2/Z2;
Zb=R1+1i*w*L1+Zref+1/(1i*w*C1);
Zsh=1/(1/Zb+1i*w*C);
Zin=1i*w*L+Zsh;
Iin=1/Zin; Va=Iin*Zsh; I1=Va/Zb; I2=-1i*w*M*I1/Z2;
Pin=real(conj(Iin)); Pload=abs(I2)^2*R;
Pcoil=abs(I1)^2*(R1+real(Zref));
y=[real(Zin) imag(Zin) Pload/Pin abs(Iin) abs(I1) abs(I2) abs(I2)*R Pin Pload -angle(Iin)*180/pi Pload/Pcoil];
end
