clc;clear;close all;
%% 1. Cargar el Modelo del Robot
% Asegúrate de que el archivo 'cylindrical_robot.urdf' esté en el mismo directorio.
try
    robot = importrobot('cylindrical_robot.urdf');
    disp('Modelo URDF cargado exitosamente.');
catch ME
    disp(['Error al cargar el URDF: ', ME.message]);
    return; % Detener la ejecución si falla la carga
end

%% 2. Configurar Propiedades de Visualización

initial_config = [pi/4, 0.1, 0.2]; 
config = homeConfiguration(robot);

% Asignar la configuración inicial a los joints, asegurando el orden correcto
joint_names = {'joint1_rotation', 'joint2_vertical', 'joint3_reach'};
for i = 1:length(joint_names)
    joint_index = find(strcmp({config.JointName}, joint_names{i}));
    if ~isempty(joint_index)
        config(joint_index).JointPosition = initial_config(i);
    end
end

%% 3. Visualización 
figure('Name', 'Robot Cilíndrico R-P-P', 'NumberTitle', 'off'); % Puedes poner el nombre aquí en la figura
show(robot, config, 'Visuals', 'on');
title('Robot Cilíndrico R-P-P');
view(3); % Vista 3D
axis equal; 
grid on;
xlabel('X (m)');
ylabel('Y (m)');
zlabel('Z (m)');

% Limites del eje para una mejor visualización del cilindro de trabajo
xlim([-0.6 0.6]);
ylim([-0.6 0.6]);
zlim([0 0.8]);

%% 4. Interacción (GUI)
% Esto te permite mover las articulaciones manualmente con sliders.
disp('Abriendo la interfaz gráfica interactiva...');
gui = interactiveRigidBodyTree(robot);