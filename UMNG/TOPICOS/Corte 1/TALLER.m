
% Tópicos Taller 1

clc; clear; close all;

syms s;
%% PUNTO 3
num = 1;
den = s^2 + 2*s + 48;

ft = num/den

disp('La función de transferencia es:')
pretty(ft)

A = [0 1;
    -48 -2];

B = [0; 1;];

C = [1 0];

D = 0;

%Retro estados

% Construcción automática de M
M = [2 1;
     1 0]

disp('Matriz M construida automáticamente:')
disp(M)


% Forma Canónica de Control (FCC)
T=0;

S = [B A*B ]
det(S)
O = [C;
     C*A]
det(O)

SI = eye(2)*s;
SIA= vpa(det(SI-A))

T= S*M

Afcc = inv(T) * A * T;
Bfcc = inv(T) * B;
Cfcc = C * T;
Dfcc = D;

disp('Matrices en Forma Canónica de Control:')
disp('Afcc ='); disp(Afcc)
disp('Bfcc ='); disp(Bfcc)
disp('Cfcc ='); disp(Cfcc)

% Forma Canónica de Observación (FCO)
O = [C; C*A];

Q = inv(M * O);

Afco = inv(Q) * A * Q;
Bfco = inv(Q) * B;
Cfco = C * Q;
Dfco = D;

disp('Matrices en Forma Canónica de Observación:')
disp('Afco ='); disp(Afco)
disp('Bfco ='); disp(Bfco)
disp('Cfco ='); disp(Cfco)

%pol des

% Parámetros de diseño
ts = 5;
z  = 0.5;
wn = 4/(ts*z);

% Polinomio deseado

phi = expand((s^2 + 2*z*wn*s + wn^2)*(s + 10*z*wn)^2);
coeffs_phi = sym2poly(phi);   % [1 alfa1 alfa2 alfa3 alfa4]
alfa1 = coeffs_phi(2);
alfa2 = coeffs_phi(3);
alfa3 = coeffs_phi(4);
alfa4 = coeffs_phi(5);

%Ackerman

% --- Sistema aumentado (4x4) ---
Aemp = [ A       [0;0];      % bloque superior
        -C        0  ];      % integra error
Aemp = [Aemp [0;0;0];        % completar cuarta columna
        0 0 1 0];            % ultima fila

Bemp = [B; 0; 0];

disp('Matriz Aemp (4x4) ='); disp(Aemp)
disp('Matriz Bemp (4x1) ='); disp(Bemp)

% --- Polinomio deseado ---
ts = 4.75;
z  = 0.7;
wn = 4/(ts*z);


phi = expand((s^2 + 2*z*wn*s + wn^2)*(s + 10*z*wn)^2); % polinomio 4to orden
phi_decimal = vpa(phi, 3);
coeffs_phi = sym2poly(phi_decimal);   % [1 alfa1 alfa2 alfa3 alfa4]

alfa1 = coeffs_phi(2);
alfa2 = coeffs_phi(3);
alfa3 = coeffs_phi(4);
alfa4 = coeffs_phi(5);

disp('Coeficientes del polinomio deseado:');
fprintf('alfa1 = %.4f\n',alfa1);
fprintf('alfa2 = %.4f\n',alfa2);
fprintf('alfa3 = %.4f\n',alfa3);
fprintf('alfa4 = %.4f\n',alfa4);

% --- Evaluar phi(Aemp) ---
phiA = Aemp^4 + alfa1*Aemp^3 + alfa2*Aemp^2 + alfa3*Aemp + alfa4*eye(4);

% --- Matriz de controlabilidad ---
Semp = [Bemp Aemp*Bemp Aemp^2*Bemp Aemp^3*Bemp];
disp('Rango de S (debe ser 4):'); disp(rank(S));

% --- Ganancia K con Ackermann ---
K = [0 0 0 1]*inv(Semp)*phiA;
disp('Ganancia K ='); disp(K);

%%Observador

ts_obs = ts/2;     % tiempo de establecimiento del observador
z_obs  = 0.7;      
wn_obs = 4/(ts_obs*z_obs);

% Polinomio deseado (ejemplo con 2 polos complejos)
phi_obs = expand((s^2 + 2*z_obs*wn_obs*s + wn_obs^2));
phi_decimalobs = vpa(phi_obs, 3);
coeffs_obs = sym2poly(phi_decimalobs);

beta1 = coeffs_obs(2);
beta2 = coeffs_obs(3);

% Matriz polinómica de Ackermann para observador
phiA_obs = A^2 + beta1*A + beta2*eye(2);

% Observabilidad
O = [C; C*A];

% Vector canónico
e2 = [0;1];

% Ganancia
L = (phiA_obs * inv(O) * e2);
disp(L)



% Función de transferencia continua
num = 1;
den = [1 2 48];
G = tf(num,den);

% Periodo de muestreo
Ts = 0.05;   % <-- aquí defines tu periodo de muestreo

% Paso a discreto (ZOH)
Gd = c2d(G, Ts, 'zoh');

disp('Función de transferencia discreta:')
Gd

%% PUNTO 4


