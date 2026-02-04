%% SIMU_GUI.m
% Simulador brazo 5GDL con STL + Sliders
% Autor: ChatGPT
% Fecha: 2025-08-10

function SIMU_GUI()
    close all; clc;

    % --- CONFIGURAR RUTA DE LOS STL ---
    rutaSTL = 'C:\Users\pinzo\Documents\UMNG\LAB ROBOTICA\STL\';

    % --- CARGAR MALLAS STL ---
BaseMesh    = stlread(fullfile(rutaSTL, 'Base.STL'));
WaistMesh   = stlread(fullfile(rutaSTL, 'Cintura.STL'));
Arm1Mesh    = stlread(fullfile(rutaSTL, 'Brazo1.STL'));
Arm2Mesh    = stlread(fullfile(rutaSTL, 'Brazo2.STL'));
Arm3Mesh    = stlread(fullfile(rutaSTL, 'Brazo3.STL'));
GripperMesh = stlread(fullfile(rutaSTL, 'Pinza.STL'));


    % --- DEFINIR BRAZO EN DH (EJEMPLO: ajustar a tu diseño real) ---
    L(1) = Link('d', 100, 'a', 0,    'alpha', pi/2, 'qlim', deg2rad([-170 170]));
    L(2) = Link('d', 0,   'a', 200,  'alpha', 0,    'qlim', deg2rad([-90 90]));
    L(3) = Link('d', 0,   'a', 150,  'alpha', 0,    'qlim', deg2rad([-90 90]));
    L(4) = Link('d', 0,   'a', 50,   'alpha', pi/2, 'qlim', deg2rad([-90 90]));
    L(5) = Link('d', 50,  'a', 0,    'alpha', 0,    'qlim', deg2rad([-180 180]));

    robot = SerialLink(L, 'name', 'Brazo_5GDL');

    % --- CONFIGURAR INTERFAZ ---
    fig = figure('Name', 'Simulador Brazo 5GDL', 'Position', [100 100 900 600]);
    ax = axes('Parent', fig, 'Position', [0.05 0.3 0.6 0.65]);
    axis(ax, 'equal');
    grid(ax, 'on');
    view(ax, 3);

    % --- VALORES INICIALES ---
    q = zeros(1, 5);

    % --- SLIDERS ---
    for i = 1:5
        uicontrol('Style', 'text', 'String', sprintf('Joint %d', i), ...
            'Units', 'normalized', 'Position', [0.7 0.8-(i-1)*0.12 0.1 0.05]);

        uicontrol('Style', 'slider', ...
            'Min', robot.links(i).qlim(1), ...
            'Max', robot.links(i).qlim(2), ...
            'Value', q(i), ...
            'Units', 'normalized', ...
            'Position', [0.8 0.8-(i-1)*0.12 0.15 0.05], ...
            'Callback', @(src, ~) moverEje(i, src.Value));
    end

    % --- FUNCION MOVER ---
    function moverEje(idx, val)
        q(idx) = val;
        dibujarBrazo(q, BaseMesh, WaistMesh, Arm1Mesh, Arm2Mesh, Arm3Mesh, GripperMesh, robot, ax);
    end

    % --- PRIMER DIBUJO ---
    dibujarBrazo(q, BaseMesh, WaistMesh, Arm1Mesh, Arm2Mesh, Arm3Mesh, GripperMesh, robot, ax);
end

%% FUNCION PARA DIBUJAR EL BRAZO CON STL
function dibujarBrazo(q, BaseMesh, WaistMesh, Arm1Mesh, Arm2Mesh, Arm3Mesh, GripperMesh, robot, ax)
    cla(ax);

    % Transformaciones usando robot.A(i, q)
    T0 = eye(4);
    T1 = robot.A(1, q);
    T2 = robot.A(2, q);
    T3 = robot.A(3, q);
    T4 = robot.A(4, q);
    T5 = robot.A(5, q);

    % --- Base ---
    patch(ax, 'Faces', BaseMesh.ConnectivityList, 'Vertices', BaseMesh.Points, ...
        'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none');

    % --- Waist ---
    plotSTL(ax, WaistMesh, T1, [0.9 0.5 0.3]);

    % --- Arm1 ---
    plotSTL(ax, Arm1Mesh, T2, [0.2 0.6 0.8]);

    % --- Arm2 ---
    plotSTL(ax, Arm2Mesh, T3, [0.3 0.8 0.3]);

    % --- Arm3 ---
    plotSTL(ax, Arm3Mesh, T4, [0.9 0.9 0.2]);

    % --- Gripper ---
    plotSTL(ax, GripperMesh, T5, [0.8 0.2 0.2]);

    camlight(ax);
end

%% FUNCION PARA PLOTEAR STL TRANSFORMADO
function plotSTL(ax, meshData, T, color)
    vertices = (meshData.Points * T(1:3,1:3)') + T(1:3,4)';
    patch(ax, 'Faces', meshData.ConnectivityList, 'Vertices', vertices, ...
        'FaceColor', color, 'EdgeColor', 'none');
end
