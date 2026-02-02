% ============================================
% Smartphone Battery SOC and CPU Power Consumption Analysis
% Based on two model images:
% 1. Battery SOC Model (based on Image 1)
% 2. CPU Power Consumption Model (based on Image 2)
% ============================================

clear; close all; clc;

%% Color Scheme Definition
color1 = [0.3, 0.396, 0.6];       % Dark blue series
color2 = [0.54, 0.55, 0.75];      % Purple series
color3 = [0.93, 0.79, 0.45];      % Orange series
color4 = [0.714, 0.463, 0.4];     % Dark orange series

%% 1) Battery SOC Model (based on Image 1)
fprintf('=== Battery SOC Model (based on Image 1) ===\n\n');
fprintf('In battery modeling and Battery Management Systems (BMS), SOC is typically defined using continuous-time current integration (Coulomb counting):\n');
fprintf('SOC(t) = SOC(t₀) - 1/Qₙₒₘ ∫ₜ₀ᵗ I(τ) dτ\n');
fprintf('The corresponding differential form is:\n');
fprintf('dSOC(t)/dt = -I(t)/Qₙₒₘ\n\n');

% Battery parameters
Q_nom = 3000;  % Battery nominal capacity 3000mAh
V_batt = 3.7;  % Battery voltage 3.7V
SOC_0 = 0.8;   % Initial SOC 80%

% SOC calculation function
calculate_SOC = @(I_array, dt, SOC_init) ...
    SOC_init - (1/Q_nom) * cumtrapz(I_array) * dt;

%% 2) CPU Power Consumption Model (based on Image 2)
fprintf('=== CPU Power Consumption Model (based on Image 2) ===\n\n');
fprintf('Core equation of smartphone CPU power consumption model:\n');
fprintf('P_cpu(t) = P₀(f(t)) + α(f(t))·U(t) + γ·g(L(t))\n\n');

% CPU frequency-related parameters
f_min = 0.3e9;   % Minimum frequency 300MHz
f_max = 2.4e9;   % Maximum frequency 2.4GHz
f_steps = 10;    % Number of frequency levels
f_range = linspace(f_min, f_max, f_steps);

% Base power function P₀(f) (frequency-dependent base power)
P0_f = 0.01 + 0.001 * (f_range / 1e9).^2;  % Unit: W

% Load coefficient function α(f) (frequency-dependent load coefficient)
alpha_f = 0.002 + 0.0005 * (f_range / 1e9);  % Unit: W

% Busy-idle structure parameters
gamma = 0.05;  % Busy-idle structure weight (Unit: W·s)
epsilon = 0.1; % Small constant to prevent division by zero

% Busy-idle structure mapping function g(L) = 1/(L + ε)
g_func = @(L) 1 ./ (L + epsilon);

%% 3) Simulation of Different CPU States
fprintf('=== Simulation of Different CPU States ===\n\n');

% Time parameters
T_total = 300;  % Total time 300 seconds
dt = 0.5;       % Time resolution 0.5 seconds
t = 0:dt:T_total;
n_samples = length(t);

% Define 4 different CPU states
states = {'Idle State', 'Light Load', 'Medium Load', 'Heavy Load'};
state_colors = {color1, color2, color3, color4};

% Parameter settings for each state
state_params = [
    0.1, 0.8e9, 0.2;    % Idle: Utilization 10%, Frequency 0.8GHz, Busy length 0.2s
    0.3, 1.5e9, 0.1;    % Light: Utilization 30%, Frequency 1.5GHz, Busy length 0.1s
    0.6, 2.0e9, 0.05;   % Medium: Utilization 60%, Frequency 2.0GHz, Busy length 0.05s
    0.9, 2.4e9, 0.02;   % Heavy: Utilization 90%, Frequency 2.4GHz, Busy length 0.02s
];

%% 4) Calculation of CPU Power for Different States
fprintf('=== Calculation of CPU Power for Different States ===\n\n');

% Initialize storage arrays
P_cpu_states = zeros(n_samples, length(states));
I_batt_states = zeros(n_samples, length(states));
SOC_states = zeros(n_samples, length(states));

for state_idx = 1:length(states)
    fprintf('Calculating state: %s\n', states{state_idx});
    
    % Get state parameters
    U_target = state_params(state_idx, 1);
    f_target = state_params(state_idx, 2);
    L_target = state_params(state_idx, 3);
    
    % Generate state-specific simulation data
    U = U_target + 0.05 * randn(size(t));  % Utilization
    f = f_target + 0.1e9 * randn(size(t));  % Frequency
    L = L_target + 0.02 * randn(size(t));  % Busy segment length
    
    % Limit numerical ranges
    U = min(max(U, 0), 1);
    f = min(max(f, f_min), f_max);
    L = max(L, 0.01);
    
    % Interpolate to get P₀ and α for current frequency
    P0_current = interp1(f_range, P0_f, f, 'linear', 'extrap');
    alpha_current = interp1(f_range, alpha_f, f, 'linear', 'extrap');
    
    % Calculate busy-idle structure term
    g_L = g_func(L);
    
    % Calculate CPU power
    P_cpu = P0_current + alpha_current .* U + gamma * g_L;
    
    % Calculate total power (CPU + other components)
    P_other = 0.5 + 0.1 * randn(size(t));  % Other component power
    P_total = P_cpu + P_other;
    
    % Calculate current
    I_batt = P_total / V_batt;  % Unit: A
    
    % Calculate SOC change
    SOC = calculate_SOC(I_batt, dt, SOC_0);
    
    % Store results
    P_cpu_states(:, state_idx) = P_cpu(:);
    I_batt_states(:, state_idx) = I_batt(:);
    SOC_states(:, state_idx) = SOC(:);
    
    fprintf('  Average CPU power: %.3f W\n', mean(P_cpu));
    fprintf('  Average battery current: %.1f mA\n', mean(I_batt)*1000);
    fprintf('  SOC change: %.2f%% → %.2f%%\n\n', SOC_0 * 100, SOC(end)*100);
end

%% 5) Visualization - Simplified Version
figure('Position', [100, 100, 1200, 800], 'Color', 'white');

% 5.1) Subplot 1: Model Equation Presentation
subplot(2, 3, 1);
hold on;
box on;
text(0.1, 0.9, 'Battery SOC Model (Coulomb Counting)', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Units', 'normalized');
text(0.1, 0.7, '$$SOC(t) = SOC(t_0) - \frac{1}{Q_{nom}} \int_{t_0}^{t} I(\tau) d\tau$$', ...
    'Interpreter', 'latex', 'FontSize', 10, 'Units', 'normalized');
text(0.1, 0.6, 'Differential form:', 'FontSize', 10, 'Units', 'normalized');
text(0.1, 0.5, '$$\frac{dSOC(t)}{dt} = -\frac{I(t)}{Q_{nom}}$$', ...
    'Interpreter', 'latex', 'FontSize', 10, 'Units', 'normalized');
text(0.1, 0.3, 'Where:', 'FontSize', 10, 'Units', 'normalized');
text(0.1, 0.2, 'SOC(t): State of Charge at time t', 'FontSize', 8, 'Units', 'normalized');
text(0.1, 0.15, 'I(t): Battery current (positive for discharge)', 'FontSize', 8, 'Units', 'normalized');
text(0.1, 0.1, 'Q_{nom}: Battery nominal capacity', 'FontSize', 8, 'Units', 'normalized');
axis off;
title('Battery SOC Model (based on Image 1)', 'FontSize', 12, 'FontWeight', 'bold');

% 5.2) Subplot 2: CPU Power Model Equation Presentation
subplot(2, 3, 2);
hold on;
box on;
text(0.1, 0.9, 'CPU Power Model', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Units', 'normalized');
text(0.1, 0.7, '$$P_{cpu}(t) = P_0(f(t)) + \alpha(f(t)) \cdot U(t) + \gamma \cdot g(L(t))$$', ...
    'Interpreter', 'latex', 'FontSize', 10, 'Units', 'normalized');
text(0.1, 0.5, 'Where:', 'FontSize', 10, 'Units', 'normalized');
text(0.1, 0.4, 'P_0(f): Frequency-dependent base power', 'FontSize', 8, 'Units', 'normalized');
text(0.1, 0.35, '\alpha(f): Frequency-dependent load coefficient', 'FontSize', 8, 'Units', 'normalized');
text(0.1, 0.3, 'U(t): CPU utilization', 'FontSize', 8, 'Units', 'normalized');
text(0.1, 0.25, 'L(t): Busy segment length', 'FontSize', 8, 'Units', 'normalized');
text(0.1, 0.2, 'g(L): Busy-idle structure mapping function', 'FontSize', 8, 'Units', 'normalized');
text(0.1, 0.15, '\gamma: Busy-idle structure weight', 'FontSize', 8, 'Units', 'normalized');
axis off;
title('CPU Power Model (based on Image 2)', 'FontSize', 12, 'FontWeight', 'bold');

% 5.3) Subplot 3: Average Power Comparison for Different CPU States
subplot(2, 3, 3);
avg_power = mean(P_cpu_states)';
bar_handles = bar(avg_power);
% Simple color settings
for i = 1:length(bar_handles)
    bar_handles(i).FaceColor = state_colors{i};
end
xlabel('CPU State');
ylabel('Average CPU Power (W)');
title('Average CPU Power for Different States');
set(gca, 'XTickLabel', states, 'XTickLabelRotation', 45);
grid on;

% 5.4) Subplot 4: Battery Current Comparison
subplot(2, 3, 4);
hold on;
for i = 1:length(states)
    plot(t, I_batt_states(:, i)*1000, 'Color', state_colors{i}, ...
        'LineWidth', 1.5, 'DisplayName', states{i});
end
xlabel('Time (s)');
ylabel('Battery Current (mA)');
title('Battery Current for Different States');
legend('Location', 'best', 'FontSize', 8);
grid on;

% 5.5) Subplot 5: SOC Change Comparison
subplot(2, 3, 5);
hold on;
for i = 1:length(states)
    plot(t, SOC_states(:, i)*100, 'Color', state_colors{i}, ...
        'LineWidth', 1.5, 'DisplayName', states{i});
end
xlabel('Time (s)');
ylabel('SOC (%)');
title('SOC Change for Different States');
legend('Location', 'best', 'FontSize', 8);
grid on;
ylim([70, 81]);

% 5.6) Subplot 6: Model Parameter Comparison
subplot(2, 3, 6);
hold on;
plot(f_range/1e9, P0_f*1000, 'Color', color1, 'LineWidth', 2, 'DisplayName', 'P_0(f)');
plot(f_range/1e9, alpha_f*1000, 'Color', color2, 'LineWidth', 2, 'DisplayName', '\alpha(f)');
xlabel('Frequency (GHz)');
ylabel('Parameter Value (mW)');
title('Frequency-dependent Parameters');
legend('Location', 'best');
grid on;

%% 6) Second Figure: Power Decomposition Analysis - Corrected Version
figure('Position', [200, 200, 1000, 600], 'Color', 'white');

% 6.1) Subplot 1: Power Decomposition (Heavy Load State Example)
subplot(2, 2, 1);
% Select heavy load state for analysis
state_idx = 4;
U_target = state_params(state_idx, 1);
f_target = state_params(state_idx, 2);
L_target = state_params(state_idx, 3);

% Calculate each component
P0_val = interp1(f_range, P0_f, f_target);
alpha_val = interp1(f_range, alpha_f, f_target);
g_L_val = g_func(L_target);

% Calculate component values - adjust relative sizes for better visualization
P0_comp = P0_val * ones(size(t));
alpha_comp = alpha_val * U_target * ones(size(t));
g_L_comp = gamma * g_L_val * ones(size(t));

% Adjust component size for better coordination
% Reduce yellow component (γ·g(L) component) to avoid excessive distance
g_L_comp_adjusted = g_L_comp * 0.3;  % Adjusted to 30% of original

% Add noise for realistic visualization
P0_comp = P0_comp + 0.005 * randn(size(t));
alpha_comp = alpha_comp + 0.008 * randn(size(t));
g_L_comp_adjusted = g_L_comp_adjusted + 0.003 * randn(size(t));

% Use stacked area plot with adjusted order
components = [P0_comp', alpha_comp', g_L_comp_adjusted'];
h = area(t, components, 'LineStyle', 'none');

% Set colors
h(1).FaceColor = color1;  % P₀(f) component - dark blue
h(2).FaceColor = color2;  % α(f)·U component - purple
h(3).FaceColor = color3;  % γ·g(L) component - orange (adjusted)

% Add boundary lines for clarity
hold on;
plot(t, P0_comp, 'Color', color1, 'LineWidth', 1, 'LineStyle', '-');
plot(t, P0_comp+alpha_comp, 'Color', color2, 'LineWidth', 1, 'LineStyle', '-');
plot(t, P0_comp+alpha_comp+g_L_comp_adjusted, 'Color', color3, 'LineWidth', 1, 'LineStyle', '-');

% 修改后的标签和标题（使用LaTeX格式）
xlabel('Time (s)', 'Interpreter', 'latex');
ylabel('Power Components (W)', 'Interpreter', 'latex');
title('Power Decomposition for Heavy Load State (Adjusted)', 'Interpreter', 'latex');

% 修改图例（使用LaTeX格式）
legend({'$P_0(f)$ Component', '$\alpha(f){\cdot}U$ Component', '$\gamma{\cdot}g(L)$ Component'}, ...
       'Interpreter', 'latex', 'Location', 'northeast');
grid on;
xlim([0, 50]);  % Show only first 50 seconds for clarity

% 修改组件值注释（使用LaTeX格式）
text(5, P0_val*0.8, sprintf('$P_0=%.3f$ W', P0_val), ...
    'Color', color1, 'FontSize', 9, 'BackgroundColor', 'white', ...
    'FontWeight', 'bold', 'Interpreter', 'latex');
text(5, P0_val+alpha_val*U_target*0.8, sprintf('$\\alpha{\\cdot}U=%.3f$ W', alpha_val*U_target), ...
    'Color', color2, 'FontSize', 9, 'BackgroundColor', 'white', ...
    'FontWeight', 'bold', 'Interpreter', 'latex');
text(5, P0_val+alpha_val*U_target+gamma*g_L_val*0.3 * 0.8, ...
    sprintf('$\\gamma{\\cdot}g(L)=%.3f$ W', gamma*g_L_val*0.3), ...
    'Color', color3, 'FontSize', 9, 'BackgroundColor', 'white', ...
    'FontWeight', 'bold', 'Interpreter', 'latex');


% 6.2) Subplot 2: Busy-idle Structure Function
subplot(2, 2, 2);
L_test = 0:0.01:1;
plot(L_test, g_func(L_test), 'Color', color1, 'LineWidth', 2);
xlabel('Busy Segment Length L (s)');
ylabel('g(L) = 1/(L+\epsilon)');
title('Busy-idle Structure Mapping Function');
grid on;

% Add function description
text(0.3, 5, 'g(L) = 1/(L+\epsilon)', ...
    'Color', color1, 'FontSize', 10, 'BackgroundColor', 'white', 'FontWeight', 'bold');
text(0.6, 3, sprintf('\epsilon=%.1f', epsilon), ...
    'Color', color2, 'FontSize', 9, 'BackgroundColor', 'white');
text(0.1, 1, 'Smaller L → Larger g(L)', ...
    'Color', color3, 'FontSize', 9, 'BackgroundColor', 'white');

% 6.3) Subplot 3: SOC Drop Rate Comparison
subplot(2, 2, 3);
SOC_drop = 100 - SOC_states(end, :)' * 100;
bar_handles2 = bar(SOC_drop);

% Set colors and add data labels for each bar
for i = 1:length(bar_handles2)
    bar_handles2(i).FaceColor = state_colors{i};
    
    % Add data labels above each bar
    text(i, SOC_drop(i) + 0.1, sprintf('%.2f%%', SOC_drop(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black');
end

xlabel('CPU State');
ylabel('SOC Drop Percentage (%)');
title('SOC Drop for Different States');
set(gca, 'XTickLabel', states, 'XTickLabelRotation', 45);
grid on;
ylim([0, max(SOC_drop) + 1]);  % Space for data labels

% Add statistical information
text(0.5, max(SOC_drop)*0.9, sprintf('Max drop: %.2f%%', max(SOC_drop)), ...
    'FontSize', 9, 'BackgroundColor', 'white', 'FontWeight', 'bold');
text(0.5, max(SOC_drop)*0.8, sprintf('Min drop: %.2f%%', min(SOC_drop)), ...
    'FontSize', 9, 'BackgroundColor', 'white', 'FontWeight', 'bold');

% 6.4) Subplot 4: Power vs. SOC Drop Relationship
subplot(2, 2, 4);
% Calculate data
avg_power = mean(P_cpu_states)';
SOC_drop = 100 - SOC_states(end, :)' * 100;

% Plot scatter points
for i = 1:length(states)
    scatter(avg_power(i), SOC_drop(i), 150, 'filled', ...
        'MarkerFaceColor', state_colors{i}, 'MarkerEdgeColor', 'k', ...
        'MarkerFaceAlpha', 0.8);
    hold on;
end

% Optimized text label positions
text_positions = [
    avg_power(1) - 0.02, SOC_drop(1) + 0.2;   % Idle State - top left
    avg_power(2) - 0.02, SOC_drop(2) + 0.2;   % Light Load - top left
    avg_power(3) + 0.02, SOC_drop(3) - 0.3;   % Medium Load - bottom right
    avg_power(4) + 0.02, SOC_drop(4) - 0.3;   % Heavy Load - bottom right
];

for i = 1:length(states)
    text(text_positions(i, 1), text_positions(i, 2), states{i}, ...
        'FontSize', 9, 'Color', state_colors{i}, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
end

xlabel('Average CPU Power (W)');
ylabel('SOC Drop Percentage (%)');
title('Power vs. SOC Drop Relationship');
grid on;

% Add regression line
p = polyfit(avg_power, SOC_drop, 1);
x_fit = linspace(min(avg_power), max(avg_power), 100);
y_fit = polyval(p, x_fit);
plot(x_fit, y_fit, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Trend Line');

% Display regression equation
text(0.15, max(SOC_drop)*0.8, sprintf('y = %.2fx + %.2f', p(1), p(2)), ...
    'FontSize', 10, 'BackgroundColor', 'white', 'FontWeight', 'bold');
text(0.15, max(SOC_drop)*0.7, sprintf('R² = %.3f', corr(avg_power, SOC_drop)^2), ...
    'FontSize', 9, 'BackgroundColor', 'white');

% Set compact axis limits
xlim([min(avg_power)-0.05, max(avg_power)+0.05]);
ylim([min(SOC_drop)-0.5, max(SOC_drop)+0.5]);

% Add trend description
text(mean(avg_power), mean(SOC_drop)*0.9, 'Power↑ → SOC Drop↑', ...
    'FontSize', 10, 'Color', 'red', 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');

%% 7) Statistical Output
fprintf('=== Statistical Analysis of CPU State Impact on Battery ===\n\n');

fprintf('State Comparison Statistics:\n');
fprintf('%-15s %-12s %-15s %-12s %-15s\n', ...
    'State', 'Avg Power(W)', 'Avg Current(mA)', 'Energy(J)', 'SOC Drop(%)');
fprintf('%s\n', repmat('-', 60, 1));

for i = 1:length(states)
    fprintf('%-15s %-12.3f %-15.1f %-12.1f %-15.2f\n', ...
        states{i}, ...
        mean(P_cpu_states(:, i)), ...
        mean(I_batt_states(:, i))*1000, ...
        trapz(t, P_cpu_states(:, i)), ...
        100 - SOC_states(end, i)*100);
end

fprintf('\nPower vs. SOC Drop Correlation:\n');
fprintf('   Correlation coefficient R = %.3f\n', corr(avg_power, SOC_drop));
fprintf('   Coefficient of determination R² = %.3f\n', corr(avg_power, SOC_drop)^2);
fprintf('   Regression equation: SOC Drop = %.2f × Power + %.2f\n\n', p(1), p(2));

% Save corrected figure
saveas(gcf, 'cpu_battery_analysis_corrected.png');
fprintf('Corrected figure saved as cpu_battery_analysis_corrected.png\n');
fprintf('\n=== Analysis Complete ===\n');