function y = phasor_network(p)
%PHASOR_NETWORK Evaluate the complete LCC-C network at one frequency.
%   p = [f RL L1 L2 R1 R2 k L C C1 C2]. The source is 1 V rms.
%   y = [Re(Zin) Im(Zin) eta |Iin| |I1| |I2| |Vload| Pin Pload
%        phase(Zin) coilEfficiency].

f = p(1);
RL = p(2);
L1 = p(3);
L2 = p(4);
R1 = p(5);
R2 = p(6);
k = p(7);
L = p(8);
C = p(9);
C1 = p(10);
C2 = p(11);

omega = 2*pi*f;
M = k*sqrt(L1*L2);

Zsecondary = R2 + RL + 1i*(omega*L2 - 1/(omega*C2));
Zreflected = (omega*M)^2/Zsecondary;
Ztransmitter = R1 + 1i*omega*L1 + Zreflected + 1/(1i*omega*C1);
Zparallel = 1/(1/Ztransmitter + 1i*omega*C);
Zin = 1i*omega*L + Zparallel;

Vin = 1;
Iin = Vin/Zin;
Vparallel = Iin*Zparallel;
I1 = Vparallel/Ztransmitter;
I2 = -1i*omega*M*I1/Zsecondary;
Vload = I2*RL;
Pin = real(Vin*conj(Iin));
Pload = abs(I2)^2*RL;
PcoilInput = abs(I1)^2*(R1 + real(Zreflected));

y = [real(Zin), imag(Zin), Pload/Pin, abs(Iin), abs(I1), abs(I2), ...
    abs(Vload), Pin, Pload, angle(Zin)*180/pi, Pload/PcoilInput];
end
