funcion = tf(150.8,[0.9932 17.69 150.8]);

[num, den] = tfdata(funcion, 'v')

wna = sqrt(den(3));

za = den(2)/(2*wna);

tsa = 4/(wna*za)

%%
tsd = 0.03;

T = tsd/2;

fz2 = c2d(funcion, T, 'zoh');

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