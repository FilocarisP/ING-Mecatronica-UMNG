syms s

% ============================
% Parámetros ajustados (coef s^4 = 1)
% ============================
M  = 1;
J1 = 2;
J2 = 3;
J3 = 4;
R1 = 1.0;
R2 = 0.8;
R3 = 0.6;
K1 = 50;
K2 = 60;
B  = 15;

% ============================
% Matrices estado
% ============================
A = [ 0  1   0  0;
     -(K2*R1^2 + K1)/(J1 + M*R1^2)   -(B*R1^2)/(J1 + M*R1^2)   (K1*R3/R2)/(J1 + M*R1^2)   0;
      0  0   0  1;
      (K1*R3/R2)/(J3 + J2*(R3^2)/(R2^2))  0  -(K2 + K1*(R3^2)/(R2^2))/(J3 + J2*(R3^2)/(R2^2))  0];

Bv = [0;
     R1/(J1 + M*R1^2);
     0;
     0];

C = [0 0 1 0];
D = 0;

% ============================
% Función de transferencia y polos
% ============================
[num, den] = ss2tf(A, Bv, C, D);
disp('Numerador:'); disp(num);
disp('Denominador:'); disp(den);

p = roots(den);
disp('Polos:'); disp(p);

% ============================
% Reducción a sistema de 2º orden
% ============================
numr = 0.05927;
denr = [1 0.4844 13.0987];
G_red = tf(numr, denr);

disp('============================');
disp('Función de transferencia reducida:');
G_red

% ============================
% Muestreo y conversión a discreto
% ============================
Tsla = 30;              % tiempo de asentamiento lazo abierto
Tm = Tsla / 300;        % tiempo de muestreo
disp(['Tiempo de muestreo Tm = ', num2str(Tm), ' s']);

Gd = c2d(G_red, Tm, 'zoh');
disp('============================');
disp('Función de transferencia discreta (c2d con zoh):');
Gd

% ============================
% Obtener numerador y denominador discretos
% ============================
[numd, dend] = tfdata(Gd, 'v');  % devuelve vectores en lugar de celdas
disp('Numerador discreto:');
disp(numd);
disp('Denominador discreto:');
disp(dend);

%%% ============================

%Retro estados

Gk = [0 1
     -0.9527 1.826];

Hk = [0 
       1];

Ck = [0.0002838 0.0002885];

Dk = [0];

Ge = [0 1 0
     -0.9527 1.826 0
     0.2749 -0.8106 1];

He = [0 
      1
      -0.0002885];

Se = [He Ge*He (Ge^2)*He]

iSe = inv(Se)

af1 = -10167;
af2 = 0.2826;
af3 = -0.0195;

I = [1 0 0
     0 1 0
     0 0 1];

og = [Ge^3+(af1*Ge^2)+(af2*Ge)+(af3*I)];

K = [0 0 1]*iSe*og;