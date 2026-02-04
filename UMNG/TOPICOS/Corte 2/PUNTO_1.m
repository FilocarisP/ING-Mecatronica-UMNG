syms s

j1 = 10; %kg*m2
r1 = 0.5; %m
j2 = 20; %kg*m2
r2 = 0.3; %m
j3 = 30; %kg*m2
r3 = 0.2; %m
M = 5; %Kg
B = 100; %N*s/m
k1 = 20; %N*m/rad
k2 = 10; %N*m/rad

A = [0 1 0 0;
    -(k2*r1^2 +k1)/(j1+M*r1^2) -(B*r1^2)/(j1+M*r1^2) (k1*r3/r2)/(j1+M*r1^2) 0;
    0 0 0 1;
    (k1*r3/r2)/(j3+j2*(r3^2)/(r2^2)) 0 -(k2+ k1*(r3^2)/(r2^2))/(j3+j2*(r3^2)/(r2^2)) 0];

B = [0;
    r1/(j1+M*r1^2);
    0;
    0];

C = [0 0 1 0];

D = 0;

[num, den] = ss2tf(A, B, C, D);

funcion1 = tf(num,den);

polos = pole(funcion1);

denominador_r = vpa(expand( (s-polos(3))*(s-polos(4)) ));

funcion_r = tf(9.172e-3,[1 0.244867 0.340121889]);
%%

T = 40/20;

fz = c2d(funcion_r, T, 'tustin')


%%

zd = 0.784 + 0.1357i;

Ang = (0.005787*zd^2 +0.01157*zd +0.005787)/((zd^2 -0.8327*zd +0.691)*(zd-1))

PolK = ((0.005787*zd^2 +0.01157*zd +0.005787)/((zd^2 -0.8327*zd +0.691)*(zd-1)))*((zd-0.7153)/(zd-0.8858))


%%

T2 = 10/2;

fz2 = c2d(funcion_r, T2, 'zoh')

[numz2, denz2] = tfdata(fz2, 'v');

Beta1 = numz2(2);

Beta2 = numz2(3);

alpha1 = denz2(2);

alpha2 = denz2(3);

q0 = 1/(Beta1 + Beta2)

q1 = q0*alpha1

q2 = q0*alpha2

p1 = q0*Beta1

p2 = q0*Beta2
