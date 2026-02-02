% ============================================================
% Analysis of GPS Impact on Smartphone Battery Power Consumption
% Based on GPS power consumption model formulas and data from two images
% Corrected version: Fixed syntax errors, using proper parentheses
% ============================================================

clear; close all; clc;

%% Set color scheme (blue-purple palette)
color1 = [0.3, 0.396, 0.6];       % Dark blue - Single-frequency phone
color2 = [0.54, 0.55, 0.75];      % Purple - Dual-frequency phone
color_bg = [0.95, 0.95, 0.95];    % Background color
color_text = [0.1, 0.1, 0.1];     % Text color

%% 1) GPS Power Consumption Model Based on Image Data
fprintf('=== GPS Power Consumption Model (Based on Image Data) ===\n\n');
fprintf('Core formula: P_GPS(t) = E_fix × r(t)\n\n');
fprintf('Parameter values:\n');
fprintf('  Single-frequency phone: E_fix ≈ 0.232 J/fix (±20 mJ)\n');
fprintf('  Dual-frequency phone: E_fix ≈ 0.318 J/fix (±32 mJ)\n\n');

% Model parameters
E_fix_single = 0.232;  % Single-frequency phone
E_fix_dual = 0.318;    % Dual-frequency phone
V_batt = 3.7;          % Battery voltage
battery_capacity_J = 29000; % Total battery energy

%% 2) Simulation of Different Usage Scenarios
% Time parameters
T_total = 24 * 3600;  % 24 hours
dt = 60;              % 1-minute resolution
t = 0:dt:T_total;
n = length(t);

% Define usage scenarios
usage_scenario = [
    0, 6 * 3600,   0.01;   % 0:00-6:00: Background mode
    6 * 3600, 8 * 3600,   0.2;    % 6:00-8:00: Motion mode
    8 * 3600, 9 * 3600,   1.0;    % 8:00-9:00: Navigation mode
    9 * 3600, 12 * 3600,  0.01;   % 9:00-12:00: Background mode
    12 * 3600, 13 * 3600, 1.0;    % 12:00-13:00: Navigation mode
    13 * 3600, 18 * 3600, 0.01;   % 13:00-18:00: Background mode
    18 * 3600, 19 * 3600, 1.0;    % 18:00-19:00: Navigation mode
    19 * 3600, 20 * 3600, 0.2;    % 19:00-20:00: Motion mode
    20 * 3600, 24 * 3600, 0.01;   % 20:00-24:00: Background mode
];

% Generate frequency data
r = zeros(size(t));
for i = 1:size(usage_scenario, 1)
    idx = (t >= usage_scenario(i,1)) & (t < usage_scenario(i,2));
    r(idx) = usage_scenario(i,3) + 0.1*usage_scenario(i,3)*randn(sum(idx),1)';
end

% Calculate power consumption
P_single = E_fix_single * r;
P_dual = E_fix_dual * r;

% Calculate energy consumption and SOC
E_single = cumtrapz(t, P_single);
E_dual = cumtrapz(t, P_dual);
SOC_single = 1 - E_single / battery_capacity_J;
SOC_dual = 1 - E_dual / battery_capacity_J;

% Ensure SOC doesn't go negative
SOC_single = max(SOC_single, 0);
SOC_dual = max(SOC_dual, 0);

%% 3) Create Optimized Figure (2×2 Layout)
figure('Position', [100, 100, 1000, 800], 'Color', 'white');

% 3.1) Subplot 1: 24-hour Power Curve Comparison
subplot(2, 2, 1);
hold on; 
grid on;

% Plot power curves
h1 = plot(t/3600, P_single*1000, '-', 'Color', color1, 'LineWidth', 2.5);
h2 = plot(t/3600, P_dual*1000, '-', 'Color', color2, 'LineWidth', 2.5);

% Add usage mode background colors
mode_colors = [0.9,0.9,0.9; 0.8,0.9,0.8; 0.9,0.8,0.8];
mode_names = {'Background', 'Motion', 'Navigation'};
freq_values = [0.01, 0.2, 1.0];

for i = 1:size(usage_scenario, 1)
    t_start = usage_scenario(i,1)/3600;
    t_end = usage_scenario(i,2)/3600;
    freq_val = usage_scenario(i,3);
    
    % Find corresponding mode
    mode_idx = find(abs(freq_values - freq_val) < 0.001);
    if ~isempty(mode_idx)
        mode_idx = mode_idx(1);
        fill([t_start, t_end, t_end, t_start], ...
             [0, 0, max(P_dual)*1000 * 1.1, max(P_dual)*1000 * 1.1], ...
             mode_colors(mode_idx,:), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    end
end

xlabel('Time (hours)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('GPS Power (mW)', 'FontSize', 12, 'FontWeight', 'bold');
title('24-hour GPS Power Consumption Curve', 'FontSize', 14, 'FontWeight', 'bold');
legend([h1, h2], {'Single-frequency', 'Dual-frequency'}, 'Location', 'northeast');
xlim([0, 24]);

% Add average power annotation
text(18, mean(P_single)*1000 * 0.8, sprintf('Single: %.1f mW', mean(P_single)*1000), ...
    'Color', color1, 'FontSize', 10, 'BackgroundColor', 'white', 'FontWeight', 'bold');
text(18, mean(P_dual)*1000 * 1.2, sprintf('Dual: %.1f mW', mean(P_dual)*1000), ...
    'Color', color2, 'FontSize', 10, 'BackgroundColor', 'white', 'FontWeight', 'bold');

% 3.2) Subplot 2: Average Power Comparison Across Scenarios
subplot(2, 2, 2);
hold on; 
grid on;

% Calculate average power for each scenario
scenes = {'Background', 'Motion', 'Navigation'};
scene_power_single = zeros(3,1);
scene_power_dual = zeros(3,1);

for scene = 1:3
    freq = freq_values(scene);
    scene_idx = find(abs(r - freq) < 0.05);
    if ~isempty(scene_idx)
        scene_power_single(scene) = mean(P_single(scene_idx)) * 1000;
        scene_power_dual(scene) = mean(P_dual(scene_idx)) * 1000;
    end
end

% Plot grouped bar chart
x = 1:3;
bar_width = 0.35;
b1 = bar(x - bar_width/2, scene_power_single, bar_width, ...
    'FaceColor', color1, 'EdgeColor', 'k', 'LineWidth', 1);
b2 = bar(x + bar_width/2, scene_power_dual, bar_width, ...
    'FaceColor', color2, 'EdgeColor', 'k', 'LineWidth', 1);

xlabel('Application Scenario', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Average Power (mW)', 'FontSize', 12, 'FontWeight', 'bold');
title('GPS Power Consumption Across Scenarios', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTick', x, 'XTickLabel', scenes);
legend([b1, b2], {'Single-frequency', 'Dual-frequency'}, 'Location', 'northwest');

% Adjust value label positions
for i = 1:3
    text(x(i)-bar_width/2, scene_power_single(i)+15, ...
        sprintf('%.1f', scene_power_single(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    text(x(i)+bar_width/2, scene_power_dual(i)+15, ...
        sprintf('%.1f', scene_power_dual(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
end

% Adjust Y-axis range for better label visibility
ylim([0, max([scene_power_single; scene_power_dual])*1.3]);

% 3.3) Subplot 3: Power-Frequency Relationship
subplot(2,2, 3);
hold on; 
grid on;

% Theoretical relationship curves
r_range = logspace(-2, 0, 100);
P_theory_single = E_fix_single * r_range * 1000;
P_theory_dual = E_fix_dual * r_range * 1000;

plot(r_range, P_theory_single, '-', 'Color', color1, 'LineWidth', 2);
plot(r_range, P_theory_dual, '-', 'Color', color2, 'LineWidth', 2);

% Mark typical frequency points
for i = 1:length(freq_values)
    P_single_point = E_fix_single * freq_values(i) * 1000;
    P_dual_point = E_fix_dual * freq_values(i) * 1000;
    
    scatter(freq_values(i), P_single_point, 100, 'o', ...
        'MarkerFaceColor', color1, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    scatter(freq_values(i), P_dual_point, 100, 's', ...
        'MarkerFaceColor', color2, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
end

xlabel('Update Frequency (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('GPS Power (mW)', 'FontSize', 12, 'FontWeight', 'bold');
title('Power-Frequency Relationship: P = E_{fix} × r', 'FontSize', 14, 'FontWeight', 'bold');
legend({'Single-frequency', 'Dual-frequency'}, 'Location', 'northwest');
set(gca, 'XScale', 'log');

% Add formula annotation
text(0.03, 250, 'P_{GPS} = E_{fix} \times r', ...
    'FontSize', 12, 'BackgroundColor', 'white', 'FontWeight', 'bold', ...
    'EdgeColor', 'k');

% 3.4) Subplot 4: Battery SOC Changes - Optimized Layout
subplot(2, 2, 4);
hold on; 
grid on;

% Plot SOC curves
h_soc1 = plot(t/3600, SOC_single*100, '-', 'Color', color1, 'LineWidth', 2.5);
h_soc2 = plot(t/3600, SOC_dual*100, '-', 'Color', color2, 'LineWidth', 2.5);

xlabel('Time (hours)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Battery State of Charge (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('GPS Impact on Battery Charge Level', 'FontSize', 14, 'FontWeight', 'bold');
legend([h_soc1, h_soc2], {'Single-frequency', 'Dual-frequency'}, 'Location', 'southwest');
xlim([0, 24]);

% Fix: Correctly calculate minimum SOC
min_soc_single = min(SOC_single);
min_soc_dual = min(SOC_dual);
min_soc_value = min(min_soc_single, min_soc_dual) * 100;
ylim([max(min_soc_value-2, 0), 101]); % Leave space for annotations

% Rearrange annotation positions to avoid overlap
SOC_24h_single = SOC_single(end)*100;
SOC_24h_dual = SOC_dual(end)*100;
E_total_single = E_single(end);
E_total_dual = E_dual(end);

% Calculate curve slopes for annotation positioning
if length(SOC_single) > 10
    slope_single = (SOC_single(end-10)*100 - SOC_24h_single) / (t(end-10)/3600 - 24);
    slope_dual = (SOC_dual(end-10)*100 - SOC_24h_dual) / (t(end-10)/3600 - 24);
else
    slope_single = 0;
    slope_dual = 0;
end

% Adjust annotation positions based on curve slopes
if slope_single < slope_dual
    % Single-frequency curve is above
    text_single_y = SOC_24h_single + 3;
    text_dual_y = SOC_24h_dual - 3;
else
    % Dual-frequency curve is above
    text_single_y = SOC_24h_single - 3;
    text_dual_y = SOC_24h_dual + 3;
end

% Add 24-hour SOC annotations
text(22, text_single_y, sprintf('After 24h: %.1f%%', SOC_24h_single), ...
    'Color', color1, 'FontSize', 10, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
    'BackgroundColor', [1,1,1,0.8], 'EdgeColor', color1, 'Margin', 2);

text(22, text_dual_y, sprintf('After 24h: %.1f%%', SOC_24h_dual), ...
    'Color', color2, 'FontSize', 10, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
    'BackgroundColor', [1,1,1,0.8], 'EdgeColor', color2, 'Margin', 2);

% Add power consumption statistics
text(2, 95, sprintf('24h Total Energy:\nSingle: %.0f J\nDual: %.0f J', ...
    E_total_single, E_total_dual), ...
    'FontSize', 9, 'BackgroundColor', [1,1,1,0.9], 'EdgeColor', 'k', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
    'Margin', 3);

% Add battery capacity information
text(2, 85, sprintf('Battery Capacity: %.0f J\n(~%.0f mAh)', ...
    battery_capacity_J, battery_capacity_J/(V_batt*3.6)), ...
    'FontSize', 8, 'BackgroundColor', [0.95,0.95,0.95], ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
    'EdgeColor', [0.7,0.7,0.7], 'Margin', 2);

%% 4) Calculation Results
fprintf('=== Calculation Results ===\n\n');
fprintf('GPS power model: P_GPS(t) = E_fix × r(t)\n');
fprintf('  Single-frequency: E_fix = %.3f J/fix\n', E_fix_single);
fprintf('  Dual-frequency: E_fix = %.3f J/fix\n\n', E_fix_dual);

fprintf('24-hour average power:\n');
fprintf('  Single-frequency: %.1f mW\n', mean(P_single)*1000);
fprintf('  Dual-frequency: %.1f mW\n', mean(P_dual)*1000);
fprintf('  Power increase: %.1f%%\n\n', (mean(P_dual)/mean(P_single)-1)*100);

fprintf('24-hour total energy consumption:\n');
fprintf('  Single-frequency: %.0f J\n', E_total_single);
fprintf('  Dual-frequency: %.0f J\n', E_total_dual);
fprintf('  Percentage of battery capacity: %.1f%% vs %.1f%%\n\n', ...
    E_total_single/battery_capacity_J*100, E_total_dual/battery_capacity_J*100);

fprintf('Remaining battery after 24 hours:\n');
fprintf('  Single-frequency: %.1f%%\n', SOC_24h_single);
fprintf('  Dual-frequency: %.1f%%\n', SOC_24h_dual);

%% 5) Save Results
% Save figure
saveas(gcf, 'GPS_Power_Analysis_Optimized.png');
fprintf('\nFigure saved as: GPS_Power_Analysis_Optimized.png\n');

% Save data
results = struct();
results.time_hours = t/3600;
results.r_Hz = r;
results.P_single_mW = P_single * 1000;
results.P_dual_mW = P_dual * 1000;
results.SOC_single_percent = SOC_single * 100;
results.SOC_dual_percent = SOC_dual * 100;
results.parameters.E_fix_single_J = E_fix_single;
results.parameters.E_fix_dual_J = E_fix_dual;
results.parameters.battery_capacity_J = battery_capacity_J;
results.usage_scenario = usage_scenario;

save('GPS_analysis_results.mat', 'results');
fprintf('Data saved as: GPS_analysis_results.mat\n');

fprintf('\n=== Program Execution Complete ===\n');