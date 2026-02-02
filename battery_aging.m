%% Battery Aging Visualization Based on Mathematical Formulas
% Q_eff(t) = Q_nom * (1 - D(t))
% dSOC/dt = -I(t)/Q_eff(t)

clear; clc; close all;

% Use the specified color scheme
color1 = [0.3, 0.396, 0.6];      % Deep blue series
color2 = [0.54, 0.55, 0.75];     % Purple series
color3 = [0.93, 0.79, 0.45];     % Orange series
color4 = [0.714, 0.463, 0.4];    % Deep orange series

% Create color matrix
color_matrix = [color1; color2; color3; color4];

%% Battery Parameters
Q_nom = 5000;           % Rated capacity (mAh)
I_nominal = 2000;       % Nominal discharge current (mA)
V_nominal = 3.7;        % Nominal voltage (V)
cycles = 0:10:1000;     % Cycle number
time_hours = 0:0.1:5;   % Discharge time (hours)

%% Model 1: Linear Degradation Model Based on Discharge Depth D(t)
% D(t) represents cumulative discharge depth during battery usage
D_max = 0.3;   % Maximum capacity fade of 30%
alpha = 0.0005; % Degradation coefficient

% Calculate effective capacity Q_eff = Q_nom * (1 - D(t))
D_linear = min(D_max, alpha * cycles);  % Linear discharge depth model
Q_eff_linear = Q_nom * (1 - D_linear);

%% Model 2: SOC Calculation Based on Formula dSOC/dt = -I(t)/Q_eff(t)
% Assuming constant current discharge I(t) = I_nominal
SOC_initial = 1;  % Initial SOC is 100%

% Create figure
figure('Position', [100, 100, 1400, 900], 'Color', 'white');

%% Subplot 1: Effective Capacity Degradation Curve
subplot(2, 3, 1);
plot(cycles, Q_eff_linear, 'LineWidth', 2.5, 'Color', color1);
xlabel('Charge-Discharge Cycles');
ylabel('Effective Capacity Q_{eff} (mAh)');
title('Effective Capacity Degradation with Cycle Number');
grid on;

% Add capacity degradation formula
text(0.05, 0.9, '$$Q_{\mathrm{eff}}(n) = Q_{\mathrm{nom}} \cdot (1 - D(n))$$', ...
    'Units', 'normalized', 'Interpreter', 'latex', 'FontSize', 12, ...
    'BackgroundColor', [1 1 1 0.8]);

% Mark critical points
hold on;
plot([0, 1000], [Q_nom*0.8, Q_nom*0.8], '--', 'Color', color4, 'LineWidth', 1);
text(800, Q_nom*0.8+50, '80% Health Threshold', 'Color', color4);

%% Subplot 2: SOC Rate of Change Variation with Aging
subplot(2, 3, 2);
% Calculate SOC rate of change for different cycle numbers
SOC_rate = -I_nominal ./ Q_eff_linear;

plot(cycles, abs(SOC_rate)*100, 'LineWidth', 2.5, 'Color', color2);
xlabel('Charge-Discharge Cycles');
ylabel('|dSOC/dt| (%/h)');
title('Increase of SOC Rate of Change with Aging');
grid on;

% Add SOC rate of change formula
text(0.05, 0.9, '$$\frac{dSOC}{dt} = -\frac{I(t)}{Q_{\mathrm{eff}}(t)}$$', ...
    'Units', 'normalized', 'Interpreter', 'latex', 'FontSize', 12, ...
    'BackgroundColor', [1 1 1 0.8]);

%% Subplot 3: SOC Discharge Curves at Different Aging Stages
subplot(2, 3, 3);
% Select four key aging stages
cycle_points = [0, 250, 500, 750];  % Cycle number points
line_styles = {'-', '--', ':', '-.'};

for i = 1:length(cycle_points)
    % Find the closest cycle point
    [~, idx] = min(abs(cycles - cycle_points(i)));
    Q_current = Q_eff_linear(idx);
    
    % Calculate SOC variation over time (constant current discharge)
    SOC_discharge = SOC_initial - (I_nominal * time_hours) / Q_current;
    SOC_discharge(SOC_discharge < 0) = 0;  % SOC cannot be negative
    
    plot(time_hours, SOC_discharge*100, 'LineWidth', 2, ...
        'Color', color_matrix(i, :), 'LineStyle', line_styles{i});
    hold on;
end

xlabel('Discharge Time (hours)');
ylabel('SOC (%)');
title('SOC Discharge Curves at Different Aging Stages');
grid on;
legend_str = cell(1, length(cycle_points));
for i = 1:length(cycle_points)
    [~, idx] = min(abs(cycles - cycle_points(i)));
    legend_str{i} = sprintf('%d cycles (Q_{eff}=%.0f mAh)', ...
        cycle_points(i), Q_eff_linear(idx));
end
legend(legend_str, 'Location', 'southwest');

%% Subplot 4: Impact of Aging on Discharge Time (Bar Chart)
subplot(2, 3, 4);
% Calculate full discharge time for different aging levels
discharge_time = Q_eff_linear ./ I_nominal;

% Select several key points
analysis_points = [0, 200, 400, 600, 800, 1000];
time_values = zeros(size(analysis_points));
capacity_values = zeros(size(analysis_points));

for i = 1:length(analysis_points)
    [~, idx] = min(abs(cycles - analysis_points(i)));
    time_values(i) = discharge_time(idx);
    capacity_values(i) = Q_eff_linear(idx);
end

% Create dual y-axis plot
yyaxis left;
bar(1:length(analysis_points), capacity_values, 'FaceColor', color1, 'FaceAlpha', 0.7);
ylabel('Effective Capacity Q_{eff} (mAh)');

yyaxis right;
plot(1:length(analysis_points), time_values, 'o-', 'LineWidth', 2, ...
    'Color', color3, 'MarkerSize', 8, 'MarkerFaceColor', color3);
ylabel('Full Discharge Time (hours)');

set(gca, 'XTick', 1:length(analysis_points), ...
    'XTickLabel', arrayfun(@(x) sprintf('%d cycles', x), analysis_points, 'UniformOutput', false));
xlabel('Cycle Number');
%title('Impact of Aging on Capacity and Discharge Time');
grid on;
legend('Effective Capacity', 'Discharge Time', 'Location', 'northeast');

%% Subplot 5: Relationship Between Capacity Fade and SOC Rate of Change (Scatter Plot)
subplot(2, 3, 5);
% Calculate capacity fade percentage
capacity_decline = 100 * (Q_nom - Q_eff_linear) / Q_nom;

% Calculate relative change in SOC rate of change
SOC_rate_relative = 100 * (abs(SOC_rate) - abs(SOC_rate(1))) / abs(SOC_rate(1));

% Create scatter plot
scatter(cycles, capacity_decline, 30, 'filled', ...
    'MarkerFaceColor', color2, 'MarkerEdgeColor', 'k');
hold on;

% Add trend line
p = polyfit(cycles, capacity_decline, 1);
trend_line = polyval(p, cycles);
plot(cycles, trend_line, '--', 'Color', color4, 'LineWidth', 2);

xlabel('Cycle Number');
ylabel('Capacity Fade (%)');
title('Capacity Fade Trend');
grid on;

% Add formula relationship description
text(0.05, 0.9, {'Capacity fade leads to:', '1. Q_{eff}↓', '2. |dSOC/dt|↑'}, ...
    'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', [1 1 1 0.8]);

%% Subplot 6: 3D Surface Plot - Relationship Between Cycle Number, Discharge Current, and SOC Rate of Change
subplot(2, 3, 6);
% Create grid
[Cycle_grid, I_grid] = meshgrid(linspace(0, 1000, 50), linspace(1000, 3000, 50));

% Calculate effective capacity based on current model
% Using simplified model: Q_eff = Q_nom * exp(-0.0005 * Cycle_grid)
Q_eff_grid = Q_nom * exp(-0.0005 * Cycle_grid);

% Calculate SOC rate of change
SOC_rate_grid = -I_grid ./ Q_eff_grid;

% Create 3D surface plot
surf(Cycle_grid, I_grid, abs(SOC_rate_grid)*100, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
colormap(jet);
xlabel('Cycle Number');
ylabel('Discharge Current I(t) (mA)');
zlabel('dSOC/dt(%/h)');
%title('3D Relationship of SOC Rate of Change');
view(30, 30);
grid on;
colorbar;

%% Add Overall Title and Description
sgtitle('Battery Aging Visualization Based on Formulas Q_{eff}(t)=Q_{nom}(1-D(t)) and dSOC/dt=-I(t)/Q_{eff}(t)', ...
    'FontSize', 14, 'FontWeight', 'bold');


%% Create Second Figure: Impact of Aging on Practical Usage
figure('Position', [100, 100, 1200, 800], 'Color', 'white');

% Simulate different usage scenarios
usage_scenarios = {'Standby', 'Text Processing', 'Web Browsing', 'Video Playback', 'Gaming'};
power_levels = [100, 300, 500, 800, 1500];  % Power consumption for different usage scenarios (mW)

% Calculate effective capacity at different aging stages
aging_stages = [0, 0.2, 0.4, 0.6, 0.8, 1.0];  % Aging level (0-1)
Q_eff_stages = Q_nom * (1 - aging_stages * 0.3);  % Maximum fade of 30%

% Calculate endurance time (hours)
endurance_matrix = zeros(length(aging_stages), length(usage_scenarios));

for i = 1:length(aging_stages)
    for j = 1:length(usage_scenarios)
        % Convert to current (mA)
        current = power_levels(j) / V_nominal;
        endurance_matrix(i, j) = Q_eff_stages(i) / current;
    end
end

% Create grouped bar chart
subplot(1, 2, 1);
h = bar(endurance_matrix, 'grouped');

% Set colors
for k = 1:length(h)
    h(k).FaceColor = color_matrix(k, :);
end

set(gca, 'XTickLabel', {'0%', '6%', '12%', '18%', '24%', '30%'});
xlabel('Capacity Fade Percentage');
ylabel('Endurance Time (hours)');
title('Endurance Comparison Across Usage Scenarios at Different Aging Levels');
legend(usage_scenarios, 'Location', 'northeastoutside');
grid on;

% Add data labels
for i = 1:size(endurance_matrix, 1)
    for j = 1:size(endurance_matrix, 2)
        text(i, endurance_matrix(i, j) + 0.5, ...
            sprintf('%.1f', endurance_matrix(i, j)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8);
    end
end

% Plot impact of aging on SOC curve slope
subplot(1, 2, 2);
% Select three aging levels
selected_stages = [1, 3, 5];  % 0%, 12%, 24% fade
line_styles = {'-', '--', ':'};
marker_symbols = {'o', 's', '^'};

for i = 1:length(selected_stages)
    stage_idx = selected_stages(i);
    Q_current = Q_eff_stages(stage_idx);
    
    % Calculate SOC variation over time
    SOC_curve = SOC_initial - (I_nominal * time_hours) / Q_current;
    SOC_curve(SOC_curve < 0) = 0;
    
    % Calculate slope (dSOC/dt)
    slope = -I_nominal / Q_current * 100;  % Convert to %/h
    
    plot(time_hours, SOC_curve*100, ...
        'LineWidth', 2, 'LineStyle', line_styles{i}, ...
        'Color', color_matrix(i, :), ...
        'Marker', marker_symbols{i}, 'MarkerSize', 6, ...
        'MarkerIndices', 1:10:length(time_hours));
    hold on;
    
    % Add slope annotation
    text(0.5, 100 - i*15, sprintf('%.0f%% fade: dSOC/dt = %.1f%%/h', ...
        aging_stages(stage_idx)*30, slope), ...
        'Color', color_matrix(i, :), 'FontSize', 10);
end

xlabel('Discharge Time (hours)');
ylabel('SOC (%)');
title('Comparison of SOC Curve Slopes at Different Aging Levels');
grid on;
legend({'0% fade', '12% fade', '24% fade'}, 'Location', 'southwest');

sgtitle('Impact of Battery Aging on Practical Usage', 'FontSize', 14, 'FontWeight', 'bold');

