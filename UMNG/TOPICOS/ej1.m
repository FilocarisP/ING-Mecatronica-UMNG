syms t tp x xp f f2 tpp
m=1
M=5
g=9.81
l=0.5
k=100
xpp=(f+m*l*sin(t)*tp^2-m*l*cos(t)*tpp-k*x)/(M+m)
tpp=(-f2*l*sin(t)-m*l*cos(t)*xpp-m*g*l*sin(t))/(m*l^2)
po=tpp
syms tpp
tpp=solve(po-tpp,tpp)
xpp=eval(xpp)
xp=xp
tp=tp
y1=x
y2=t
A=jacobian([xp xpp tp tpp],[x xp t tp])
B=jacobian([xp xpp tp tpp],[f f2])
C=jacobian([y1 y2],[x xp t tp])
D=jacobian([y1 y2],[f f2])
tp=0
A=eval(A)
C=double(C)
c1=C(1,:)
c2=C(2,:)
E=[c1*A*B; c2*A*B]
G=inv(E)
P=[c1*A^2; c2*A^2]
F=G*P
F =[                          (7500*cos(t)^2)/(75*cos(t)^2 - 450) - (2500*cos(t)^2)/(25*cos(t)^2 - 150) - 100, 0,                   (cos(t)*((2943*cos(t) + 300*f2*cos(t) - 50*f*sin(t) + 5000*x*sin(t))/(25*cos(t)^2 - 150) + (50*cos(t)*sin(t)*(2943*sin(t) + 50*f*cos(t) + 300*f2*sin(t) - 5000*x*cos(t)))/(25*cos(t)^2 - 150)^2))/2 - (6*cos(t)*(2943*cos(t) + 300*f2*cos(t) - 50*f*sin(t) + 5000*x*sin(t)))/(300*cos(t)^2 - 1800) + (6*sin(t)*(2943*sin(t) + 50*f*cos(t) + 300*f2*sin(t) - 5000*x*cos(t)))/(300*cos(t)^2 - 1800) - (25*cos(t)^2*sin(t)*(2943*sin(t) + 50*f*cos(t) + 300*f2*sin(t) - 5000*x*cos(t)))/(25*cos(t)^2 - 150)^2, 0;(2500*cos(t))/(sin(t)*(25*cos(t)^2 - 150)) - (cos(t)*((1250*cos(t)^2)/(75*cos(t)^2 - 450) - 50/3))/sin(t), 0, (cos(t)*((cos(t)*(2943*cos(t) + 300*f2*cos(t) - 50*f*sin(t) + 5000*x*sin(t)))/(300*cos(t)^2 - 1800) - (sin(t)*(2943*sin(t) + 50*f*cos(t) + 300*f2*sin(t) - 5000*x*cos(t)))/(300*cos(t)^2 - 1800) + (25*cos(t)^2*sin(t)*(2943*sin(t) + 50*f*cos(t) + 300*f2*sin(t) - 5000*x*cos(t)))/(6*(25*cos(t)^2 - 150)^2)))/sin(t) - ((2943*cos(t) + 300*f2*cos(t) - 50*f*sin(t) + 5000*x*sin(t))/(25*cos(t)^2 - 150) + (50*cos(t)*sin(t)*(2943*sin(t) + 50*f*cos(t) + 300*f2*sin(t) - 5000*x*cos(t)))/(25*cos(t)^2 - 150)^2)/(2*sin(t)), 0]
 