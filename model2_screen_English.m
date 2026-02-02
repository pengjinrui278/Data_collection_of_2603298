% ============================================
% Smartphone Battery Model - Analysis of Screen Power Consumption Impact on SOC
% Based on NASA B0005 Dataset
% Modified: Using specified color scheme, adjusting subplot layout
% ============================================

clear; close all; clc;

% Define four color combinations
color1 = [0.3, 0.396, 0.6];    % Deep blue
color2 = [0.54, 0.55, 0.75];   % Purple
color3 = [0.93, 0.79, 0.45];   % Orange
color4 = [0.714, 0.463, 0.4];  % Deep orange

%% 1) Load B0005.mat (default desktop)
if ispc
    desktopPath = fullfile(getenv('USERPROFILE'), 'Desktop');
else
    desktopPath = fullfile(getenv('HOME'), 'Desktop');
end
b0005_path = fullfile(desktopPath, 'B0005.mat');
assert(exist(b0005_path,'file')==2, 'File not found: %s', b0005_path);

data = load(b0005_path);
vars = fieldnames(data);
if ismember('B0005', vars)
    B0005 = data.B0005;
else
    B0005 = data.(vars{1});
end
assert(isfield(B0005,'cycle'), 'B0005 does not contain cycle field');

%% 2) Find the first discharge cycle
discharge_cycles = [];
for i = 1:length(B0005.cycle)
    if isfield(B0005.cycle(i),'type') && strcmp(B0005.cycle(i).type,'discharge')
        discharge_cycles(end+1) = i; %#ok<AGROW>
    end
end
if isempty(discharge_cycles)
    warning('No discharge cycle found, using first cycle');
    cycle_idx = 1;
else
    cycle_idx = discharge_cycles(1);
end
fprintf('Using cycle %d\n', cycle_idx);

cycle_data = B0005.cycle(cycle_idx);
assert(isfield(cycle_data,'data'), 'cycle_data does not contain data field');
d = cycle_data.data;

%% 3) Extract time, voltage, current, temperature
% Time
if isfield(d,'Time')
    time_sec = d.Time;
elseif isfield(d,'time')
    time_sec = d.time;
else
    error('Time/time field not found. Available fields: %s', strjoin(fieldnames(d),', '));
end

% Voltage
assert(isfield(d,'Voltage_measured'), 'Missing Voltage_measured field');
voltage = d.Voltage_measured;

% Current
assert(isfield(d,'Current_measured'), 'Missing Current_measured field');
current_measured = d.Current_measured;

% Temperature (optional)
temperature = [];
if isfield(d,'Temperature_measured')
    temperature = d.Temperature_measured;
end

% Convert to column vectors
time_sec = time_sec(:);
voltage  = voltage(:);
current_measured = current_measured(:);
if ~isempty(temperature), temperature = temperature(:); end

n = length(time_sec);
assert(length(voltage)==n && length(current_measured)==n, 'Time/Voltage/Current length mismatch');

% Time (hours)
time_hours = time_sec / 3600;

% Clean: ensure strictly increasing time
[time_hours, order] = sort(time_hours, 'ascend');
time_sec = time_sec(order);
voltage = voltage(order);
current_measured = current_measured(order);
if ~isempty(temperature), temperature = temperature(order); end

%% 4) Define screen usage scenarios
% Based on provided screen power consumption data
screen_scenarios = {
    struct('name', 'Screen Off', 'current', 0.0);    % 0A
    struct('name', 'Screen Minimum Brightness', 'current', 0.2); % 200mA = 0.2A
    struct('name', 'Screen Maximum Brightness', 'current', 0.4); % 400mA = 0.4A (middle value of 100-300mA)
};

fprintf('Screen usage scenarios defined:\n');
for i = 1:length(screen_scenarios)
    fprintf('  %s: %.1f mA\n', screen_scenarios{i}.name, screen_scenarios{i}.current*1000);
end

%% 5) Basic current processing
% Raw discharge current (positive)
I_base = max(0, -current_measured);  % A, discharge positive
fprintf('Basic discharge current range: [%.4f, %.4f] A\n', min(I_base), max(I_base));

%% 6) Calculate nominal capacity Q_nom (screen off scenario)
dt = [0; diff(time_sec)];
Q_discharged_base = cumsum(I_base .* dt) / 3600; % Ah
Q_nom = Q_discharged_base(end);
assert(Q_nom > 1e-6, 'Q_nom too small, current or time data abnormal');
fprintf('Battery nominal capacity Q_nom = %.4f Ah\n', Q_nom);

%% 7) Create 2x2 layout chart
figure('Position',[100,100,1200,800],'Color','white');

% Store results for each scenario
results = struct();

%% 7.1) First subplot: Impact of screen usage on SOC
subplot(2,2,[1,2]); % Occupies two positions in first row

% Assign colors to three scenarios
scenario_colors = [color1; color2; color3];

for scenario_idx = 1:length(screen_scenarios)
    scenario = screen_scenarios{scenario_idx};
    fprintf('\n=== Analyzing scenario: %s ===\n', scenario.name);
    
    % Total current = base current + screen current
    I_total = I_base + scenario.current;
    fprintf('Total discharge current range: [%.4f, %.4f] A\n', min(I_total), max(I_total));
    
    % Calculate measured SOC (Coulomb counting)
    Q_discharged = cumsum(I_total .* dt) / 3600;
    SOC_measured = 1 - Q_discharged / Q_nom;
    SOC_measured = max(0, min(1, SOC_measured));
    SOC0 = SOC_measured(1);
    
    % Solve differential equation
    t_span = [time_hours(1), time_hours(end)];
    options = odeset('RelTol',1e-6,'AbsTol',1e-9);
    
    ode_fun = @(t, SOC) battery_ode_screen(t, SOC, time_hours, I_total, Q_nom);
    [t, SOC_pred] = ode45(ode_fun, t_span, SOC0, options);
    
    % Calculate discharge time (time to SOC drops to 5%)
    soc_threshold = 0.05; % 5%
    [~, idx] = min(abs(SOC_pred - soc_threshold));
    discharge_time = t(idx);
    
    % Store results
    results(scenario_idx).name = scenario.name;
    results(scenario_idx).SOC_pred = SOC_pred;
    results(scenario_idx).t = t;
    results(scenario_idx).discharge_time = discharge_time;
    results(scenario_idx).current = scenario.current;
    
    fprintf('Time for SOC to drop from %.0f%% to %.0f%%: %.2f hours\n', ...
        SOC0 * 100, soc_threshold*100, discharge_time);
    
    % Plot SOC curve
    plot(t, SOC_pred*100, 'LineWidth', 3, 'Color', scenario_colors(scenario_idx,:)); 
    hold on;
end

% Chart beautification
grid on;
xlabel('Time (hours)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('SOC (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Impact of Screen Usage on Battery SOC', 'FontSize', 14, 'FontWeight', 'bold');

% Add legend
legend_names = cell(1, length(screen_scenarios));
for i = 1:length(screen_scenarios)
    legend_names{i} = sprintf('%s (%.0fmA)', screen_scenarios{i}.name, screen_scenarios{i}.current*1000);
end
legend(legend_names, 'Location', 'northeast', 'FontSize', 10);

% Add grid and annotations
xlim([0, max(t)]);
ylim([0, 100]);

% Add key information annotation
text(0.02, 0.98, sprintf('Battery capacity: %.2f Ah', Q_nom), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'FontSize', 10, 'BackgroundColor', 'white');

%% 7.2) Second subplot: Screen brightness vs. power consumption rate
subplot(2,2,3); % Bottom left subplot

% Define brightness levels (0-100%)
brightness_levels = 0:5:100; % From 0% to 100%, 5% increments

% Build model based on provided screen power consumption data
% Minimum brightness (0%): 200mA, maximum brightness (100%): 400mA
% Assume linear relationship: I_screen = 0.2 + 0.2 * (brightness/100)
screen_currents = 0.2 + 0.2 * (brightness_levels / 100); % A

% Calculate corresponding power consumption (assuming average voltage 3.7V)
avg_voltage = 3.7; % V
power_consumption = screen_currents * avg_voltage; % W

% Plot screen current vs. brightness
yyaxis left;
plot(brightness_levels, screen_currents*1000, 'LineWidth', 3, 'Color', color1);
ylabel('Screen Current (mA)', 'FontSize', 10, 'FontWeight', 'bold');
ylim([150, 450]); % Set according to data range

% Plot power consumption vs. brightness
yyaxis right;
plot(brightness_levels, power_consumption, 'LineWidth', 2, 'Color', color4, 'LineStyle', '--');
ylabel('Screen Power (W)', 'FontSize', 10, 'FontWeight', 'bold');
ylim([0.5, 1.5]); % Set according to calculated range

grid on;
xlabel('Screen Brightness (%)', 'FontSize', 10, 'FontWeight', 'bold');
title('Screen Brightness vs. Power Consumption Rate', 'FontSize', 12, 'FontWeight', 'bold');

% Add legend
legend('Screen Current', 'Screen Power', 'Location', 'northwest', 'FontSize', 9);

% Mark key points
hold on;
brightness_points = [0, 50, 100];
current_points = 0.2 + 0.2 * (brightness_points / 100);
power_points = current_points * avg_voltage;

for i = 1:length(brightness_points)
    text(brightness_points(i), current_points(i)*1000+10, ...
        sprintf('%.0fmA', current_points(i)*1000), ...
        'HorizontalAlignment', 'center', 'FontSize', 8);
    text(brightness_points(i), power_points(i)-0.05, ...
        sprintf('%.2fW', power_points(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 8);
end

%% 7.3) Third subplot: Impact of screen power consumption on battery life
subplot(2,2,4); % Bottom right subplot

% Extract battery life for each scenario
scenario_names = {results.name};
discharge_times = [results.discharge_time];
screen_currents_plot = [results.current]*1000; % Convert to mA

% Create bar chart
bar(1:length(discharge_times), discharge_times, 'FaceColor', color2, 'EdgeColor', 'k');

% Calculate appropriate y-axis range
max_time = max(discharge_times);
y_max = max_time * 1.2; % Increase 20% space to ensure text doesn't block title
ylim([0, y_max]);

% Add value labels
for i = 1:length(discharge_times)
    text(i, discharge_times(i) + 0.02 * y_max, sprintf('%.2f hours', discharge_times(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
end

% Set x-axis labels
xticks(1:length(scenario_names));
xticklabels(scenario_names);
xtickangle(45); % Tilt labels to avoid overlap

ylabel('Battery Life (hours)', 'FontSize', 10, 'FontWeight', 'bold');
title('Impact of Screen Settings on Battery Life', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% Add screen current information
text(0.5, 0.9, sprintf('Screen Current: %.0f/%.0f/%.0f mA', screen_currents_plot), ...
    'Units', 'normalized', 'FontSize', 9, 'BackgroundColor', 'white');

%% 8) Output detailed analysis results
fprintf('\n\n=== Analysis of Screen Usage Impact on Battery Life ===\n');
fprintf('Baseline scenario (screen off) discharge time: %.2f hours\n', results(1).discharge_time);

for i = 2:length(results)
    time_reduction = results(1).discharge_time - results(i).discharge_time;
    reduction_percent = (time_reduction / results(1).discharge_time) * 100;
    
    fprintf('\n%s impact analysis:\n', results(i).name);
    fprintf('  Discharge time: %.2f hours\n', results(i).discharge_time);
    fprintf('  Time reduction: %.2f hours (%.1f%%)\n', time_reduction, reduction_percent);
    fprintf('  Screen current: %.0f mA\n', results(i).current*1000);
end

% Calculate quantitative relationship between screen brightness and battery life
fprintf('\n=== Quantitative Relationship: Screen Brightness vs. Battery Life ===\n');
brightness_test = [0, 25, 50, 75, 100]; % Test several brightness levels
for brightness = brightness_test
    screen_current = 0.2 + 0.2 * (brightness / 100);
    % Simplified estimation: battery life inversely proportional to total current
    avg_base_current = mean(I_base);
    total_current = avg_base_current + screen_current;
    estimated_time = results(1).discharge_time * (avg_base_current / total_current);
    
    fprintf('Brightness %.0f%%: Screen current=%.0fmA, Estimated battery life=%.2f hours\n', ...
        brightness, screen_current*1000, estimated_time);
end

fprintf('\nConclusion:\n');
fprintf('Screen usage significantly affects battery life.\n');
max_reduction = (results(1).discharge_time - results(3).discharge_time) / results(1).discharge_time * 100;
fprintf('Maximum brightness screen usage can reduce battery life by approximately %.1f%%.\n', max_reduction);

%% ===== Local function: Battery equation including screen current =====
function dSOC_dt = battery_ode_screen(t, SOC, time_hours, I_total_data, Q_nom)
    % Modified battery equation: includes screen current impact
    % dSOC/dt = -I_total(t) / Q_nom
    % I_total(t) = I_base(t) + I_screen
    I_t = interp1(time_hours, I_total_data, t, 'linear', 'extrap');
    dSOC_dt = -I_t / Q_nom;
end