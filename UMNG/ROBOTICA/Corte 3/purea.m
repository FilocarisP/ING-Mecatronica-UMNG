clear; clc; close all;

% --- 1. DEFINICIÓN DE PARÁMETROS NUMÉRICOS ---
L5_val = [10, 0, 10, 10]; 
L_val  = [0, 5]; 

% --- 2. DEFINICIÓN DEL ROBOT (Toolbox) ---
% Se usan los valores numéricos para la visualización del robot
R5(1) = Link('revolute',  'd', L5_val(1), 'a', 0, 'alpha', 0, 'offset', pi);
R5(2) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', pi/2, 'offset', L_val(2), 'qlim', [0 25]);
R5(3) = Link('revolute',  'd', 0, 'a', 0, 'alpha', pi/2, 'offset', pi/2);
R5(4) = Link('revolute',  'd', L5_val(4)+L5_val(3), 'a', 0, 'alpha', 0, 'offset', 0);
R5(5) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', -pi/2, 'offset', L_val(2), 'qlim', [0 25]);

Rob5r = SerialLink(R5, 'name', 'PARIN');

% --- 3. CÁLCULO SIMBÓLICO (MODIFICADO) ---
% Definimos las variables articulares y las longitudes simbólicas
syms q1 q2 q3 q4 q5 real 
syms l1 l2 l3 l4 l5 real % Longitudes simbólicas solicitadas

% Definimos los vectores de longitudes usando los símbolos
% Mapeo: L5(1)->l1, L(2)->l2, L5(3)->l3, L5(4)->l4
L5_sym = [l1, 0, l3, l4]; 
L_sym  = [0, l2];

% --- VISUALIZACIÓN PARA LIVE SCRIPT ---
disp('--- Matriz de Transformación Homogénea (MTH) Simbólica ---'); %[output:77109da1]
% Calculamos la Cinemática Directa con símbolos
MTH = simplify(Parin_fkin([q1 q2 q3 q4 q5], L5_sym, L_sym))  %[output:24c17026]

PosVector = simplify(MTH(1:3,4)); 

disp('--- Jacobiano Simbólico (J_sym) ---'); %[output:52d273c0]
% Jacobiano Analítico
J_sym = jacobian(PosVector, [q1 q2 q3 q4 q5]) %[output:28d05ef2]

% --- 4. CONFIGURACIÓN INICIAL ---
qin = [0, 5, 0, 0, 5]'; 

Rob5r.plot(qin'); %[output:9fc315c8]
hold on %[output:9fc315c8]
view(3);  %[output:9fc315c8]

step = 1; 

% Preparamos vectores para sustitución rápida en el bucle
% Debemos sustituir q y TAMBIÉN las longitudes l por sus valores numéricos
vars_to_sub = [q1 q2 q3 q4 q5 l1 l2 l3 l4];
vals_lengths = [L5_val(1), L_val(2), L5_val(3), L5_val(4)]; % Valores de l1, l2, l3, l4

% --- 5. BUCLES DE MOVIMIENTO ---

% Lado 1: Movimiento en X positivo
fprintf('Moviendo X+ ...\n'); %[output:419ccdab]
for i=1:1:20 %[output:group:3e00eaec]
    V = [step; 0; 0]; 
    
    % Sustituimos q_actual Y las longitudes l_actuales
    vals_current = [qin', vals_lengths];
    J_num = eval(subs(J_sym, vars_to_sub, vals_current)); %[output:7c854def] %[output:67be8943] %[output:913439b9] %[output:517578aa] %[output:1fff4db2] %[output:4a4ac5be] %[output:596497c6] %[output:7a7009cb] %[output:43ea8fda] %[output:9e1e6f74] %[output:62387975] %[output:5dfa7de6] %[output:942e047f] %[output:42ea5af8] %[output:6aceeb52] %[output:74296c45] %[output:23682fc8] %[output:81ac1011] %[output:02830de3] %[output:79baaf11]
    
    Thetadot = pinv(J_num) * V; 
    qin = qin + Thetadot;
    
    Rob5r.animate(qin');  %[output:9fc315c8]
    % Para la MTH numérica también sustituimos las longitudes
    MTH_num = double(subs(MTH, vars_to_sub, vals_current)); 
    plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');
    drawnow;
end %[output:group:3e00eaec]

% Lado 2: Movimiento en Y positivo
fprintf('Moviendo Y+ ...\n'); %[output:9bd92c0c]
for i=1:1:20 %[output:group:53d47d70]
    V = [0; step; 0];
    vals_current = [qin', vals_lengths];
    J_num = eval(subs(J_sym, vars_to_sub, vals_current)); %[output:4e76a4eb] %[output:75bae5f7] %[output:73e956af] %[output:85515d36] %[output:299f9739] %[output:38a0402d] %[output:62624e85] %[output:04c54271] %[output:1b1aecab] %[output:8fbd9c2e] %[output:2d36358c] %[output:7d704f49] %[output:23350fc0] %[output:0f86f9c8] %[output:06cf4641] %[output:1fa314dd] %[output:8b9c8bd9] %[output:6d5c1784] %[output:5f5e596a] %[output:753b06e7]
    
    Thetadot = pinv(J_num) * V;
    qin = qin + Thetadot;
    
    Rob5r.animate(qin'); %[output:9fc315c8]
    MTH_num = double(subs(MTH, vars_to_sub, vals_current));
    plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');
    drawnow;
end %[output:group:53d47d70]

% Lado 3: Movimiento en X negativo
fprintf('Moviendo X- ...\n'); %[output:1c16aa03]
for i=1:1:20 %[output:group:2eed0500]
    V = [-step; 0; 0];
    vals_current = [qin', vals_lengths];
    J_num = eval(subs(J_sym, vars_to_sub, vals_current)); %[output:1be37616] %[output:02702af7] %[output:9f594dd3] %[output:28552c5d] %[output:7266a18a] %[output:0ad4ee40] %[output:69360d44] %[output:9c709483] %[output:043edbe7] %[output:0ebf9f09] %[output:8749915f] %[output:647a5c0d] %[output:289c7995] %[output:6c22858c] %[output:8dd4edc3] %[output:7484673f] %[output:88c236b2] %[output:146c35de] %[output:0069fe9e] %[output:6c086317]
    
    Thetadot = pinv(J_num) * V;
    qin = qin + Thetadot;
    
    Rob5r.animate(qin'); %[output:9fc315c8]
    MTH_num = double(subs(MTH, vars_to_sub, vals_current));
    plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');
    drawnow;
end %[output:group:2eed0500]

% Lado 4: Movimiento en Y negativo
fprintf('Moviendo Y- ...\n'); %[output:9fa64702]
for i=1:1:20 %[output:group:294e796e]
    V = [0; -step; 0];
    vals_current = [qin', vals_lengths];
    J_num = eval(subs(J_sym, vars_to_sub, vals_current)); %[output:7d57ddb1] %[output:10f968fd] %[output:5d5cb258] %[output:3ceefd0b] %[output:1b9d1591] %[output:91781ecb] %[output:68a71cbc] %[output:3bce7fb2] %[output:2ab5db82] %[output:6dfacfc0] %[output:89f41484] %[output:9265a3d0] %[output:740b85c0] %[output:69b30430] %[output:7970ddb8] %[output:20cacc1f] %[output:82cda889] %[output:99f5d11a] %[output:3628df76] %[output:9fd49113]
    
    Thetadot = pinv(J_num) * V;
    qin = qin + Thetadot;
    
    Rob5r.animate(qin'); %[output:9fc315c8]
    MTH_num = double(subs(MTH, vars_to_sub, vals_current));
    plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');
    drawnow;
end %[output:group:294e796e]

disp('Trayectoria finalizada.'); %[output:5a88bca3]


% --- FUNCIONES AUXILIARES ---

function MTH = Parin_fkin(q, L5, L)
    % Link 1 (Revolute): d=L5(1) -> l1
    T1 = MiDH(q(1) + pi, L5(1), 0, 0);
    
    % Link 2 (Prismatic): offset=L(2) -> l2
    T2 = MiDH(-pi/2, q(2) + L(2), 0, pi/2);
    
    % Link 3 (Revolute)
    T3 = MiDH(q(3) + pi/2, 0, 0, pi/2);
    
    % Link 4 (Revolute): d=L5(4)+L5(3) -> l4 + l3
    T4 = MiDH(q(4), L5(4)+L5(3), 0, 0);
    
    % Link 5 (Prismatic): offset=L(2) -> l2
    T5 = MiDH(-pi/2, q(5) + L(2), 0, -pi/2);
    
    MTH = T1 * T2 * T3 * T4 * T5;
end

function T = MiDH(theta, d, a, alpha)
    T = [cos(theta) -sin(theta)*cos(alpha) sin(theta)*sin(alpha) a*cos(theta);
         sin(theta) cos(theta)*cos(alpha) -cos(theta)*sin(alpha) a*sin(theta);
         0           sin(alpha)             cos(alpha)            d;
         0           0                      0                     1];
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
%[output:77109da1]
%   data: {"dataType":"text","outputData":{"text":"--- Matriz de Transformación Homogénea (MTH) Simbólica ---\n","truncated":false}}
%---
%[output:24c17026]
%   data: {"dataType":"symbolic","outputData":{"name":"MTH","value":"\\begin{array}{l}\n\\left(\\begin{array}{cccc}\n\\sigma_2 -\\cos \\left(q_1 \\right)\\,\\cos \\left(q_4 \\right)+\\sigma_7 -\\sigma_5 +\\frac{1202453802380202612679414065556140558016349465041059773802132977407586929771258562750827143105108370416113433767\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{1202453802380202612679414065556140558016349465041059773802132977424491020858679523053413887173001575952350707712}-\\frac{24678615572571482867467662723121\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)}{3291009114642412084309938365114701009965471731267159726697218048}-\\frac{32697871082009813622455219990351321198931191876828657536391216476239934877805225\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}-\\frac{907548233286809381061144841050561982124555756491312436638528097\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}+\\frac{32697871082009813622455219990351566393691329179223172964110046442520659751916887\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}+\\frac{49357231145142964744974150469681\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}+\\frac{907548233286809381061144841050568787646261303381729908994461087\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808} & \\sigma_{14} -\\frac{4967757600021511\\,\\cos \\left(q_1 \\right)}{81129638414606681695789005144064}+\\sigma_{11} +\\frac{684969180613545\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_4 \\right)}{182687704666362864775460604089535377456991567872}+\\frac{4967757600021511\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{81129638414606681695789005144064}+\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)+\\sigma_2 -\\frac{3402760852773445208736177966495\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}-\\frac{684969180613545\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{182687704666362864775460604089535377456991567872}-\\sigma_5 -\\frac{4508479633296642371710296140142213886022127883437326811314322031477946811794265\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{1202453802380202612679414065556140558016349465041059773802132977424491020858679523053413887173001575952350707712}-\\frac{4508479633296642552564030905425727557646164644730948009963451028509818577894567\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)}{1202453802380202612679414065556140558016349465041059773802132977424491020858679523053413887173001575952350707712}+\\frac{245194760137302389597540568113930496276353307991\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}+\\frac{4508479633296642552564030905425761365828339486651553183451586814920891052442457\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_3 \\right)}{1202453802380202612679414065556140558016349465041059773802132977424491020858679523053413887173001575952350707712}+\\frac{3402760852773445208736177966495\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)}{7410693711188236507108543040556026102609279018600996098525285376506440296955904}+\\frac{4917887150716035784448520803671\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}+\\frac{125135447373487877846921248620896337456935971797256815309326959\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)}{33374797436264220037422214158899251790667258161822699530422525122222183215322508594108782608384}+\\frac{165797903613180019966627968433924354966172962609825788835091898474378312181266875504776190413277127806535773449\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{2707685248164858261307045101702230179137145581421695874189921465443966120903931272499975005961073806735733604454495675614232576} & \\sigma_{15} -\\frac{122597380068651197257713859414983140362437055831\\,\\sin \\left(q_1 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}-\\frac{24678615572571482867467662723121\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}+\\sigma_{10} -\\frac{24678615572571482867467662723121\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}-\\sigma_8 +\\cos \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)-\\frac{24678615572571482867467662723121\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}+\\frac{3402760852773445208736177966495\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}-\\sigma_1 -\\frac{907548233286809381061144841050568787646261303381729908994461087\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}-\\frac{32697871082009813622455219990351321198931191876828657536391216476239934877805225\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}+\\frac{24678615572571482867467662723121\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{3291009114642412084309938365114701009965471731267159726697218048}+\\frac{32697871082009813622455219990351566393691329179223172964110046442520659751916887\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_3 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}+\\frac{49357231145142964744974150469681\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}+\\frac{907548233286809381061144841050561982124555756491312436638528097\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}+\\frac{1202453802380202612679414065556140558016349465041059773802132977407586929771258562750827143105108370416113433767\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{1202453802380202612679414065556140558016349465041059773802132977424491020858679523053413887173001575952350707712} & -\\sigma_3 \\,{\\left(24678615572571482867467662723121\\,\\sin \\left(q_1 \\right)-403032377821159473656973322630821148176053960704\\,\\cos \\left(q_1 \\right)+403032377821159473656973322630821148176053960704\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)+403032377821159473656973322630821148176053960704\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)+6582018229284824168619876730229402019930943462534319453394436096\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)-24678615572571481877506487746560\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\right)}\\\\\n\\sigma_6 -\\sigma_{10} -\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)+\\sigma_1 +\\frac{32697871082009813622455219990351566393691329179223172964110046442520659751916887\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}+\\frac{907548233286809381061144841050561982124555756491312436638528097\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}-\\frac{49357231145142964744974150469681\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}-\\frac{907548233286809381061144841050568787646261303381729908994461087\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_3 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}-\\frac{24678615572571482867467662723121\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)}{3291009114642412084309938365114701009965471731267159726697218048}-\\frac{1202453802380202612679414065556140558016349465041059773802132977407586929771258562750827143105108370416113433767\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{1202453802380202612679414065556140558016349465041059773802132977424491020858679523053413887173001575952350707712}-\\frac{32697871082009813622455219990351321198931191876828657536391216476239934877805225\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144} & \\frac{3402760852773445208736177966495\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_4 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}-\\frac{4967757600021511\\,\\sin \\left(q_1 \\right)}{81129638414606681695789005144064}-\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)-\\sigma_{15} +\\frac{684969180613545\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{182687704666362864775460604089535377456991567872}+\\sigma_8 +\\sigma_6 +\\frac{684969180613545\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)}{182687704666362864775460604089535377456991567872}+\\frac{4967757600021511\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{81129638414606681695789005144064}+\\sigma_1 +\\frac{4917887150716035784448520803671\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}-\\frac{3402760852773445208736177966495\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)}{7410693711188236507108543040556026102609279018600996098525285376506440296955904}-\\frac{125135447373487877846921248620896337456935971797256815309326959\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{33374797436264220037422214158899251790667258161822699530422525122222183215322508594108782608384}-\\frac{165797903613180019966627968433924354966172962609825788835091898474378312181266875504776190413277127806535773449\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_3 \\right)}{2707685248164858261307045101702230179137145581421695874189921465443966120903931272499975005961073806735733604454495675614232576}-\\frac{4508479633296642552564030905425727557646164644730948009963451028509818577894567\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)}{1202453802380202612679414065556140558016349465041059773802132977424491020858679523053413887173001575952350707712}+\\frac{4508479633296642371710296140142213886022127883437326811314322031477946811794265\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{1202453802380202612679414065556140558016349465041059773802132977424491020858679523053413887173001575952350707712}+\\frac{245194760137302389597540568113930496276353307991\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}+\\frac{4508479633296642552564030905425761365828339486651553183451586814920891052442457\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{1202453802380202612679414065556140558016349465041059773802132977424491020858679523053413887173001575952350707712} & \\frac{122597380068651197257713859414983140362437055831\\,\\cos \\left(q_1 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}+\\sigma_{14} +\\sigma_{11} +\\frac{24678615572571482867467662723121\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_4 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}-\\frac{3402760852773445208736177966495\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}-\\frac{24678615572571482867467662723121\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}+\\sigma_2 +\\sigma_7 -\\frac{24678615572571482867467662723121\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}+\\sin \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)-\\frac{49357231145142964744974150469681\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}-\\frac{907548233286809381061144841050561982124555756491312436638528097\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}-\\frac{1202453802380202612679414065556140558016349465041059773802132977407586929771258562750827143105108370416113433767\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_3 \\right)}{1202453802380202612679414065556140558016349465041059773802132977424491020858679523053413887173001575952350707712}-\\frac{32697871082009813622455219990351321198931191876828657536391216476239934877805225\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144}+\\frac{907548233286809381061144841050568787646261303381729908994461087\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}+\\frac{24678615572571482867467662723121\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)}{3291009114642412084309938365114701009965471731267159726697218048}+\\frac{32697871082009813622455219990351566393691329179223172964110046442520659751916887\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144} & \\sigma_3 \\,{\\left(24678615572571482867467662723121\\,\\cos \\left(q_1 \\right)+403032377821159473656973322630821148176053960704\\,\\sin \\left(q_1 \\right)+6582018229284824168619876730229402019930943462534319453394436096\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)-24678615572571481877506487746560\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)-403032377821159473656973322630821148176053960704\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)-403032377821159473656973322630821148176053960704\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\right)}\\\\\n\\sigma_{13} -\\frac{4967757600021511\\,\\cos \\left(q_4 \\right)}{81129638414606681695789005144064}+\\sigma_9 +\\cos \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)+\\frac{4967757600021511\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_3 \\right)}{81129638414606681695789005144064}-\\sigma_4  & \\frac{3402760852773445208736177966495\\,\\cos \\left(q_4 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}-\\sin \\left(q_3 \\right)+\\sigma_{13} +\\sigma_9 -\\frac{684969180613545\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{182687704666362864775460604089535377456991567872}-\\frac{3402760852773445208736177966495\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_3 \\right)}{14821387422376473014217086081112052205218558037201992197050570753012880593911808}-\\sigma_4 -\\frac{24678615572571482867467662723121}{6582018229284824168619876730229402019930943462534319453394436096} & \\frac{24678615572571482867467662723121\\,\\cos \\left(q_4 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}+\\frac{4967757600021511\\,\\sin \\left(q_3 \\right)}{81129638414606681695789005144064}+\\frac{4967757600021511\\,\\sin \\left(q_4 \\right)}{81129638414606681695789005144064}+\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)-\\frac{4967757600021511\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{81129638414606681695789005144064}-\\frac{24678615572571482867467662723121\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_3 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}-\\frac{4967757600021511\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{81129638414606681695789005144064}+\\frac{122597380068651197257713859414983140362437055831}{533996758980227520598755426542388028650676130589163192486760401955554931445160137505740521734144} & l_1 +l_2 +q_2 +{\\left(l_3 +l_4 \\right)}\\,\\sigma_{12} +{\\left(l_2 +q_5 \\right)}\\,\\sigma_{12} \\\\\n0 & 0 & 0 & 1\n\\end{array}\\right)\\\\\n\\mathrm{}\\\\\n\\textrm{where}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_1 =\\frac{4967757600021511\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)}{81129638414606681695789005144064}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_2 =\\frac{4967757600021511\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)}{81129638414606681695789005144064}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_3 =\\frac{l_2 }{6582018229284824168619876730229402019930943462534319453394436096}+\\frac{l_3 }{6582018229284824168619876730229402019930943462534319453394436096}+\\frac{l_4 }{6582018229284824168619876730229402019930943462534319453394436096}+\\frac{q_5 }{6582018229284824168619876730229402019930943462534319453394436096}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_4 =\\frac{24678615572571482867467662723121\\,\\sin \\left(q_3 \\right)\\,\\sin \\left(q_4 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_5 =\\frac{24678615572571482867467662723121\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_6 =\\frac{24678615572571482867467662723121\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_4 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_7 =\\frac{4967757600021511\\,\\cos \\left(q_4 \\right)\\,\\sin \\left(q_1 \\right)}{81129638414606681695789005144064}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_8 =\\frac{4967757600021511\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)}{81129638414606681695789005144064}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_9 =\\frac{4967757600021511\\,\\cos \\left(q_3 \\right)\\,\\cos \\left(q_4 \\right)}{81129638414606681695789005144064}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_{10} =\\frac{4967757600021511\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_4 \\right)}{81129638414606681695789005144064}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_{11} =\\frac{4967757600021511\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)}{81129638414606681695789005144064}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_{12} =\\sin \\left(q_3 \\right)+\\frac{24678615572571482867467662723121}{6582018229284824168619876730229402019930943462534319453394436096}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_{13} =\\frac{24678615572571482867467662723121\\,\\sin \\left(q_4 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_{14} =\\frac{24678615572571482867467662723121\\,\\sin \\left(q_1 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_{15} =\\frac{24678615572571482867467662723121\\,\\cos \\left(q_1 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}\n\\end{array}"}}
%---
%[output:52d273c0]
%   data: {"dataType":"text","outputData":{"text":"--- Jacobiano Simbólico (J_sym) ---\n","truncated":false}}
%---
%[output:28d05ef2]
%   data: {"dataType":"symbolic","outputData":{"name":"J_sym","value":"\\begin{array}{l}\n\\left(\\begin{array}{ccccc}\n-\\sigma_1 \\,{\\left(24678615572571482867467662723121\\,\\cos \\left(q_1 \\right)+403032377821159473656973322630821148176053960704\\,\\sin \\left(q_1 \\right)+6582018229284824168619876730229402019930943462534319453394436096\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)-24678615572571481877506487746560\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)-\\sigma_3 -\\sigma_2 \\right)} & 0 & \\sigma_1 \\,{\\left(\\sigma_4 -\\sigma_5 +24678615572571481877506487746560\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)+6582018229284824168619876730229402019930943462534319453394436096\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\right)} & 0 & \\frac{4967757600021511\\,\\cos \\left(q_1 \\right)}{81129638414606681695789005144064}-\\frac{24678615572571482867467662723121\\,\\sin \\left(q_1 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}-\\frac{4967757600021511\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)}{81129638414606681695789005144064}-\\frac{4967757600021511\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{81129638414606681695789005144064}-\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)+\\frac{684969180613545\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{182687704666362864775460604089535377456991567872}\\\\\n-\\sigma_1 \\,{\\left(24678615572571482867467662723121\\,\\sin \\left(q_1 \\right)-403032377821159473656973322630821148176053960704\\,\\cos \\left(q_1 \\right)+\\sigma_5 +\\sigma_4 +6582018229284824168619876730229402019930943462534319453394436096\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)-24678615572571481877506487746560\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\right)} & 0 & -\\sigma_1 \\,{\\left(24678615572571481877506487746560\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)+6582018229284824168619876730229402019930943462534319453394436096\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)+\\sigma_3 -\\sigma_2 \\right)} & 0 & \\frac{24678615572571482867467662723121\\,\\cos \\left(q_1 \\right)}{6582018229284824168619876730229402019930943462534319453394436096}+\\frac{4967757600021511\\,\\sin \\left(q_1 \\right)}{81129638414606681695789005144064}+\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)-\\frac{684969180613545\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{182687704666362864775460604089535377456991567872}-\\frac{4967757600021511\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)}{81129638414606681695789005144064}-\\frac{4967757600021511\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)}{81129638414606681695789005144064}\\\\\n0 & 1 & \\cos \\left(q_3 \\right)\\,{\\left(l_3 +l_4 \\right)}+\\cos \\left(q_3 \\right)\\,{\\left(l_2 +q_5 \\right)} & 0 & \\sin \\left(q_3 \\right)+\\frac{24678615572571482867467662723121}{6582018229284824168619876730229402019930943462534319453394436096}\n\\end{array}\\right)\\\\\n\\mathrm{}\\\\\n\\textrm{where}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_1 =\\frac{l_2 }{6582018229284824168619876730229402019930943462534319453394436096}+\\frac{l_3 }{6582018229284824168619876730229402019930943462534319453394436096}+\\frac{l_4 }{6582018229284824168619876730229402019930943462534319453394436096}+\\frac{q_5 }{6582018229284824168619876730229402019930943462534319453394436096}\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_2 =403032377821159473656973322630821148176053960704\\,\\sin \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_3 =403032377821159473656973322630821148176053960704\\,\\cos \\left(q_3 \\right)\\,\\sin \\left(q_1 \\right)\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_4 =403032377821159473656973322630821148176053960704\\,\\cos \\left(q_1 \\right)\\,\\sin \\left(q_3 \\right)\\\\\n\\mathrm{}\\\\\n\\;\\;\\sigma_5 =403032377821159473656973322630821148176053960704\\,\\cos \\left(q_1 \\right)\\,\\cos \\left(q_3 \\right)\n\\end{array}"}}
%---
%[output:419ccdab]
%   data: {"dataType":"text","outputData":{"text":"Moviendo X+ ...\n","truncated":false}}
%---
%[output:7c854def]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:67be8943]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:913439b9]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:517578aa]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:1fff4db2]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:4a4ac5be]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:596497c6]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:7a7009cb]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:43ea8fda]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:9e1e6f74]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:62387975]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:5dfa7de6]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:942e047f]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:42ea5af8]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:6aceeb52]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:74296c45]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:23682fc8]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:81ac1011]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:02830de3]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:79baaf11]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:9bd92c0c]
%   data: {"dataType":"text","outputData":{"text":"Moviendo Y+ ...\n","truncated":false}}
%---
%[output:4e76a4eb]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:75bae5f7]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:73e956af]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:85515d36]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:299f9739]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:38a0402d]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:62624e85]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:04c54271]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:1b1aecab]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:8fbd9c2e]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:2d36358c]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:7d704f49]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:23350fc0]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:0f86f9c8]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:06cf4641]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:1fa314dd]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:8b9c8bd9]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:6d5c1784]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:5f5e596a]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:753b06e7]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:1c16aa03]
%   data: {"dataType":"text","outputData":{"text":"Moviendo X- ...\n","truncated":false}}
%---
%[output:1be37616]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:02702af7]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:9f594dd3]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:28552c5d]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:7266a18a]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:0ad4ee40]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:69360d44]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:9c709483]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:043edbe7]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:0ebf9f09]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:8749915f]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:647a5c0d]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:289c7995]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:6c22858c]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:8dd4edc3]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:7484673f]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:88c236b2]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:146c35de]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:0069fe9e]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:6c086317]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:9fa64702]
%   data: {"dataType":"text","outputData":{"text":"Moviendo Y- ...\n","truncated":false}}
%---
%[output:7d57ddb1]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:10f968fd]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:5d5cb258]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:3ceefd0b]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:1b9d1591]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:91781ecb]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:68a71cbc]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:3bce7fb2]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:2ab5db82]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:6dfacfc0]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:89f41484]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:9265a3d0]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:740b85c0]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:69b30430]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:7970ddb8]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:20cacc1f]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:82cda889]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:99f5d11a]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:3628df76]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:9fd49113]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The function sym\/eval is deprecated and will be removed in a future release. Depending on the usage, use subs or double instead."}}
%---
%[output:9fc315c8]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAY4AAADwCAYAAAAXW4N5AAAAAXNSR0IArs4c6QAAIABJREFUeF7tfQuUVsWV7m4augGDPBoiImADIQxjIgFMIGAUM2aSGIm5Sw0Pk9GG8aJZBhciL0kE0chTImjwiZCICDFcbhaOJhIvKJEJywQ0jmSEAC0wNISH2Eg\/eN61C+q3+vSpc6rqVJ3H\/++zVq\/u\/v86Vbu+qrO\/s2vvXVV09uzZs0AXIUAIEAKEACGgiEAREYciUlSMECAECAFCgCFAxEETgRAgBAgBQkALASIOLbioMCFACBAChAARB80BQoAQIAQIAS0EiDi04KLChAAhQAgQAkQcNAcIAUKAECAEtBAg4tCCiwoTAoQAIUAIEHHQHCAECAFCgBDQQoCIQwsuKkwIEAKEACFAxEFzgBAgBAgBQkALASIOLbioMCFACBAChAARB80BQoAQIAQIAS0EiDi04KLChAAhQAgQAkQcNAcIAUKAECAEtBAg4tCCiwoTAoQAIUAIEHHQHCAECAFCgBDQQoCIQwsuKkwIEAKEACFAxEFzgBAgBAgBQkALASIOLbioMCFACBAChAARB80BQoAQIAQIAS0EiDi04KLChAAhQAgQAkQcNAcIAUKAECAEtBAg4tCCiwoTAoQAIUAIEHHQHCAECAFCgBDQQoCIQwsuKlwICJw6dQqOHTsGrVq1gqZNmxZCl6mPhIAWAkQcWnBR4UJAoK6uDqqqquDiiy+G5s2bF0KXqY+EgBYCRBxacFHhQkAgDcRBVk8hzLTs9pGII7tjR5I7QiANxJEGGRzBS9XmAQJEHHkwiNQFuwikQWmnQQa7qFJt+YQAEUc+jSb1xQoCaVDaaZDBCphUSV4iQMSRl8NKnYqCQBqUdhpkiIIh3ZvfCBBx5Pf4Uu8MEEiD0k6DDAbQ0S0FggARR4EMNHVTHYE0KO00yKCOGJUsNASIOAptxKm\/oQikQWmnQYZQoKhAwSJAxFGwQ08dlyGQBqWdBhlohhACMgSIOGhuEAIeBNKgtNMgA00MQoCIg+ZA5hBIKns6DUo7DTJkbsKQwLEhQBZHbFBTQ7oIJKU8bbSLpIf14GaJ+LtNmzbQtm1bZQhsyKDcGBUkBDQRIOLQBIyKx4dAUsrTtF0kC24lffLJJ2xnXdwkEXfZ\/eijj9h3HTp0UNo40VSG+EaHWipkBIg4Cnn0U973pJSnbrsiWeDfnCw+85nPNEAYyePo0aOAnyOBBF26MqR8KEm8PEOAiCPPBjSfupOU8lRp17sUhdYFEkLYGR5438GDB0OtDxUZ8mmsqS\/ZQoCII1vjVVDSJqU8g9rl1gVaDuJSlO65Hdz6wPvw3A\/v5brvSQUeFNQEzuPOEnHk8eBmvWuulacMH2+7MutCx9nt15ZofaC1Itbnuu+u68\/63CP5gxEg4qAZkloEklJu2O6ePXtYJBReXke3rnURBjDWj8tXWC\/6PtCScd131\/WH9Zm+zzYCRBzZHr+8lj4J5YZWwKFDh2Dnzp3Qrl07aN26NfNbeB3dtoEXl8CQsFq0aOH0+NoksLWNGdWXHAJEHMlhTy2HIBCXcvMuReH\/NTU10KNHD+eEIfNtnD59mjnQy8vLlcJ3dSdTXNjqykXls4EAEUc2xqkgpXSt3GSObgS7qqqKOa1tL0upDuT+\/fth+\/bt0LNnT+jYsaPqbcrlXGOrLAgVzCQCRByZHLb4hE4y+saFcuP9wbrxh4fRxumYVhk97mcpKiqC0tJS5cRBlbqxjAtsVdumctlHgIgj+2PotAdJKhhbbfOlqNraWiVHt612owyMKAPKjeG\/utuWBLWfhj5GwYfuTRYBIo5k8U9960kqmKhtixndCDRaFyqO7qjt2hhUv5BglcRB1bbT0EdVWalc+hAg4kjfmKRKoiQVjEnbphndIugm7doeNJkMYYmDqnKkoY+qslK59CFAxJG+MUmVREkqGJ22kTBQqdrIudBp19VgBckQlDioKk8a+qgqK5VLHwJEHOkbk1RJlKSCCWtbxdFtAmZYuyZ16t6jIoNf4qBqOyr1q9ZF5QoPASKOwhtzrR4nqWD82vZzdGNyHibM2QqdTbLPfHBUZeDWB5bXcZ6r1q81WahwwSBAxFEwQ23W0SQVjNg2OrbxUCR8y8YLSQLJwkVGd5J91iUOb3nECfNP8HfQlYY+ms1IuisNCBBxpGEULMuwd+9eWLVqFdx4443QuXPnSLUnqWCQJCorKxk5nD17NpdzEbZ1eaQOpyTHwQR377YlQZswmtQfFVe6P38QIOLIn7HM9eRPf\/oTjBw5EpYvXw4DBw6M1MMkFAx3dB8+fBiOHDkCXbt2hfbt21tbigoDJIk+e2WKIgPei6G7eMlOHIxSfxh+9H3+I0DEkYdjnEXi8HN043IUWh1xb\/2RBqVqQwYeuuvn+7BRf9Cjk+SOA3n4SKeuS0QcqRuS6AJlhTjCHN2ulZsM6aTaFeWxJYPsxEFb9acZw+hPEtUgQ4CIIw\/nRtqJw29zQT9Ht2vllmalZ7vv3vPObddvc6ktDx\/JvOsSEUfeDSlAGonDJKPbtXIrJOLAvnoTB3H\/K1fLgEmNXR4+zqnsEhFHKoclmlBpIo4oGd1JKZ+k2nWxVOU3k9D6OHDgAFRXV8Pll1\/uJOggDRhGe4ro7iAEiDjycH4kTRzi5oL4N+YUYGiobs5FUsonqXbjIg5sB4MOtm7dyk45LCsra3DeuY1HIg0Y2ugH1eGPABFHHs6MJIhDthQVJaM7KeWTVLtxEgfvI0Zc4ZKVauKg6uOSBgxVZaVy+ggQcehjlvo74iQOVUe3CWhxKJ\/aWoBx4wCeekou4YwZAD\/9qUkPzO9x3Xexfp6Vb\/PMD9fymyNLd9pAgIjDBooR6sBDeiZPngxr1qxpUMvMmTNh2LBh7DNvmaFDh8KsWbPYlht+l2viMHF0m0CUlPLh7S5d2gVmzGgKf\/wjwODBJj0wv8d13\/3qV0kcVO2Ra\/lV5aBybhAg4nCDq3KtmBk9evRomDRpkjTLe\/bs2bBv3z5GFngh0XTq1IndEydxYFt8vyh8S8UEPdz+w9bmgt6+JKV8sN0nnzwG48Z1gGXLAG65RXk4rRV03feg+oMSB1U76Fp+VTmonBsEiDjc4Kpc6\/bt22HixIkwZ84c6NmzZ6P7\/L4Pu8emxYFO1B07dkDLli3ZOripo1sZEKFgUsrnr3+th+HDi2Dw4GJYuLAYJIadSZeU73Hd97D60aqsqqpi8sq2LQnqTFj9ykBQwVQiQMSR8LCgkkeLYvHixSzCxXv5fc+XrkaMGOFrpUQlDnEp6uOPP2b7RXXv3p1t2+3KuvAbhiSUD\/o8xo49Ddu2nYDly4vgkkuaJzJDXPddtX5T60O1\/kTApUYjI0DEERnCaBWsXLkSVqxYwTalw+UovET\/Bn6\/cePGBj4NThyDBg3K+UFEKUyJw8\/RjfUmsV8UtpuE8nnwQYD77wd46aUquP76trESpTiGrvuuU79s2xKyOKI9+1m+m4gj4dFDawMVPbc4uM9j+PDhjBRcE4fM0c235NZRMLahdN32hAkTmMhz585lv996C+DKKwGWLDkJV1+911lWtQpOrvtuUr\/Oeecm9avgQmXSgQARRzrGoYEU3ApBMlm7dq0TiwMfbBVHd5IKwGXbeGbJVVddxXDfuXMnfPABAAax4S70M2fWwdGjVZGIw0vIOqfzxWFtmWKret65af0pfBxJJB8EiDhSOC1Ev8a2bdsa+UBMfRwmGd1JKgCXbfPlPBz+117bAPPmXQKVlQAvvABwwQV1zDGsu48T4itiLEae4ds6fqfqaHbZdxvEFHbeuWv5U\/jYFpRIRBwJDrfMVyEuT+GbsTfqKiiqasGCBaxH+BsPcrriiiuYrwCtC\/yNygy3\/lA9RS9JBeCybcSHYzV06ApYuPAruXwN3Xa9hMzDlL1brHh3qE3SR6DbRz9Zg847t1F\/go8mNR2CABFHwlNEXJbCqCokhYqKCpg3b14uYkonj0N8k160aBH06tWLkYVpzkWSCsBl2+jfwON16+r6Q1XVSw3yNVTaNU2CVHU0q8gQZerarJ\/XhfOMW1Q264\/ST7rXDQJEHG5w1aoVyWPKlCm5e7xHvupmjqNCRMW4cOFCGDx4cKQN7JJUAC7bxlDmTZs2wdGjP4aPPhoXOF7f\/Oa5JayysnNbk6P1xvd3MiXkMEezy77bWKryAuY97xx3NTBZ7tN6cKhwYggQcSQGvbuGTcNx\/SRyrcCSWK4RHeO8fXSQ88vb57DIM9ORDHI0u8bdVf1YL4aW19fXM5ItLy9PLKTZdFzovnAEiDjCMcpcCSKO4CHzI44333wTOnfuzG5E5bdnzx6W8IgXOoKjLPeFTSA\/R7MrxS4jxzAZdb\/fv38\/W3bF3RA6duyoezuVTzkCRBwpHyAT8Yg4glET\/UC8JCcOfEs+dOgQC9FFn1Pr1q1ZIIHuWSK64xb3Uk8cxITk26xZMyguLlaOJtPFjcongwARRzK4O22ViCPc4kAfEPo48Lr7hhtgzJgxucizuo4doaamBnr06OGcMLyScoV++vRpp0s9cRAH93Ggjw59Qki+6DynK\/sIEHFkfwwb9YCII2BQMVkDAHC5at69f4XWOzfCAwdfaHDDqbVroaq0FDp8+cuJrc+7XuqJkzgwgEA1cTAPH8e87BIRRx4OKxGHZ1DPk0Xu027d2J\/L2iyGNmf2wfXV\/qc0IYE0vfbaRGYI97MUFRVBKZJYhw5WSSxu4uAgitFk2Cf0HdGVPQSIOLI3ZqESE3Gch0gkjPNkIYIXRhys7Lp1AEOGhGJuu4Co2PlSj+62JUEyJUUcKFNQ4qBtHKk+NwgQcbjBNdFaC544QgiDD04D4liyBKCiwn\/ckDzKy8\/9xHT5hQRjmKvOtiVpJQ4ul5g4iNu7kPUR0+Sy0AwRhwUQ01ZFQRNHZSULp23eu3fosCz70uvQpkszuH5hl3OksH49wDXXyO+LkUBkFkFY4mBop88XSNLiEGX0RpPxXZlV+0HlkkGAiCMZ3J22WojEgQoIlWrdf\/83dDm\/660U5PMEsGzcaWjTpeQccfCrshJO\/f3v0PQb3wgmEMfLV0GK3YajOS3EIVofaFHhZduf4\/RhK9DKiTjycOALhTj42yoqQfxhGzgePgxt+\/b1H1VcjkKFf37Jadn\/2tGYOM4nAH60ejVcPHKkfHbs2uV06UpFsYftUJv2pSo\/+ZD88SLLI92KiYgj3eNjJF0+Ewff\/gMdxjyjG\/MDcG8kdqwt+jd8HOE5IIXlJl\/iQIvj\/HnbgZZLCogD+2TqaFYhJqPJF9NSWBTZ6N7oCBBxRMcwdTXkI3GgNcEPnkLAkSSQLHwzusN8FVjBunWwbEEXaHN6X8OlKvwuiHj4aKeEOMSlHky4Q5xUHM1EHKl7bDMlEBFHpoZLTdh8IQ60KCorKxk5nD17Vu8sEbQ88CfA2Z1zjq85dxKg0hWTg9xEses4mk3qV8KHLA4dmDJblogjs0MnFzzrxMEd3YcPHwY8g71r167Qvn17swS4AALh4bhfqf4pHACAL8og5WSB38cUkhtFsfMdalFcmaM5Sv0qj4zr+lVkoDLuECDicIdtYjVnkTj8HN24HIVWh+4Rrr7A+yxfIXF0q18Db9b9Fg6dPctuGw8Anc5XwDLHP\/e52MhClNuG4uWhu36JgzbqD5rgrutP7OGihhkCRBx5OBGyQhxhjm7rygcd3wcrofbma+BYOcD\/FHeC99fvh9LiYvjbqY6w52xnaFd+An726jJ2pkSSe1XZ6rvsxEFb9cseH9f15+Fjm6kuEXFkarjUhE07cfidoufn6LapfGrfXw+frP8lHFu\/FJoeB2hxEGDtVoA\/1gBsgw5wpOgr8I\/SW6HqxJXw\/UHz4eFf\/ciOpaM2ZI1K2ew7Vu4979x2\/d4OuK7fEFa6zRICRByWgExTNWkkDpMzuv2Uz1tvAVx5JcCYMQA\/\/zlAixbnkMfdbvF6443O8IMfAMyYATDljko4tu4cWaCl0fyyIdBqyK3QashtzHH++vr18HhFBZwCgJfhSWjS5FIoKSmHoqK2UFZ2Em69dTc89NCgRIbWheL1Jg7iVudWlgF9EHIhfyIDQY36IkDEkYcTI03EwR3dJqfoyZQPJ49lywBuueUcaYwcORJ27SqBdq1fge9+5X24s+s9UPf+emjaoZwRRatrbmV\/e6+3ly6F71XMh31wOQBchrG40LTppVBa2hnq6prC1762Ax6eVgKlUAMXl5eznzgul4oXrY8DBw5AdXU1XH755WZBByEguJQ\/DvypjWAEiDjycIYkTRx8KQrJAv\/G3ALMBNY9RS9I+Tz4IMCKFSfhe997EV58cTqcOdMW\/vGPn0PTpnvhzyMehLaXD4TPDLkVWlwWvrNtZeU\/YGLFeHhp\/VEA6AkAn4MmTcqhtLQcyorqYeSZ78OlJ3bC0TNn4IvTp8PQadNys2b0LcfgueWtYHLfH8PoR2+Gz3m2O\/ngA4BhwwAGDmxoIYVNO9eKF8dm69at7JTDsrIy65naruUPw4++d4sAEYdbfBOpPQnikC1F5TK6DZAIUj5Ll66Be+65iG018tnPjoPq6h\/A8ePfgs9+9sfw6KN3wo033qjd4vr178E118wDgJMA8M\/QuqgVjGkyF7oWH4QLS0qg+NQpOFVXByfLy+HC226DtuvXw\/Y334dni1dAcbNmcF+nCXDl849Ce2QJAKitBRg37lw6yQsvAJSVqYvkWvHy+jHiCpesVBMHVXvgWn5VOaicGwSIONzgmmitcRKHqqPbBBA\/5YPLUqtWrYIFCxZAXV1\/qKp6KVd1hw7j4J\/+6S+wfPly6Ny5s0mTUFn5CTz77P+Bn\/1sJfwzHIZrYRO0btIE2jRpAq2aNmU\/J2trmaLtcNFF0KxlS\/igtivMrHoUvlT6Mtw06HW45Xe\/Y23zJbU\/\/hFg8GA9cVwrXrF+npWPBGLrzA\/X8uuhSaVtI0DEYRtRB\/XhvkyTJ0+GNWvWsNqHDh0Ks2bNYltu+F2uicPE0W0Ci1f58H6JdZWUVMAHH\/wUBg\/+PYwb9wkMGDDAmDR4vdju6tXvwOyR18Pn4TBcBAC4f26rkhLo0q4dsy5OnDgBJ86cgfrmzeHQJ5\/A+mPfhd+eWgrfgSthya5l0KRVOfO\/IGH81P+AwUBIXCtev\/rxM1s71LqW32Q+0T32ECDisIels5pmz54N+\/btY2SBF5JIp06dYNKkSbESBzbG94vCt1RM0GvVqpUT5yq25UccaGmgNTFw4EBo1aoc5s\/vD7\/\/PUCfPgArVwL06hV9GLDdv779NvxiwgQ4tmkT3Nq2LbQpK4OikhL45MQJqK6vh+rDh+HC4mKoqa2Fk6dOwTvQHH4Hj0I1lMMvHjsC2z8awSwO3SUqkbxw76kkop6CEgdV0SXiUEUqm+WIOFI+btu3b4eJEyfCnDlzoGdPdNwC+H0mdsOmxYFO1B07dkDLli3Z8oypo9sE5jDlgw7yVasAHngAAP3Vug5omUzY7uurV8OM89uq\/0v79jCgdWtGGAeqq+Hg8ePQCgBaFxdD65IS2FxfD7tPnoS90Awq4Qk4CKNZ1SZLVGkgDpSB7xCMf5ucjxE2dibzge5JDwJEHOkZC6n1gBbH4sWLWQQMXnzpasSIEezN23tFJQ5xKerjjz9m+0V1796drX+zrctjuoKUD77JY74GD8n1\/h9FRGz3148\/Dk9MmABnzld0TWkp1NbXQw0AHAcA9HOj7+N\/AGDrGV4K4OLe34Hf\/u1llkdiskSVFuLgcphaH0QcUWZg+u8l4kj5GK1cuRI2btzYwKfBiWPQoEEwDGM9PZcpcfg5urFqa\/tFaWItUz48xBUDp0TlzC2QqEtW2O7G1athzsiRcO5YIYD2AIAeJSQNJA\/8\/wIA+MDTpy59fwirtvwqkrWBVbpWvDr1y7YtCRpOnfo1pwUVTwECRBwpGIQgEVwTh8zRzU9gS1IB+LV9+PC5pD+8vP6DoO90hpm3+\/y3vgX\/sW0bu7UYAE6f\/8G\/8UIiqfVUfM2oxTD7uVF5RRxe6wOtTvS9EHHozKr8KkvE4TOeuDQzfvx4uO+++3J+Bdmwo2JfsWJFg6Ukm1PEFXGgclRxdKeNOO64A+Cpp+T+A9mWJDpjwvtcsns3jP7GN+Cjk5jXce6qhjLYBX2gG7wLF8LhBtViVvmEZbvYlihvvHEa+vWrZRhjfbphrq5xN61f9bxz0\/p1xonKJocAEYeEOEaPHg3vvvsujBkzRhq9hLe6Jg5cdrLl4zDJ6E5SASTVttju1j\/9CZ554AHoN2QI9L\/6ahh1zb9BKexpNGuQNB5buxb+vqcrfP3rJfDSS1UwYMCpXOQZ+goQf1VHs+u+R60\/7LzzqPUnpxKpZRUEiDgCiOPCCy+EDRs2sNDXJUuW+FofrolDN6oKw1Xxwt+YCHfFFVewN17+5otRUbj1B4bR4t9hV5IKIKm2Ze1uXr8e+l+zFNrDOwy2emgJLy7539Chc2fo2b8\/8wVt2tQUbr75Yli7thauvbZhno13h9okl3psYBt03rmN+sPmJn2fHAJEHAHEMXz4cPjud7+bS77zsz5cEweKp5PHISbJLVq0CHr16sUIwjTnIkkFkFTbfu1+UlkJc6\/5Dsyo7N5gxtxfvhOG\/+pJ+Ex5uRIhqzqaXffdZv28LpZN36EDm2s2609OPVLLMgSIOEKIg0ctcYXstT7iIA7dzHHckmPChAmwcOFCGDx4cKQN7JJUAEm17dfull\/+Et6rqIDxZ78Oh5hbHCOramF60f+Drzz9NHz53\/9dS8tw60PmaHbdd9v1e887x10NXCYwaoFNha0jQMShSBxYTFTg3PqIgzh0R900HNevHdsKRqcvSbXtbReV4v999ll48s474RB0gZ3QGU5AC+gGe6E3bIPRS5bAd267TadrrGyQo9l1313Vj\/XitiX19fWsf+Xl5bHm\/mgPAt1ghAARhwZx8KKi9TFkyBB4\/\/33nUVVmYwqEYcJap\/eg8pvz549LBIKL\/RdvLFqFUsI9LvuNyQOXpefo9mVYudtuq5\/\/\/79bIcD3O2gY8eO0QaE7k4dAkQcBsThtT769OlDxOFgartWbn4i41vyoUOHYOfOnSxTv3Xr1iyQ4I3f\/AZmVFQ4IQ5ufWAAA9+h1vVSj2tsOfk2a9YMiouLlaPJHEwjqtIBAkQcEUHFt6qHH34YHnnkkdyWIBGrjHw7WRx6EHqTIPH\/mpoa6NGjR+7wqf9YutQpcXgtgdOnTztd6omDOLiPA5d4kRAxmg+d53RlHwEijuyPYaMeEHGoDarfFitoXeDldezGRRxcctdLPXESBwYAqCYOqo0clUoaASKOpEfAQftEHHJQOVmg4sQfntfCt1jBO\/2UatzEwZd6ioqKoLS01PpST9zEwUdEjCZD60Mll8jBI0JVRkSAiCMigGm8nYij4ajwpShcMkFHdFheS1qIw7vUo7ttSdDcTIo4UKagxME0Pk8kU2MEiDjycFYQcZwbVHGLFfwfCQOXonCtXVepJmFxiMtlqomDqtM5SeLgMoqJg7hpIlkfqqOXfDkijuTHwLoEhUwcNo61TZvFIZ6BEpY4qDqZ0kAcIrnbPO9cFQMqZ44AEYc5dqm9sxCJAwkDlarKUlTYwKWZOMSlHuwzWk+ifyasb963\/SSOpvWTkScO4neqG0Gq9pXK2UeAiMM+ponXWCjEoeLoNhkMXeKYu2QJXGWQOa67XOYtH7ZDbdT6TbCLSkxI\/niZkGEUeelePQSIOPTwykTpfCYOP0c3vnVjwpytY239iAM3Ofy3bt3YUbHi1au8HBatW8c2ObR5qS4lmTqaVes37ZPr+k3lovvsIEDEYQfHVNWSj8SBjlN+8BSCjSSBZBHm6DYZGJnSe+CBB+Dx6dOh9Hyl9QBw1\/TpMG3aNJNmAu\/RVby6jmbd+nU76Lp+XXmovF0EiDjs4pmK2vKFOHApprKykpHD2bNnczkXqmeJmA5GEHFMnz69QbX4fxqIA4Xy7lAbtNzjWrG7rt90bOk+OwgQcdjBMVW1ZJ04uKP78OHDgMf4du3aFdq3b29tKSpssLJKHLxfKo5m14rddf1hY0jfu0WAiMMtvonUnkXi8HN043IUWh2uIn9kg2OLOHC\/KdxeHH\/zrUxUJ4QNxctDd\/0SB23UH9QX1\/Wr4kjl3CBAxOEG10RrzQpxhDm6k1I+UYnjyOkj8OeaP0Ofmj6MNPDCHWJbtmypTCC2+i5LHLRVvy75JvpgUOPWECDisAZleipKO3H4bS7o5+h2rdx0lR46x2U+DiSIzfWbGWHsOLEjV\/U9cA\/7ez7MZ797lPSAYW2HQbvidoETxnbfveed267f2xnX9afnaStMSYg48nDc00gcJhndSSkfHYvjJz\/5CYwfP55tw84vThKcNETi4GWmtZoWaH246Lt3h1rM1na1DOhC\/jx8VDPbJSKOzA6dXPA0EUeUjO6klI8OcXz1nq\/CoPGDwEsS4v+ykSopKWGJbriMFecbO1ofBw4cgOrqarj88sudBB0kNXZ5+DinsktEHKkclmhCJU0c4uaC+DfmYKCC1M25SEr5+LWLS1G4TPXQQw81GByROLilETZ63uWrf231r4A\/4uW67xh0sHXrVnb4WFlZmfVMbdfyh2FM37tFgIjDLb6J1J4EcciWoqJkdCelfMR2a5rVML\/F2zVvw5E5R2D+\/HO+Cn7dc889bKlKvJBAZMtUXtLg900onsBCjrn14brvvH6MuMIlKyR3mzvUupY\/kQeLGs0hQMSRh5MhTuJQdXSbwJyU8sEQ2n379rHM9Hln5uVE3\/jIRvjP+f\/ZyOL4zfjfsM9Ei8OPOFSWrzBsF39c912sn2fl29yh1rX8JvOJ7rGHABGHPSyNasLDhSZPngxr1qxpcP\/MmTNh2LBh7DNvmaFDh8KsWbOYYvO7XBOHiaPbBJy4lQ+G0b527DW4quYqXwsCz5X3Why4VOVHHFjhAqG5AAAeeElEQVQBEoV3+Ur2mUg8bYvbwveafw9aHmkZq\/Ma8T548CDre9QdauMeO5P5RfeYI0DEYY6dlTsxM3r06NEwadIkGDhwoG+ds2fPZm\/ASBZ4IdF06tSJ3RMncWBbfL+osFP0bIATh\/JB38XrNa\/DjvodgWG02J+zj5xVWqry9t27dCWzTrwkM+b4GOjWrZuTA46CsA1KHFQd1zjGTlUWKmcfASIO+5hq1bh9+3aYOHEizJkzB3r27NnoXr\/vw+6xaXGgE3XHjh0seQ3JwtTRrQXK+cKulA9aFs3rm8OJEye0wmj9iINbHH6WhYwgxM\/Dlq\/Q54F+CDx33OYVhi1alXgCoan1EVa\/zb5QXfEjQMQRP+YNWkQljxbF4sWLWYSL9\/L7ni9djRgxwtdKiUoc4lLUxx9\/zPaL6t69O1NgtrYuV4HdtvLhGd3o6P7o9LlzH3TCaP2WqkTneFj+ht8yFZchjHj8Iq9UMJSVUcXW1PpQrT9KH+je5BAg4kgOe9byypUrYcWKFWxtGZej8BL9G\/j9xo0bG\/g0OHEMGjQo5wcRu2FKHH6Obqw3if2isF0byofvF4UJemhhqPgcZFMibKnKuySFfit8KfC7Pn\/L5+G5O59r8NWcujmwedZm2PuHvdC7d2\/oPrc7lLb51NJA38ddze+C+++\/v5FPjFfk9X\/xpdB3330XxowZw5Y38bOKigp477332DLp1KlTc3KI\/rSdO3eyz03OO7cxdgk\/mtR8AAJEHAlPD1QsqOi5xcEf9OHDhzNScE0cMkc335I7SQUQpW3u6MZQWu9ykJ\/PAadBkC8C65BZHEXjixrNolN1p3IkIJtit9xyC9x55525r3+85sewZfYW9v9FF10E8+bNYz4O8dq1axdMmDAB9u\/fL525InngsiaSBL6ULF++nFmo\/MUCK\/jiF78IS5YsyVm7ItFw4uAN6Zx3HmXsEn4kqXkFBIg4FECKuwi3QpBM1q5d68TiwAdbxdGdpALQbRutC7QsMJx21olzgQRhl3f5KCiMVmWpit+Poa0\/nPBD+OhvH0HfSX3hsaGPMVGQnP7rif+CbS9sg87Xdoalk5fCouaLoP5oPWycsJGV59fXFn4NOvTrwP7l9W7evBnGjh0LF1x0ASx4dgF8\/bKv58pzQujTp0\/uRQTn0pQpU1gwBRIE+tH4Z\/xG0cLlRINRVatXr25MiKdOMes47Lxz3bELGyf6Pl0IEHHENB7imx82GRRSK\/o1tm3b1sgHYurjMMnoTlIBqLSNlgWPiPKG0foNbZgfgitpvyxwvzwO9HGIFodXwWN9CxcuhH79+uXE4UtY1157LYuQQ7\/RqCdGMTIZMGAAK7dp0yZGON2GnrM4eL28XNvebWHQ3EEw7bPTWOIgXpw4RJJAi\/app57KzTcs5w3\/FucirwM\/W7BggfTpCDvvXGXsYnr0qBkHCBBxOABVtUqZr0Jcntq7d2+jqKugqCr+sONvXJq44oormK8ArQv8jVFRuPWH6il6SSqAoLa5dbGwZmHO0S0qWN1kPNkylWiBqC5V4T182Ykr+CltpjBro3pXNbx171tQe6CW+RtQQU\/fNT33GZIMksYLL7wA6Af5wp1fyJEG4oEh2X\/4wx9AXObCyCt8KbjrrrsAfRmcCHB+oQ8DP+NWBV+KOnPmDCOcdevWsenKl7E40YhWiGw+B513nuS8UX3+qJw5AkQc5thZuVNclsKoKm6Z4Po2z+vQyeMQ168XLVoEvXr1YmSBb7VIFrpRUUkqAG\/bPIyWO7r5AIRZEbJtPvwG0K8s\/yxsqYrXJyp42SRBQnl+7vNsPG6bdRtziHOi2LVmF\/N14FJWv8n9oGnzpow8RIIJmnycBIL8G9dddx0MHjw45xhHxzkugXFrhNehMsn5OOE844mDSc4bFZmpTDQEiDii4Wflbu+as\/eh1c0cX7VqFXOg4tsrKoegs6fDOpCkAuBtl3YohTdPvcn2jOJXkIIP6lOYA9xLRtyKwftkW47g7riiXKJ\/w08W0VrgPgvRGc4\/4+SCYdB48c+DyOi6+dfBxE4T2UsCn1d+Po8ZM2bAF77wBXZeOkZXYRl8Wbn33ntZ9bLw8CDrA61avm0J7mqAeSCutm0Pm7f0vVsEiDjc4ptI7abhuH7CJkUcfCkKl1aaNWvGRPMuP+nsRhuWJxGWiIfthy1V8TqmbJ4CG8ZuYDKjg3tmv5mNwoDxu1FHR+Uc6H7Yt7ioBQyeNximd5vOvn7iiSfYEhaG6s6dO5fl1XAyET\/Dsrhl+zPPPMN++NIVfs4tiqVLl0KXLl3grbfeYuG9eI0cORLWr18P\/fv3D9zSJmhS43xB5zkGKOBSVnl5ubaVm8hDQ41qIUDEoQVXNgpnlThER7dOGK3fqHiXr6Lkb\/DIqyDnuEg83PntVeac\/HjZoDwP3idOPGKOh+j7EKO0xNyQmUdn5qK0vP4NVOxPPvkkXHDBBXD8+HG44447cjlE2K6KfyPsScBwYVwqwyiujh07hhWn7zOGABFHxgZMRdysEQe3LtB3Mff0XJUuNtpAUGU3Wln+hrdBP8e66lKVmL\/BfRQTm09sZC1hPgYuC+GBSmK4Lsoi+ki4A10szz\/jRHRw80Fm4fDlrtXdVjdwwj\/++OPwzW9+E95++21mVeCy1C9+8QtmFeBSEgZSYOQVv3T8G7LBwj7s2bOHWYvovI+6aaLSpKBCsSFAxBEb1PE1lAXi4NYFWhY3nLghFJy4HOBcGeNv7\/LVTY\/c1GhbdR6Oq5K\/IXayxRMt2LKT6AAXv+e5Htwfwpe\/cPnq6XlPN0gMRGukZlZNg2grP6sHc4Lw3HR0hN999905H8Q777zDCAUv0R8SOigBBcQlTvTRoe8Do\/mQQOjKPgJEHNkfw0Y9SDNxoHWBTtSHahqepBe03XiQMlcJo5XdL7MsZFMiyDmukr\/BZRWd3DzJz2sx8cgqnuvxoyU\/Ynke3vBeLisvz\/0iu3+3m5Xn9y+EhblM9nEPjoPbb7w9Rxxo6fGw3bAt+1UfF69vzHveeZSADVUZqJw7BIg43GGbWM1pIw60LprVNGNLI7hfFL9sWxEyB7gt4gmLqjI9f8Nr3fjhIptMphhObTGVWQGuop5kQRXitiVofWAIL13ZQ4CII3tjFipxGogDLYvN9ZvZGRc6YbSoCG+Gm6ELdGnQT9MwWpE0goALC++V+ThUjo5VsXhksqkc\/GRKPGfPnmWRWegkt30FReMFJQ7aloPqc4MAEYcbXBOtNUniEB3d+LdXccu2FvcDzFRp+oXWmhKPaMWoLFUFZayrhPxyvLxlwyyLKMRje8t2lEUljFtMHLR53nmiD1+BNE7EkYcDHTdxiI5utDD8lJ4NpcnfrOPO3+DKPOggJz\/LRpck\/UiWT0\/ViDBV4vFiiFu239vmXmsHRqkQB8oqbuWP1g\/5PrKhkIg4sjFOWlLGRRzc0Y3OVdU8CRUrwibxqMqlYvGEnccRNEgqFk9UWWVLYjIy8ZMXM87xJ+qlShy8HZ44iP9T6G5U9N3fT8ThHuPYW3BJHPwUPdyRViWM1k9pqUQzyd7WvZ\/Hkb\/BBzDMOe4daBNZZZPFSzxRMPSTU7Rs0PoY3mY49CjtYTx3dYmDN4TOc7zI8jCGPpYbiThigTneRmwTB2YBX3jhhdCkSZNGYbSyN3Xx7Rf\/NrUiwtb2\/ZzaMrRVHOBBsoZtcuhCmQf5TPxk9eu7KYY\/afkT5jw3uUyJw6Qtuid+BIg44sfceYu2iINbF5dVXwZFRZ+ecmeqiGyFq\/pZMUGfeRWsVxljXskLb7wAZ1qdgbqr66TjE7ZUJQuj1c01EeVVWb5SWf6TYRBG6Jj1jeRRWvrpEbYqE5iIQwWl7JYh4sju2Eklj0IcPIwWQ2jR0c0v07d1m2\/AMusmav4GHpb1xhtvsOpxff\/qq69m+Q2i1YT9D7I4VBV8kCWmm78hi7wKIh5dDLlMPUp6wJ3tPz3mNuyxIeIIQyjb3xNxZHv8fKU3IQ4eRotv3\/wKsyxk0Jm+AetEXoVZEV4FLZP19mO3w4oVKxp9jcRx\/fXX55z+YcTB29MNo1X15cjIwOvj0cFQl3jQ9zG25Vgl5zkRRx4qFqFLRBx5OL6qxCE6url14UIR6fghuIKUWRG6eRJh0Uwvv\/wy23rD78Klq5M9T8KJ\/uey3VWOjvUjNBvKXIZhEsSDW7bz42pljw8RRx4qFiKO\/B7UIOJAy4Jv\/aETRitb4vAu54jlbOUeyMgkisWDCldcogqaEWh94PLV008\/DfPnz29Q1HvmeFRZw3wOQXKGkaSfFWZKPGh9fLnllwGTB\/0uIo781jFkceTh+PoRB7cu3q55GypOVyj12mUIqN\/Si02lqeJzuGDFBdDkWBMlLLDQBx98AC+++GIj4hg\/fjxb0vKzLOLAUGaFcaIwtXhUosQml0xmobPoRBcvIg7laZXJgkQcmRy2YKE5cTz\/\/PPQt29fQMti1olZoT216QD3U1oqikj1DdhW\/sZf\/vIXdoqeyoWn4+GPeH31nq+C9+hY75t9FFldEk\/YeOsQjzdxkIhDZUZltwwRR3bHTir53r172Znj7dq1g6lTp+bKBS1l+FkA\/EaZMvcKEKaIdKOGRJlkyljFsgiT69Fjj0LzN5pDcVXDt2Zv\/\/yIQ1yq8iOIuDBUWaaKimGY3wmXrzDyql1xO6W9qvLw0SuYLhFx5OlQc\/L48MMPGXms67su11PTN2CbxGMSeSV7A7alNEv+UgKlm+X5CjrEYVNWTqA2SDIO8p7Waho7+Q+DDlxt256nj21mukXEkZmhMhMUjwXFn0u\/fSn0n9qfVaIToRP2th6HIvLruSnx+NUlEg+GI2NOh1+klcpSlUxWk+WrMFn592kIm\/41\/Bq+D9\/PiYw+DwzC6NSpE525YfbopvouIo5UD48d4bzWB\/o9RKWTpdyDsOUr71u5DMEw4vGzPoIsDlsYmhKPqQNcJDQXYdMutmy381RQLVEQIOKIgl7G7uXWBxJHt8e6NZA+K\/kbUSOvdIgHI65E30eYxeFVvC6Vuarfyc\/CjIqhjCRlS2q2t2zP2GOXl+ISceTlsMo7xa2P9z58Dy697lLoPap3bvlK5239WXgWqqE6d6\/YYpT8DZXIK1Mrwksa\/G07TMHzfA8V4tDBMCiZ0U9WWb9dRl7ZJB5bW7YX2CObyu4ScaRyWNwLtWrVKhZ5hdbHfffdl9ubyU+Zqihz1TdgU8e8TaWpSjyirBh5VffbOhZ5xRMCsZ6Xurzkm7\/hbcMFhmkkHu888I63jS3b3T8d1EIYAkQcYQjl8fdofSCB4BLWqFGj4Oioo7neqih4P2jCHLU6jnm\/+lXkUrV4TGTlIbunLz53LC6\/TIMIZBFhYctBnOC9MqhYPGGyqlpiogyyUGTZeGPklY0Do\/L48Ux114g4Uj088QjHEwZbdmzJIq869O3AGpY5kMPi+fm9XPo4Iq90ZZUpPZnStBXyG4SrlwxMSTIrYdOmW7bH81RQK0EIEHHQ\/GAIoPVx1VVXsb\/R+sAfUfHbegMOi2byvsGbKHgZcYmfq76Zy0gySC6\/KZVW4pHJGgeGHFvdLdvpkU0eASKO5McgFRLgchWSx4033ggTJ06EU6dOGSUO6ipNm8o8aM3fzwFuqsxVSCfMsoiLePxkNSXvsCCCIAvTOzZeuSjyKhVqQFkIIg5lqPK7IJJG586dc53kobsYdRUWeRWHIgqzeGwoc9mSmsxnkgbi0VHmMgxlfgjZjFcZb92QX0y43LJlC7z22mswePBguPvuu\/P7gct474g4Mj6ALsWPmjjot8xj+gasq4hEXILCVWWWQRxKU4V4VDH0k9dLCK4wNCWemqoaOL7\/OOx+ZTd8+OqH7MVlwIABjDTElxiXc5zqNkOAiMMMt4K6S5Y4GLci8nvT9VP8pk5l2aC6JJ4osgbJlaboNb4sx2VC6+L+V++HD1\/5EGr21zCyuOmmm9gyKV3ZQICIIxvjlLiUURMH0xACmgTxhIX86lg8YRgmFb0WZO1w0kDrot+WfvDqq6+yJSm0KJAo8Iesi8Qfb20BiDi0IUvHDbW1tTB58mRYs2ZNA4FmzpwJw4YNY595ywwdOhRmzZoFLVq0MO6ELHEwTEHqvAGrrKFzhRu0JBVkQXjv93OsqywTmSpz3fwNP8uE9083FDkoiMAPVz8cVcf7oaqH2DLU3577W24pCsli4MCBxnOQbkweASKO5MfASIIjR47A6NGjYdKkSdKHcPbs2bBv3z5GFngh0eBupXhPlItbH5s2bUpl4qBN4lHxQ\/C3alGRez+T4W1KPDJlHhZE4CeXbeIZUTWCWRVe64Ic3lGeunTdS8SRrvFQlmb79u0sbHbOnDnQs2fPRvf5fR92j3Lj5wuKiYNXPXYVtLy4pbQKE2Uex9KLn8AmsgZZN2HRTH7EYxpEILOkVKKvgkhSrNdPNlyKOrjlIBzacqiBo5usC92nKhvliTiyMU6NpESljRbF4sWL2Ul\/3svve750NWLECGtLBd5tS1QTB4OWXmwpc1kYrextXaZ0+ecuQ37TTDxBpIOObrQsXnnlFdi\/fz85ujOqT3TFJuLQRSwl5VeuXAkrVqyAgwcPsuUovET\/Bn6\/cePGBj4NThyDBg3K+UFsdQeJSjVxUOXtl7+Fh72tu1TmUYhHxT8iwz7I4pHhEoV4VGXlcnHrAn0XaGGgcxsTRps2bUoOb1sPVMrrIeJI+QDJxENrA5U1tzi4z2P48OGMFOImDi6nTuKgzLIQl27iDvlVVeZRwmhVLB5VZa5indnCkIfR+jm6ueWJwRO4PEX+jIwqFkWxiTgUgcpCMW6FIJmsXbs2VotDxEcncdA0mimIdGwQj2rUkKnFE4V44sjf4P1C66LTq52Ys1sMoyViyIJGcCcjEYc7bGOvWfRr4OFDXh+ICx9HUCe59fHtb38bWkz9NARYRWmqvJWLBIF\/2wr5jYN4uLwqxGMaeWUaEYaWxawts8jRHfsTnJ0GiTiyM1Y5SWW+CnF5Ct\/6vVFXtqOqVKATEwfj3LLdVGl6yUim4FX8ECKZcazSnL+BYbTc0Y3+iksuuYQyulUmeQGWIeLI6KCLy1IYVYWkUFFRAfPmzctFTLnK4zCBTNy25LHHHstVESUE1CuHSRitLOTXJvEELavZSsYLCyLwI0T8zM\/RTRndJjO8sO4h4sjweCN5TJkyJdeD5cuXNwizdZE5bgKX6DjFvzt27AjXXXdd4ImDNiKvgpavZMrczyktWxLjn\/vJako8KktXsn55lwDDwmife+45ZmHwzQUp58JkdhfmPUQchTnusfYarQ0ebXPDDTeweP+RI0cCnjjIEwf9rIWgZSITZe7XaRWLR0eZhxGPDULU8eWIfUbrAkNoeaIe3y8qDkc3t4h56DjKhbsYLFmyJJfAyhNKuczeF6FYJy01FogAEQdNEOcIeM\/6wAajJg6qhquqLF9FDVcNsmxkhKhi8ZgGEYiWED\/ngm8BwskCd6SNc7+osIRV71Irlr\/33nsbEIvziUoNKCNAxKEMFRV0gYCYONhzas8G552L7ekm48ky03Xf1r2KX0WZq8pqMxTZa53xMFrM6EZHNyeKpLYu98srEscX\/XF4ifuo+X3mYg5SnfoIEHHoY0Z3OEAgSuJgWLiq+AYeJrrN\/I0wuXQc87JlNv45tsXDaMWM7rQ4uoNIQBYliC8VL774YuQdncPGnL7XR4CIQx8zusMRArh8hb4Pft553759WUumyly2TBXmhxCXnnhXbYXRyiweP0hViQfDaLmjG+vhZBHnUlTQlODEcPToUdiwYQMrKvo3ZDs9hy1vOZqGVK0CAkQcCiBREX8EXEVtcesDN0w8OupornGVZaKgN3Pd5SuZMpcRj4zkZBaPaeQV1sfPuRAd3ejkRuzwwl2T00IcnBhQHr4UJfowysrKfI8IIOJIr+Yh4kjv2KReMpd5IrLEQV1lHpQnYTOMViSNoIEzTRzEOlUd3Zw84oiWMp2k\/KUDLY\/bb7+diMMUyITuI+JICPisNxvHeR+IkUnioM5yELahEnnFy\/FxkznATa2IoJBfHkYrbi6Ib+9JObptzV3u9xg7diw7ZMy7azP5OGwhbb8eIg77mBZEjXGd94FgipsmiomDUcNoZdnWMjKRDawK8ajKyomHWxf5cEa330uG1yFOUVXZUhtEHNkar9RIm8S27fy88\/Z928MV913BThyMkjioqsz9QA\/aoTYK8aB1UfRcUV5ldIvLUtzHEbZlDuVxpOZR9xWEiCPd45Na6ZIgDtH64OedB504GCVPIo78DU5c\/JyLD1\/5EGr217AtQNA\/kfWlKHHyegMp+vTp0+j0SsocT+3j3kgwIo7sjFWqJE2KODgIXMngvlc2Egdth\/yinEGOebQs+m3pxywL8ZyLuDO6UzWpSJjMIEDEkZmhSpegcfo4ZD0Xty3pPao34I9smUjFD8HvFduznb\/Bw2iTcnSjL+Gpp55iXfR760\/XLCNp0ooAEUdaRyblcsUVVaUCg\/e886iJg35tRiEeTNDje0WJ1gUuReGyVFyX168ghlO3aPHpQVtxyUPtZBcBIo7sjl3ikrvM49DpnGh54H1hiYM6O9R6rRAVvwmXHZPzdr+ym+1Im\/TW5X7Z2bKMbR3sqWxhIkDEUZjjbqXXrjLHdYUTt21HHwH+\/96H74F44qAtKyJsA0N0dPNT9HD7+LQ4umWnPyL5l5eXw7Bhw3Rhp\/IFjAARRwEPfr503W\/bdvG886lTp+a6qpKgp3v+hvcUPWwsbftFybbvoB1o8+UpiLcfRBzx4k2txYiA68RBHkbrdXTjWd24WWOaDiIi4ohx4hVAU0QcBTDIhd5Fbn2oJA56sfJujCgLo\/XuC4WKGnNN0rJfFBFHoT8FdvtPxGEXT6otpQhw68ObOKiavzFly5TUOLpNICYfhwlqdI8MASIOmhuxI+B1qnMBZs6cmXPSunK8i4mDX3rsS2zbErz8tlzHMNo0OrpNBoyiqkxQo3uIOGgOpAYBlTBQl6G+ssRBBMjr6OZndMedc+FisCiPwwWqhVknWRyFOe6J9lq2bMKFiiu5UEwcxNwPDJ\/Fk\/SSzrlwOTiUOe4S3cKpm4ijcMY6NT0NO9kt7u1MuPOcWxdpcWinZsBIEELAgwARB02J2BHgSyYHDx6Effv2sfZF\/0YSGyj65YLEBQxaWBUVFTkssF3xTG78n3aOjWs0qB0VBIg4VFCiMlYRwOUSVISLFy+Gdu3aAfd5DB8+nDnHkyAOqx3UrCzMAuPEMm\/ePHaOOJ1VoQkwFbeOABGHdUipQhMERMft2rVrYePGjTBr1izgm+95T4wzaSOt9\/gRpSgrnY6X1pErXLmIOAp37J333LsEM3To0AZkIAogvnVv27YNUFlyiwTLceIYMWIEe+vOpyto2w8ZYdJ53Pk0A7LXFyKO7I1ZpiWWKULxrRv9DRMnToQ5c+ZAz549WX\/DIrGyCgrH4+jRo7BhwwbWDdG\/IQtdDlveyioeJHc2ECDiyMY45ZWUYedNY2dd5nGkCUxODGhF8fO4RR9GWVkZjB49mn0nWlpEHGkaxcKThYij8MY8FT1G8pgyZUpOFu+GgK4yx1PR+RAheN\/R8rj99tuJOLIwaAUmIxFHgQ04dTc5BLxkKYYge6Xifo+xY8fC5MmTYdCgQQ3OzCAfR3LjSC0DEHHQLCAEEkTAz3fj9QNRVFWCA0RN+yJAxEETgxBIEAFxWYr7OMJ8QJTHkeCAUdMMASKOApgIor9AdrgQD53t378\/O3qVrvgQ8Ppz+vTp0yAUGSWhzPH4xoNaCkeAiCMco7wowaN3sDNifgT+zxXX7t27G32XF52nThAChIBVBIg4rMKZ7sq4VYGJeHxZRHybTdNRp+lGkqQjBAobASKOAht\/HtnDScIvj6DAIKHu+iDAl8Zk2f58Ho0ZM6bBSwiBWRgIEHEUxjjneuldlnrmmWcabDhYYHBQdwMQ4OThDRuWWa4EZuEgQMRROGOd66l3DylaoirASaDYZQwFXrNmDSxZsoRt\/8It1K5du0r3HVOsmoplGAEijgwPXhTRaakhCnqFc683qAItVJFICgcJ6qmIABFHgc4HvgxB1kaBTgCNbntDgYMy3jWqpaIZRoCII8ODF0V0Io4o6BXevWShFt6YB\/WYiKNA5wMRR4EOvEG3+XLVu+++2+hIW4Pq6JY8QICIIw8G0aQLRBwmqBXmPdxBft9998HDDz8MuLuAeDpjYaJS2L0m4ijQ8SfiKNCB1+w2X6Lifg3v\/5rVUfE8QYCII08GkrpBCNhGQJav4Q3Rtd0u1Zd+BIg40j9GJCEhEDsCQXubBX0Xu6DUYCIIEHEkAjs1SgikG4G7776b5WvIwrXDtiRJd+9IuqgIEHFERZDuJwQIAUKgwBD4\/5K8+luiRcQbAAAAAElFTkSuQmCC","height":0,"width":0}}
%---
%[output:5a88bca3]
%   data: {"dataType":"text","outputData":{"text":"Trayectoria finalizada.\n","truncated":false}}
%---
