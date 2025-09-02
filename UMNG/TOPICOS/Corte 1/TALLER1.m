
% Tópicos Taller 1

clc; clear; close all;

syms s;

num = 1;
den = s^2 + 2*s + 48;

ft = num / den;

disp('La función de transferencia es:')
pretty(ft)