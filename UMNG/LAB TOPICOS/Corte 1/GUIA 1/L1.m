%% Controladores
clc; clear; close all;
w=1; amp=1;

syms k_1 k_2 k_3 k_4 k_i s l1 l2 l3 l4 
SI = eye(5)*s;

% Parámetros de diseño
ts = 1;
z = 0.5;
wnd = 4/(ts*z);
%% Coeficientes del polinomio deseado (s^2 + 2*ζ*ω_n*s + ω_n^2)*(s + 10*ζ*ω_n)^2
alfa1 = 128 / ts;
alfa2 = (16 * (360*z^2 + 1)) / (ts^2 * z^2);
alfa3 = (640 * (160*z^2 + 3)) / (ts^3 * z^2);
alfa4 = (25600 * (20*z^2 + 3)) / (ts^4 * z^2);
alfa5 = 1024000 / (ts^5 * z^2);

% Parámetros físicos
k1 = 20; 
k2 = 30; 
b1 = 4; 
b2 = 3;
M = 1; 
m = 1.5; 
g = 9.81;
L = 0.3; 

x_op = 0.5;

% Matriz A y B del sistema linealizado
A = [0 1 0 0;
    -(k1+k2)/m -(b1+b2)/m M*g/m 0;
    0 0 0 1;
    (k1+k2)/(m*L) (b1+b2)/(m*L) ((-M/m)-1)*g/L 0];

B = [0; 1/m; 0; -1/(m*L)];

% Entrada PERTURBACION
E = [0; M/m; 0; -M + m/L*m];
FM =[0];
C = [1 0 0 0];
D = [0];

% Obtener función de transferencia
[num, den] = ss2tf(A, B, C, D);

% Asegurar formato correcto
num = num(1,:);
num = [zeros(1, length(den)-length(num)) num];  % igualar longitud
den = den(:)';

funcion = tf(num, den);

% Mostrar automáticamente en consola
disp('Función de Transferencia:')
funcion 

% F.C.C por polinomios

% Matriz de controlabilidad
S = [B A*B (A^2)*B (A^3)*B];
dS = det(S);

Ac_poly = [0 1 0 0;
           0 0 1 0;
           0 0 0 1;
          -den(5) -den(4) -den(3) -den(2)];

Bc_poly = [0; 0; 0; 1];

Cc_poly = [num(5)-(den(5)*num(1))  num(4)-(den(4)*num(1)) ...
           num(3)-(den(3)*num(1))  num(2)-(den(2)*num(1))];

% FCC desde matrices A, B, C

if rank(S) == size(A,1)
    disp('El sistema es controlable.')
else
    error('El sistema NO es controlable.')
end

% Cálculo de T y su inversa
SS = S;         % Matriz de transformación de controlabilidad
S_inv = inv(S);

% Transformación de A, B, C a la FCC
Ac_mat = S_inv*A*S;
Bc_mat = S_inv*B;
Cc_mat = C*S;

% Mostrar resultados

disp('--- Forma Canónica Controlable desde polinomios:')
disp('Ac (polinomios):'); disp(Ac_poly)
disp('Bc (polinomios):'); disp(Bc_poly)
disp('Cc (polinomios):'); disp(Cc_poly)

disp('--- Forma Canónica Controlable desde A, B, C:')
disp('Ac (matricial):'); disp(Ac_mat)
disp('Bc (matricial):'); disp(Bc_mat)
disp('Cc (matricial):'); disp(Cc_mat)


% Mostrar resultados

disp('--- Forma Canónica Controlable desde polinomios:')
disp('Ac (polinomios):'); disp(Ac_poly)
disp('Bc (polinomios):'); disp(Bc_poly)
disp('Cc (polinomios):'); disp(Cc_poly)

disp('--- Forma Canónica Controlable desde A, B, C:')
disp('Ac (matricial):'); disp(Ac_mat)
disp('Bc (matricial):'); disp(Bc_mat)
disp('Cc (matricial):'); disp(Cc_mat)
% F.C.O

% Matriz de observabilidad
O = [C; C*A; C*A^2; C*A^3];
dO = det(O);

Ao_poly = [0 0 0 -den(5);
           1 0 0 -den(4);
           0 1 0 -den(3);
           0 0 1 -den(2)];

Bo_poly = [num(5)-(den(5)*num(1));
           num(4)-(den(4)*num(1));
           num(3)-(den(3)*num(1));
           num(2)-(den(2)*num(1))];

Co_poly = [0 0 0 1];

% FCO desde matrices A, B, C

if rank(O) == size(A,1)
    disp('El sistema es observable.')
else
    error('El sistema NO es observable.')
end

% Matriz de transformación de observabilidad
T_obs = inv(O);

% Transformación de A, B, C a la FCO
Ao_mat = T_obs*A*O;
Bo_mat = T_obs*B;
Co_mat = C*O;

% Mostrar resultados FCO

disp('--- Forma Canónica Observable desde polinomios:')
disp('Ao (polinomios):'); disp(Ao_poly)
disp('Bo (polinomios):'); disp(Bo_poly)
disp('Co (polinomios):'); disp(Co_poly)

disp('--- Forma Canónica Observable desde A, B, C:')
disp('Ao (matricial):'); disp(Ao_mat)
disp('Bo (matricial):'); disp(Bo_mat)
disp('Co (matricial):'); disp(Co_mat)
%% Asignacion de polos

Ap = Ac_poly;
Bp = Bc_poly;
Cp = Cc_poly;
Dp = D;

[n, Columnas] = size(Ap);

k = sym('k', [1 n]);

syms s ki

AA = [Ap - Bp*k, Bp*ki;
      -Cp,       0];

Matriz = s*eye(n+1) - AA;

pol = expand(det(Matriz));

pol_ordenado = collect(pol, s);

% Obtiene los coeficientes y los términos base (potencias de s)
[coef_1, potencias] = coeffs(pol_ordenado, s);



pol_d = vpa(expand((s^2 + 2*z*wnd*s + wnd^2) * (s + 10*z*wnd)^3));
pol_d = collect(pol_d, s);

coef_2 = fliplr(coeffs(pol_d, s));

ecuaciones = coef_2 == coef_1;

sol = solve(ecuaciones, [k, ki]);

k_valores = arrayfun(@(i) double(sol.(sprintf('k%d', i))), 1:length(k));

sol_ki = double(sol.ki);

sol_vector = double(k_valores);

%% Matriz de transformacion
emp = [0;0;0;0];
Aemp = [A emp;-C 0];
Bemp = [B ;0];
Semp = [Bemp Aemp*Bemp Aemp^2*Bemp Aemp^3*Bemp Aemp^4*Bemp];
SIAemp = SI-Aemp;
dSIAemp = det(SIAemp);
[CoefEmp, terminos] = coeffs(dSIAemp, s, 'All');
coeficientes_ordenados = fliplr(CoefEmp);
coeficientes_decimales = vpa(coeficientes_ordenados, 4);

M = [den(2) den(3) den(4) 1;den(3) den(4) 1 0;den(4) 1 0 0; 1 0 0 0];
T = [S*M];

%% Método de Ackermann

I = eye(5);

RoAemp = Aemp^4 + Aemp^3*alfa1 + Aemp^2*alfa2 + Aemp*alfa3 + I*alfa4;

K_ack = [0 0 0 0 1] * inv(Semp) * RoAemp;

%% Observador por asignación de polos

syms s l1 l2 l3 l4

SI1 = eye(4)*s;
Lgain = [l1; l2; l3; l4];
Lc = Lgain * [0 0 0 1];

ALc = A - Lc;
SIALc = SI1 - ALc;
dSIALc = det(SIALc);
dSIALc_e = expand(dSIALc);

%% Observador por matriz de transformación
RoA_fco = Ao_poly^4 + Ao_poly^3*alfa1 + Ao_poly^2*alfa2 + Ao_poly*alfa3 + eye(4)*alfa4;
L_fco = RoA_fco * inv(O) * [0; 0; 0; 1];

Q = inv(M * O);
L_trans = Q \ L_fco;

disp('--- Observador por matriz de transformada ---')
disp('L_fco (ganancia en FCO):'); disp(L_fco)
disp('L_trans (ganancia en base original):'); disp(vpa(L_trans,4))

%% Observador por Ackermann

I1 = eye(4);
RoA = A^4 + A^3*alfa1 + A^2*alfa2 + A*alfa3 + I1*alfa4;

Lo = RoA * inv(O) * [0; 0; 0; 1];

%% Observador por Asigancion de polos
Lo = sym('L', [1 n]);
Lo = Lo.';

% Corrección de matriz escalar simbólica
Matriz_o = s*eye(n) - (Ap - Lo*Cp);

% Cálculo del polinomio del observador
pol_obs = expand(det(Matriz_o));
pol_obs_ordenado = collect(pol_obs, s);

% Obtiene los coeficientes y los términos base
[coef_1o, potencias_o] = coeffs(pol_obs_ordenado, s);

% Parámetros de diseño del observador
tso = ts / 10;
z = 0.9;                         % Asegurado que 'z' esté definido
wno = 4 / (z * tso);

% Corrección de expresión polinómica deseada
pol_d_o = vpa(expand((s^2 + 2*z*wno*s + wno^2) * (s + 10*z*wno)^2));
pol_d_o = collect(pol_d_o, s);

% Coeficientes del polinomio deseado
coef_2o = fliplr(coeffs(pol_d_o, s));

% Ecuaciones de igualdad de coeficientes
ecuaciones = coef_2o == coef_1o;

% Resolución simbólica
sol_o = solve(ecuaciones, Lo);

% Extracción de resultados
l_valores = arrayfun(@(i) double(sol_o.(sprintf('L%d', i))), 1:length(Lo));
sol_vector_o = double(l_valores);