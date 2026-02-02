% ============================================
% Three-State Network Current Model Visualization
% Based on core formulas and parameters from 6 images
% Implementation of three-state network current model visualization
% Modifications: Adjusted color scheme and formula subscript format
% ============================================

clear; close all; clc;

% Define color scheme (using four user-specified colors)
color1 = [0.3, 0.396, 0.6];     % Dark blue series
color2 = [0.54, 0.55, 0.75];    % Purple series
color3 = [0.93, 0.79, 0.45];    % Orange series
color4 = [0.714, 0.463, 0.4];   % Dark orange series

% Define state component colors
color_maint = color4;     % Maintenance current uses dark orange
color_active = color3;    % Active current uses orange
color_tail = color2;      % Tail current uses purple
color_scan = color1;      % Scan current uses dark blue

%% 1) Core model definition
% According to the core formulas in images 1, 3, 4, 5
% I_net(t) = I_maint * 1_iface_on + I_tail * 1_tail + I_active * 1_active
fprintf('Three-State Network Current Model:\n');
fprintf('I_net(t) = I_maint * 1_iface_on + I_tail * 1_tail + I_active * 1_active\n\n');

% Model parameters
V_net = 3.7;  % Network interface nominal voltage, based on image 1

%% 2) Network type definition
% Based on parameters in image 6
networks = {
    struct('name', '3G', ...
           'R_a', 0.025, ...    % 0.025x + 3.5
           'R_b', 3.5, ...
           'E', 0.62, ...       % Tail energy
           'T', 12.5, ...       % Tail duration
           'M', 0.02, ...       % Maintenance power
           'I_scan', 0, ...     % Scan current
           'color', color1),    % 3G network uses dark blue
    
    struct('name', 'GSM', ...
           'R_a', 0.036, ...    % 0.036x + 1.7
           'R_b', 1.7, ...
           'E', 0.25, ...       % Tail energy
           'T', 6.0, ...        % Tail duration
           'M', 0.03, ...       % Maintenance power
           'I_scan', 0, ...     % Scan current
           'color', color2),    % GSM network uses purple
    
    struct('name', 'Wi-Fi', ...
           'R_a', 0.007, ...    % 0.007x + 5.9
           'R_b', 5.9, ...
           'E', 0, ...          % Tail energy is 0
           'T', 0, ...          % Tail duration is 0
           'M', 0.05, ...       % Maintenance power
           'I_scan', 0.100, ... % Scan current 100mA
           'color', color3)     % Wi-Fi network uses orange
};

% Convert power parameters to current parameters
for i = 1:length(networks)
    networks{i}.I_maint = networks{i}.M / V_net;
    networks{i}.I_tail = networks{i}.E / V_net;
    % Assume active current equals tail current
    networks{i}.I_active = networks{i}.E / V_net;
end

% Wi-Fi special handling: Use user-provided current values
% Find the index of Wi-Fi network
for i = 1:length(networks)
    if strcmp(networks{i}.name, 'Wi-Fi')
        wi_fi_idx = i;
        break;
    end
end

if exist('wi_fi_idx', 'var')
    networks{wi_fi_idx}.I_maint = 0.002;   % 2mA
    networks{wi_fi_idx}.I_active = 0.031;  % 31mA
    % I_scan is already set to 0.100 during initialization
end

%% 3) Define state indicator functions
% According to the definitions in images 1, 3, 4, 5
% 1_iface_on: Interface-on indicator function
% 1_tail: Tail state indicator function
% 1_active: Active state indicator function

% Create a simulated time sequence
% Simulate a complete packet transmission cycle
T_total = 30;  % Total time 30 seconds
dt = 0.01;     % Time resolution 0.01 seconds
t = 0:dt:T_total;

% Define state times
% Assume a typical packet transmission process
t_start = 5;        % Transmission start time
t_active = 2;       % Active transmission time
t_tail_3G = 12.5;   % 3G tail time
t_tail_GSM = 6;     % GSM tail time
t_end = T_total;    % Simulation end time

%% 4) Define state indicator functions
% Define interface-on state
iface_on = zeros(size(t));
iface_on(t >= 0 & t <= t_end) = 1;  % Interface on throughout the simulation period

% Define active state
active = zeros(size(t));
active(t >= t_start & t < t_start + t_active) = 1;

% Define 3G tail state
tail_3G = zeros(size(t));
tail_3G(t >= t_start + t_active & t < t_start + t_active + t_tail_3G) = 1;

% Define GSM tail state
tail_GSM = zeros(size(t));
tail_GSM(t >= t_start + t_active & t < t_start + t_active + t_tail_GSM) = 1;

% Wi-Fi has no tail state
tail_WiFi = zeros(size(t));

% Wi-Fi scanning state (simulated additional state)
scan = zeros(size(t));
% Assume one scan before transmission starts
t_scan_start = 2;
t_scan_duration = 0.5;
scan(t >= t_scan_start & t < t_scan_start + t_scan_duration) = 1;

%% 5) Calculate network currents
figure('Position', [100, 100, 1400, 800], 'Color', 'white');

% Store network currents
I_net_3G = zeros(size(t));
I_net_GSM = zeros(size(t));
I_net_WiFi = zeros(size(t));

% Find network indices
for i = 1:length(networks)
    if strcmp(networks{i}.name, '3G')
        net_3G = networks{i};
    elseif strcmp(networks{i}.name, 'GSM')
        net_GSM = networks{i};
    elseif strcmp(networks{i}.name, 'Wi-Fi')
        net_WiFi = networks{i};
    end
end

% 3G network current
I_net_3G = net_3G.I_maint * iface_on + ...
           net_3G.I_tail * tail_3G + ...
           net_3G.I_active * active + ...
           net_3G.I_scan * scan;  % 3G has no scan, this term is 0

% GSM network current
I_net_GSM = net_GSM.I_maint * iface_on + ...
            net_GSM.I_tail * tail_GSM + ...
            net_GSM.I_active * active + ...
            net_GSM.I_scan * scan;  % GSM has no scan, this term is 0

% Wi-Fi network current
I_net_WiFi = net_WiFi.I_maint * iface_on + ...
             net_WiFi.I_active * active + ...
             net_WiFi.I_scan * scan;  % Wi-Fi has scanning

%% 6) Visualization results
% 6.1) Subplot 1: Three-state model formula and parameter display
subplot(3, 3, [1, 2, 3]);
hold on;

% Draw title
text(0.5, 0.9, 'Three-State Network Current Model', ...
    'FontSize', 18, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% Draw core formula (with correct subscript format)
text(0.5, 0.7, 'I_{net}(t) = I_{maint}·1_{iface on}(t) + I_{tail}·1_{tail}(t) + I_{active}·1_{active}(t)', ...
    'FontSize', 16, 'HorizontalAlignment', 'center');

% Add symbol explanations (with correct subscript format)
text(0.5, 0.5, 'I_{maint}: Maintenance current (interface on but idle)', ...
    'FontSize', 12, 'HorizontalAlignment', 'center');
text(0.5, 0.4, 'I_{active}: Active current (data transmission phase)', ...
    'FontSize', 12, 'HorizontalAlignment', 'center');
text(0.5, 0.3, 'I_{tail}: Tail current (high-power retention after transmission)', ...
    'FontSize', 12, 'HorizontalAlignment', 'center');

% Add energy model description (with correct subscript format)
text(0.5, 0.1, 'Energy model: E_{net} = R(x) + E_{tail} + M·t', ...
    'FontSize', 12, 'HorizontalAlignment', 'center');

axis off;

% 6.2) Subplot 2: 3G network current model
subplot(3, 3, 4);
hold on;

% Plot each state component
plot(t, net_3G.I_maint * iface_on, 'LineWidth', 2, 'Color', color_maint, 'DisplayName', 'I_{maint}');
plot(t, net_3G.I_active * active, 'LineWidth', 3, 'Color', color_active, 'DisplayName', 'I_{active}');
plot(t, net_3G.I_tail * tail_3G, 'LineWidth', 2, 'Color', color_tail, 'DisplayName', 'I_{tail}');

% Plot total current
plot(t, I_net_3G, 'LineWidth', 2.5, 'Color', net_3G.color, 'LineStyle', '--', 'DisplayName', 'I_{net}');

xlabel('Time (s)', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('Current (A)', 'FontSize', 10, 'FontWeight', 'bold');
title('3G Network Three-State Current Model', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 8);
grid on;
xlim([0, T_total]);
ylim([0, max(I_net_3G)*1.2]);

% Mark state regions
text(t_start + t_active/2, net_3G.I_active*1.1, 'Active', ...
    'HorizontalAlignment', 'center', 'FontSize', 9, 'BackgroundColor', 'white');
text(t_start + t_active + t_tail_3G/2, net_3G.I_tail*1.1, 'Tail (12.5s)', ...
    'HorizontalAlignment', 'center', 'FontSize', 9, 'BackgroundColor', 'white');

% 6.3) Subplot 3: GSM network current model
subplot(3, 3, 5);
hold on;

% Plot each state component
plot(t, net_GSM.I_maint * iface_on, 'LineWidth', 2, 'Color', color_maint, 'DisplayName', 'I_{maint}');
plot(t, net_GSM.I_active * active, 'LineWidth', 3, 'Color', color_active, 'DisplayName', 'I_{active}');
plot(t, net_GSM.I_tail * tail_GSM, 'LineWidth', 2, 'Color', color_tail, 'DisplayName', 'I_{tail}');

% Plot total current
plot(t, I_net_GSM, 'LineWidth', 2.5, 'Color', net_GSM.color, 'LineStyle', '--', 'DisplayName', 'I_{net}');

xlabel('Time (s)', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('Current (A)', 'FontSize', 10, 'FontWeight', 'bold');
title('GSM Network Three-State Current Model', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 8);
grid on;
xlim([0, T_total]);
ylim([0, max(I_net_GSM)*1.2]);

% Mark state regions
text(t_start + t_active/2, net_GSM.I_active*1.1, 'Active', ...
    'HorizontalAlignment', 'center', 'FontSize', 9, 'BackgroundColor', 'white');
text(t_start + t_active + t_tail_GSM/2, net_GSM.I_tail*1.1, 'Tail (6s)', ...
    'HorizontalAlignment', 'center', 'FontSize', 9, 'BackgroundColor', 'white');

% 6.4) Subplot 4: Wi-Fi network current model
subplot(3, 3, 6);
hold on;

% Plot each state component
plot(t, net_WiFi.I_maint * iface_on, 'LineWidth', 2, 'Color', color_maint, 'DisplayName', 'I_{maint}');
plot(t, net_WiFi.I_active * active, 'LineWidth', 3, 'Color', color_active, 'DisplayName', 'I_{active}');
plot(t, net_WiFi.I_scan * scan, 'LineWidth', 2, 'Color', color_scan, 'DisplayName', 'I_{scan}');

% Plot total current
plot(t, I_net_WiFi, 'LineWidth', 2.5, 'Color', net_WiFi.color, 'LineStyle', '--', 'DisplayName', 'I_{net}');

xlabel('Time (s)', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('Current (A)', 'FontSize', 10, 'FontWeight', 'bold');
title('Wi-Fi Network Three-State Current Model', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 8);
grid on;
xlim([0, T_total]);
ylim([0, max(I_net_WiFi)*1.2]);

% Mark state regions
text(t_start + t_active/2, net_WiFi.I_active*1.1, 'Active', ...
    'HorizontalAlignment', 'center', 'FontSize', 9, 'BackgroundColor', 'white');
text(t_scan_start + t_scan_duration/2, net_WiFi.I_scan*0.9, 'Scan', ...
    'HorizontalAlignment', 'center', 'FontSize', 9, 'BackgroundColor', 'white');

% 6.5) Subplot 5: Comparison of three networks
subplot(3, 3, [7, 8, 9]);
hold on;

plot(t, I_net_3G, 'LineWidth', 2.5, 'Color', net_3G.color, 'DisplayName', '3G Network');
plot(t, I_net_GSM, 'LineWidth', 2.5, 'Color', net_GSM.color, 'DisplayName', 'GSM Network');
plot(t, I_net_WiFi, 'LineWidth', 2.5, 'Color', net_WiFi.color, 'DisplayName', 'Wi-Fi Network');

xlabel('Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Current (A)', 'FontSize', 12, 'FontWeight', 'bold');
title('Comparison of Three Network Interface Currents', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 10);
grid on;
xlim([0, T_total]);

% Mark state regions
fill([t_start, t_start + t_active, t_start + t_active, t_start], ...
     [0, 0, max([I_net_3G, I_net_GSM, I_net_WiFi]), max([I_net_3G, I_net_GSM, I_net_WiFi])], ...
     [0.9, 0.95, 1.0], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
text(t_start + t_active/2, max([I_net_3G, I_net_GSM, I_net_WiFi])*0.9, 'Active Transmission', ...
    'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'white');

% Mark tail region
fill([t_start + t_active, t_start + t_active + t_tail_3G, ...
      t_start + t_active + t_tail_3G, t_start + t_active], ...
     [0, 0, max([I_net_3G, I_net_GSM]), max([I_net_3G, I_net_GSM])], ...
     [1.0, 0.95, 0.9], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
text(t_start + t_active + t_tail_3G/2, max([I_net_3G, I_net_GSM])*0.7, 'Tail State', ...
    'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'white');

%% 7) Calculate energy consumption
% According to the energy model in image 1: E_net = R(x) + E_tail + M·t
fprintf('\n=== Network Energy Model Analysis ===\n\n');

% Assume transmission data volume
x = 50;  % 50KB, based on the description in image 6

for i = 1:length(networks)
    net = networks{i};
    
    % Calculate transmission energy R(x) = a*x + b
    R_x = net.R_a * x + net.R_b;  % Joules
    
    % Calculate active time energy
    t_active_seconds = t_active;  % 2 seconds
    P_active = net.E;  % Active power
    E_active = P_active * t_active_seconds;  % Joules
    
    % Calculate tail energy
    E_tail = net.E * net.T;  % Joules
    
    % Calculate maintenance energy
    t_total = T_total;  % 30 seconds
    M_power = net.M;  % Watts
    E_maintenance = M_power * t_total;  % Joules
    
    % Total energy
    E_total = R_x + E_tail + E_maintenance;
    
    % Convert to Wh
    E_total_Wh = E_total / 3600;
    
    fprintf('%s Network Energy Analysis:\n', net.name);
    fprintf('  Transmission data volume: %.0f KB\n', x);
    fprintf('  Transmission energy R(x): %.3f J\n', R_x);
    fprintf('  Tail energy E_{tail}: %.3f J\n', E_tail);
    fprintf('  Maintenance energy M·t: %.3f J\n', E_maintenance);
    fprintf('  Total energy: %.3f J (%.3f Wh)\n', E_total, E_total_Wh);
    fprintf('  Model formula: E_{net} = R(x) + E_{tail} + M·t = %.3f + %.3f + %.3f\n\n', ...
        R_x, E_tail, E_maintenance);
end

%% 8) Add model description
figure('Position', [100, 100, 1000, 400], 'Color', 'white');

subplot(1, 2, 1);
% Draw state diagram
states = {'iface on', 'active', 'tail'};
state_colors = {color_maint, color_active, color_tail};  % Use state component colors
state_durations = [T_total, t_active, t_tail_3G];

% Calculate start times
start_times = [0, t_start, t_start + t_active];

% Draw state timeline
for i = 1:length(states)
    rectangle('Position', [start_times(i), i-0.4, state_durations(i), 0.8], ...
              'FaceColor', state_colors{i}, 'EdgeColor', 'k', 'LineWidth', 1);
    text(start_times(i) + state_durations(i)/2, i, states{i}, ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 10);
end

xlabel('Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('State', 'FontSize', 12, 'FontWeight', 'bold');
title('Network Interface Three-State Timeline', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
xlim([0, T_total]);
ylim([0.5, 3.5]);
set(gca, 'YTick', 1:3, 'YTickLabel', states);

subplot(1, 2, 2);
% Draw model hierarchy structure
text(0.5, 0.8, 'Energy Model → Power Model → Current Model', ...
    'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% Draw formula hierarchy (with correct subscript format)
text(0.5, 0.6, 'E_{net} = R(x) + E_{tail} + M·t', ...
    'FontSize', 12, 'HorizontalAlignment', 'center');

text(0.5, 0.4, '↓ Convert via P(t) = V_{net}·I(t)', ...
    'FontSize', 10, 'HorizontalAlignment', 'center');

text(0.5, 0.2, 'I_{net}(t) = I_{maint}·1_{iface on}(t) + I_{tail}·1_{tail}(t) + I_{active}·1_{active}(t)', ...
    'FontSize', 10, 'HorizontalAlignment', 'center');

axis off;
title('Model Hierarchy Structure', 'FontSize', 14, 'FontWeight', 'bold');

%% 9) Output summary
fprintf('\n=== Three-State Network Model Summary ===\n\n');
fprintf('Based on the core formulas and parameters from 6 images, this program implements:\n\n');
fprintf('1. Model visualization: Shows each component and total current of the three-state current model\n');
fprintf('2. Network comparison: Compares current characteristics of 3G, GSM, and Wi-Fi networks\n');
fprintf('3. Energy calculation: Computes energy consumption of each network based on the energy model\n');
fprintf('4. State analysis: Shows the state timeline of the network interface\n\n');

fprintf('Key findings:\n');
fprintf('1. 3G network has the longest tail state (12.5s), leading to higher tail energy consumption\n');
fprintf('2. GSM network has a shorter tail state (6s), with relatively lower tail energy consumption\n');
fprintf('3. Wi-Fi network has no tail state, but has high-power scanning state\n');
fprintf('4. Significant differences in active state currents among different networks\n\n');

fprintf('Model applications:\n');
fprintf('This three-state model can be used for:\n');
fprintf('1. Smartphone energy consumption analysis and optimization\n');
fprintf('2. Network protocol design and evaluation\n');
fprintf('3. Battery life prediction\n');
fprintf('4. Network selection strategy formulation\n');

% Save figure
saveas(gcf, 'network_three_state_model.png');
fprintf('\nFigure saved as network_three_state_model.png\n');