% ============================================================
% GPU Power Consumption Analysis for Smartphone Battery Life
% Based on GPU power consumption model from referenced images
% Model: P_GPU = β_GPU_freq(F_GPU) * U_GPU + β_GPU_on * S_GPU_on/off
% ============================================================

clear; close all; clc;

%% Color Scheme Definition
color1 = [0.3, 0.396, 0.6];      % Deep blue
color2 = [0.54, 0.55, 0.75];     % Purple
color3 = [0.93, 0.79, 0.45];     % Orange
color4 = [0.714, 0.463, 0.4];    % Deep orange

%% 1) GPU Power Model Parameters (based on Image 2)
fprintf('=== GPU Power Model (based on Images 1 and 2) ===\n\n');
fprintf('Core equation (from Image 1):\n');
fprintf('P_GPU = β_GPU_freq(F_GPU) * U_GPU + β_GPU_on * S_GPU_on/off\n\n');
fprintf('Parameter values (from Image 2):\n');
fprintf('GPU frequency points: 128 MHz, 200 MHz, 325 MHz, 400 MHz\n\n');
fprintf('Fitted coefficients (Table 1):\n');
fprintf('  β_GPU_freq,128 = 2.5 mW/%%\n');
fprintf('  β_GPU_freq,200 = 5.5 mW/%%\n');
fprintf('  β_GPU_freq,325 = 7.5 mW/%%\n');
fprintf('  β_GPU_freq,400 = 12.6 mW/%%\n');
fprintf('  β_GPU_on = 90.8 mW\n\n');

% Model parameters
freq_list = [128, 200, 325, 400];  % GPU frequency points (MHz)
beta_freq_list = [2.5, 5.5, 7.5, 12.6];  % β_GPU_freq values
beta_on = 90.8;  % β_GPU_on (mW)

% Battery parameters
battery_capacity_mAh = 3000;  % Typical smartphone battery capacity
battery_voltage = 3.7;  % Battery voltage
battery_capacity_J = battery_capacity_mAh * battery_voltage * 3.6;  % Convert to Joules

fprintf('Battery parameters:\n');
fprintf('  Capacity: %d mAh (approximately %.0f J)\n', battery_capacity_mAh, battery_capacity_J);
fprintf('  Voltage: %.1f V\n\n', battery_voltage);

%% 2) GPU Power Model Function
beta_interp = @(freq) interp1(freq_list, beta_freq_list, freq, 'linear', 'extrap');
P_GPU = @(freq, utilization, state) ...
    beta_interp(freq) * utilization/100 + beta_on * state;

%% 3) Simulation of Different Usage Scenarios
% Time parameters
T_total = 24 * 3600;  % 24 hours
dt = 60;              % 1-minute resolution
t = 0:dt:T_total;
n = length(t);

% Define usage scenarios
usage_scenario = [
    % Start time, End time, GPU frequency, Utilization, State
    0,          6 * 3600,   0,     0,   0;    % 0:00-6:00: Sleep (GPU off)
    6 * 3600,   7 * 3600,   128,   10,  1;    % 6:00-7:00: Light use
    7 * 3600,   8 * 3600,   200,   30,  1;    % 7:00-8:00: Social media
    8 * 3600,   9 * 3600,   400,   80,  1;    % 8:00-9:00: Gaming
    9 * 3600,   12 * 3600,  200,   20,  1;    % 9:00-12:00: Work
    12 * 3600,  13 * 3600,  325,   50,  1;    % 12:00-13:00: Video playback
    13 * 3600,  18 * 3600,  200,   15,  1;    % 13:00-18:00: Work
    18 * 3600,  19 * 3600,  400,   85,  1;    % 18:00-19:00: Gaming
    19 * 3600,  20 * 3600,  325,   60,  1;    % 19:00-20:00: Video streaming
    20 * 3600,  24 * 3600,  128,   5,   1;    % 20:00-24:00: Light use
];

% Initialize arrays
freq_array = zeros(size(t));
util_array = zeros(size(t));
state_array = zeros(size(t));
P_array = zeros(size(t));

% Generate GPU usage data
for i = 1:size(usage_scenario, 1)
    idx = (t >= usage_scenario(i,1)) & (t < usage_scenario(i,2));
    freq_array(idx) = usage_scenario(i,3);
    util_array(idx) = usage_scenario(i,4) + 5*randn(sum(idx),1)';  % Add 5% noise
    state_array(idx) = usage_scenario(i,5);
    
    % Ensure utilization is between 0-100%
    util_array(idx) = max(0, min(100, util_array(idx)));
end

% Calculate power consumption
for i = 1:n
    P_array(i) = P_GPU(freq_array(i), util_array(i), state_array(i));
end

P_array = max(P_array, 0);  % Ensure non-negative power

%% 4) Energy Consumption and SOC Calculation
% Calculate cumulative energy consumption
E_cumulative = cumtrapz(t, P_array/1000);  % Convert to Watts, integrate to Joules
SOC = 1 - E_cumulative / battery_capacity_J;
SOC = max(SOC, 0);  % Ensure SOC is non-negative

% Calculate statistics
E_total = trapz(t, P_array/1000);  % Total energy consumption (J)
avg_power = mean(P_array);  % Average power (mW)

%% 5) Visualization - Optimized Layout (3×2 layout, first subplot removed)
figure('Position', [100, 100, 1200, 900], 'Color', 'white');

% 5.1) Subplot 1: 24-Hour GPU Power Consumption Curve
subplot(3, 2, [1, 2]);  % Occupy first two positions for larger display
hold on; grid on;

% Plot power consumption curve
plot(t/3600, P_array, '-', 'Color', color1, 'LineWidth', 2.5);

% Add usage mode backgrounds
mode_colors = {[0.95,0.95,0.95], [0.85,0.95,0.85], [0.95,0.85,0.85], [0.85,0.85,0.95]};
mode_times = {[0,6], [6,7,7,9,20,24], [8,9,18,19], [12,13,19,20]};

% Fill background regions
for i = 1:length(mode_times)
    if i == 1
        fill([mode_times{1}(1), mode_times{1}(2), mode_times{1}(2), mode_times{1}(1)], ...
             [0, 0, max(P_array)*1.1, max(P_array)*1.1], mode_colors{1}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    elseif i == 2
        fill([6, 7, 7, 6], [0, 0, max(P_array)*1.1, max(P_array)*1.1], mode_colors{2}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        fill([7, 9, 9, 7], [0, 0, max(P_array)*1.1, max(P_array)*1.1], mode_colors{2}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        fill([20, 24, 24, 20], [0, 0, max(P_array)*1.1, max(P_array)*1.1], mode_colors{2}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    elseif i == 3
        fill([8, 9, 9, 8], [0, 0, max(P_array)*1.1, max(P_array)*1.1], mode_colors{3}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        fill([18, 19, 19, 18], [0, 0, max(P_array)*1.1, max(P_array)*1.1], mode_colors{3}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    elseif i == 4
        fill([12, 13, 13, 12], [0, 0, max(P_array)*1.1, max(P_array)*1.1], mode_colors{4}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        fill([19, 20, 20, 19], [0, 0, max(P_array)*1.1, max(P_array)*1.1], mode_colors{4}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    end
end

xlabel('Time (hours)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('GPU Power (mW)', 'FontSize', 12, 'FontWeight', 'bold');
title('24-Hour GPU Power Consumption Profile', 'FontSize', 14, 'FontWeight', 'bold');
xlim([0, 24]);
ylim([0, max(P_array)*1.1]);

% Add average power annotation
text(20, mean(P_array)*0.8, sprintf('Average: %.1f mW', mean(P_array)), ...
    'FontSize', 10, 'BackgroundColor', 'white', 'FontWeight', 'bold');

% 5.2) Subplot 2: GPU Frequency and Utilization
subplot(3, 2, 3);
yyaxis left;
plot(t/3600, freq_array, '-', 'Color', color2, 'LineWidth', 2);
ylabel('GPU Frequency (MHz)', 'FontSize', 12, 'FontWeight', 'bold');
ylim([0, 450]);

yyaxis right;
plot(t/3600, util_array, '-', 'Color', color3, 'LineWidth', 2);
ylabel('GPU Utilization (%)', 'FontSize', 12, 'FontWeight', 'bold');
ylim([0, 100]);

xlabel('Time (hours)', 'FontSize', 12, 'FontWeight', 'bold');
title('GPU Frequency and Utilization', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
xlim([0, 24]);

% Manual legend creation
legend({'Frequency', 'Utilization'}, 'Location', 'northeast');

% 5.3) Subplot 3: Power-Frequency Relationship
subplot(3, 2, 4);
hold on; grid on;

% Use specified colors
util_colors = {color1, color2, color3, color4};
util_levels = [0, 25, 50, 75];  % Four utilization levels

% Plot theoretical relationship curves
for i = 1:length(util_levels)
    util = util_levels(i);
    P_total = beta_freq_list + beta_on + beta_freq_list * util/100;
    
    plot(freq_list, P_total, 'o-', 'Color', util_colors{i}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', util_colors{i});
end

xlabel('GPU Frequency (MHz)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('GPU Power (mW)', 'FontSize', 12, 'FontWeight', 'bold');
title('Power-Frequency Relationship', 'FontSize', 14, 'FontWeight', 'bold');

% Create legend labels
legend_labels = arrayfun(@(x) sprintf('%d%%', x), util_levels, 'UniformOutput', false);
legend(legend_labels, 'Location', 'northwest');

% Add β_GPU_on baseline
yline(beta_on, 'k--', 'LineWidth', 1, 'Label', sprintf('β_GPU_on = %.1f mW', beta_on));

% 5.4) Subplot 4: Power Consumption Statistics at Different Frequencies
subplot(3, 2, 5);
hold on; grid on;

% Calculate average power consumption at each frequency
freq_unique = unique(freq_array(freq_array > 0));
avg_power_by_freq = zeros(size(freq_unique));

for i = 1:length(freq_unique)
    idx = freq_array == freq_unique(i) & state_array == 1;
    if any(idx)
        avg_power_by_freq(i) = mean(P_array(idx));
    end
end

% Bar chart
bar_colors = {color1, color2, color3, color4};
if ~isempty(freq_unique)
    bar_handles = bar(freq_unique, avg_power_by_freq, 0.6, 'FaceColor', 'flat');
    
    % Set color for each bar
    for i = 1:min(length(freq_unique), length(bar_colors))
        bar_handles.CData(i,:) = bar_colors{i};
    end
    
    % Add value labels
    for i = 1:length(freq_unique)
        text(freq_unique(i), avg_power_by_freq(i)+5, sprintf('%.1f', avg_power_by_freq(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    end
end

xlabel('GPU Frequency (MHz)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Average Power (mW)', 'FontSize', 12, 'FontWeight', 'bold');
title('Average GPU Power at Different Frequencies', 'FontSize', 14, 'FontWeight', 'bold');

% 5.5) Subplot 5: Battery SOC Variation - Adjust scale for centered display
subplot(3, 2, 6);
hold on; grid on;

% Plot SOC curve
plot(t/3600, SOC*100, '-', 'Color', color4, 'LineWidth', 2.5);
xlabel('Time (hours)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Battery State of Charge (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Impact of GPU Usage on Battery Life', 'FontSize', 14, 'FontWeight', 'bold');
xlim([0, 24]);

% Adjust Y-axis range to center the curve
% Calculate SOC minimum, then set appropriate Y-axis range
min_soc = min(SOC)*100;
max_soc = 100;

% Calculate center position to center the curve
center_soc = (min_soc + max_soc) / 2;
range_soc = max_soc - min_soc;

% Extend range by 10% to avoid edges
padding = range_soc * 0.1;
y_lower = min_soc - padding;
y_upper = max_soc + padding;

% Ensure Y-axis lower limit is not negative
y_lower = max(y_lower, 0);
ylim([y_lower, y_upper]);

% Add key time point annotations
key_times = [6, 12, 18, 24];
key_times_idx = [find(t >= 6 * 3600, 1), find(t >= 12 * 3600, 1), ...
                 find(t >= 18 * 3600, 1), length(t)];

for i = 1:length(key_times)
    text(key_times(i), SOC(key_times_idx(i))*100+2, ...
        sprintf('%.1f%%', SOC(key_times_idx(i))*100), ...
        'FontSize', 9, 'BackgroundColor', 'white', 'EdgeColor', 'k', ...
        'HorizontalAlignment', 'center');
end

% Add total energy consumption statistics
text(2, y_upper*0.9, sprintf('24h total consumption:\n%.0f J (%.1f%% of capacity)', ...
    E_total, E_total/battery_capacity_J*100), ...
    'FontSize', 9, 'BackgroundColor', [1,1,1,0.9], 'EdgeColor', 'k');

% Add reference lines showing battery capacity percentages
yline(100, 'k:', 'LineWidth', 1, 'Label', '100%');
yline(SOC(end)*100, 'r--', 'LineWidth', 1.5, ...
    'Label', sprintf('After 24h: %.1f%%', SOC(end)*100));

%% 6) Calculation Results Output
fprintf('=== Calculation Results ===\n\n');
fprintf('24-Hour Statistics:\n');
fprintf('  Total GPU Energy Consumption: %.0f J\n', E_total);
fprintf('  Average GPU Power: %.1f mW\n', avg_power);
fprintf('  Percentage of Battery Capacity: %.1f%%\n\n', E_total/battery_capacity_J*100);

fprintf('Battery Status Changes:\n');
fprintf('  Initial SOC: 100.0%%\n');
fprintf('  SOC after 24 hours: %.1f%%\n', SOC(end)*100);
fprintf('  Battery Depletion: %.1f%%\n\n', (1-SOC(end))*100);

fprintf('Power Statistics at Different Frequencies:\n');
if ~isempty(freq_unique)
    for i = 1:length(freq_unique)
        fprintf('  %d MHz: %.1f mW\n', freq_unique(i), avg_power_by_freq(i));
    end
end

%% 7) Save Results
% Save figure
saveas(gcf, 'GPU_Power_Analysis.png');
fprintf('\nFigure saved as: GPU_Power_Analysis.png\n');

% Save data
results = struct();
results.time_hours = t/3600;
results.gpu_frequency_MHz = freq_array;
results.gpu_utilization_percent = util_array;
results.gpu_state = state_array;
results.gpu_power_mW = P_array;
results.battery_soc_percent = SOC * 100;
results.parameters.frequency_points_MHz = freq_list;
results.parameters.beta_freq_mW_per_percent = beta_freq_list;
results.parameters.beta_on_mW = beta_on;
results.energy_total_J = E_total;
results.average_power_mW = avg_power;

save('GPU_analysis_results.mat', 'results');
fprintf('Data saved as: GPU_analysis_results.mat\n');

fprintf('\n=== Analysis Complete ===\n');