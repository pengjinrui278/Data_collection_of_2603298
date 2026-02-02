% ============================================================
% Mobile Device Power Consumption Analysis: Network Activity and Background Applications
% Based on the power consumption model from the provided image
% Model: P_total = P_idle + P_scr + P_net + P_cpu + P_gps + P_gpu + Σ P_j * 1_j(t)
% where P_j are constants, and 1_j(t) are state indicator functions
% ============================================================

clear; close all; clc;

%% Color scheme
color1 = [0.3, 0.396, 0.6];      % Dark blue series
color2 = [0.54, 0.55, 0.75];    % Purple series
color3 = [0.93, 0.79, 0.45];    % Orange series
color4 = [0.714, 0.463, 0.4];   % Dark orange series

% Assign colors
color_base = color1;      % Base power consumption
color_net = color2;       % Network power consumption
color_video = color3;     % Video playback power consumption
color_audio_rec = color4; % Audio recording power consumption
color_audio_play = [0.6, 0.4, 0.2];  % Audio playback power consumption (brown)
color_background = [0.5, 0.5, 0.5];  % Background process power consumption (gray)
color_total = [0.2, 0.2, 0.2];  % Total power consumption (black)

%% 1) Power Model Parameters Extracted from the Image
fprintf('=== Mobile Device Power Consumption Model (Based on Image Formulas) ===\n\n');
fprintf('Core formula (from image):\n');
fprintf('P_app(t) = Σ_j P_j * 1_j(t)\n');
fprintf('where P_j are constants, 1_j(t)∈{0,1} indicates whether the function is enabled\n\n');
fprintf('Total power formula:\n');
fprintf('P_total = P_idle + P_scr + P_net + P_cpu + P_gps + P_gpu + Σ_j P_j * 1_j(t)\n\n');

% Define base power consumption for each component (constants)
P_idle = 0.1;   % Idle power consumption (W) - constant
P_scr = 0.3;    % Screen power consumption (W) - constant
P_cpu = 0.2;    % CPU base power consumption (W) - constant
P_gps = 0.1;    % GPS power consumption (W) - constant
P_gpu = 0.1;    % GPU base power consumption (W) - constant

% Network power consumption (constant model based on activity level)
% Note: The image does not explicitly specify the P_net model. We assume it is a function of network activity level
% Simplified as: P_net = β_net + α_net * activity(t)
% where β_net is the base network power, and α_net is the activity coefficient
beta_net = 0.05;  % Base network power
alpha_net = 0.15; % Network activity coefficient

% Application-specific power constants (state constant terms from the image)
P_video_play = 0.12;    % Video playback power consumption (W) - constant
P_audio_rec = 0.25;     % Audio recording power consumption (W) - constant
P_audio_play = 0.08;    % Audio playback power consumption (W) - constant
P_background = 0.05;    % Background process power consumption (W) - constant

fprintf('=== Power Constant Definitions ===\n');
fprintf('Component     Power(W) Description\n');
fprintf('%-12s %.3f   Base power consumption in idle state\n', 'P_idle', P_idle);
fprintf('%-12s %.3f   Screen power consumption\n', 'P_scr', P_scr);
fprintf('%-12s %.3f   CPU base power consumption\n', 'P_cpu', P_cpu);
fprintf('%-12s %.3f   GPS power consumption\n', 'P_gps', P_gps);
fprintf('%-12s %.3f   GPU base power consumption\n', 'P_gpu', P_gpu);
fprintf('%-12s %.3f   Base network power consumption\n', 'β_net', beta_net);
fprintf('%-12s %.3f   Network activity coefficient\n', 'α_net', alpha_net);
fprintf('%-12s %.3f   Video playback power constant\n', 'P_video_play', P_video_play);
fprintf('%-12s %.3f   Audio recording power constant\n', 'P_audio_rec', P_audio_rec);
fprintf('%-12s %.3f   Audio playback power constant\n', 'P_audio_play', P_audio_play);
fprintf('%-12s %.3f   Background process power constant\n', 'P_background', P_background);

%% 2) Power Model Functions
% Network power function (based on activity level)
P_net_func = @(activity_level) beta_net + alpha_net * activity_level;

% Total power calculation function (based on image formula)
P_total_func = @(net_activity, video_state, audio_rec_state, audio_play_state, background_state) ...
    P_idle + P_scr + P_net_func(net_activity) + P_cpu + P_gps + P_gpu + ...
    P_video_play * video_state + P_audio_rec * audio_rec_state + ...
    P_audio_play * audio_play_state + P_background * background_state;

%% 3) Simulation Settings
T_total = 24;  % 24-hour simulation
dt = 0.1;      % 0.1-hour resolution
time = 0:dt:T_total;  % Time vector
n = length(time);

% Define typical daily usage pattern
% Each row: [start_time, end_time, network_activity(0-1), video_state(0/1), 
%            audio_rec_state(0/1), audio_play_state(0/1), background_state(0/1)]
% where 1_j(t) ∈ {0,1} indicates whether the function is enabled (state indicator function from the image)

daily_scenario = [
    % Sleep time (all functions off)
    0,  6,   0.1, 0, 0, 0, 0;    % Night: low network, all applications off
    
    % Morning activities
    6,  7,   0.3, 0, 0, 1, 1;    % Morning: medium network, audio playback on, background processes
    7,  8,   0.5, 0, 0, 1, 1;    % Commute: high network, audio playback, background processes
    
    % Work hours
    8,  10,  0.7, 0, 0, 0, 1;    % Work: high network, background processes
    10, 12,  0.4, 0, 0, 0, 1;    % Work: medium network, background processes
    
    % Lunch break
    12, 13,  0.2, 1, 0, 0, 1;    % Lunch: low network, video playback, background processes
    13, 13.5,0.1, 0, 1, 0, 1;    % Afternoon break: low network, audio recording, background processes
    
    % Afternoon
    13.5,15, 0.6, 0, 0, 0, 1;    % Meeting: medium network, background processes
    15, 18,  0.8, 0, 0, 0, 1;    % Work: high network, background processes
    
    % Evening entertainment
    18, 20,  0.5, 1, 0, 0, 1;    % Evening: medium network, video playback, background processes
    20, 20+1/3, 0.3, 0, 0, 1, 1; % Relaxation: medium network, audio playback, background processes (20:20)
    20+1/3, 22, 0.3, 0, 0, 0, 1; % Relaxation: medium network, background processes
    
    % Night
    22, 24,  0.1, 0, 0, 0, 0;    % Night: low network, all applications off
];

% Initialize arrays
net_activity_array = zeros(size(time));
video_state_array = zeros(size(time));
audio_rec_state_array = zeros(size(time));
audio_play_state_array = zeros(size(time));
background_state_array = zeros(size(time));

% Generate state data
for i = 1:size(daily_scenario, 1)
    start_hour = daily_scenario(i,1);
    end_hour = daily_scenario(i,2);
    net_activity = daily_scenario(i,3);
    video_state = daily_scenario(i,4);
    audio_rec_state = daily_scenario(i,5);
    audio_play_state = daily_scenario(i,6);
    background_state = daily_scenario(i,7);
    
    idx = (time >= start_hour) & (time < end_hour);
    
    % Add randomness to network activity
    noise_factor = 0.1;
    net_activity_noisy = max(0, min(1, net_activity + noise_factor * randn(sum(idx),1)'));
    net_activity_array(idx) = net_activity_noisy;
    
    % State variables (0 or 1)
    video_state_array(idx) = video_state;
    audio_rec_state_array(idx) = audio_rec_state;
    audio_play_state_array(idx) = audio_play_state;
    background_state_array(idx) = background_state;
end

% Calculate component power consumption
P_base_array = P_idle + P_scr + P_cpu + P_gps + P_gpu + P_background * background_state_array;
P_net_array = P_net_func(net_activity_array);
P_video_array = P_video_play * video_state_array;
P_audio_rec_array = P_audio_rec * audio_rec_state_array;
P_audio_play_array = P_audio_play * audio_play_state_array;

% Calculate total power consumption
P_total_array = P_base_array + P_net_array + P_video_array + ...
                P_audio_rec_array + P_audio_play_array;

%% 4) Visualization - Keep only the first subplot
figure('Position', [100, 100, 1000, 600], 'Color', 'white');

% 4.1) 24-hour Power Breakdown Plot
axes('Position', [0.12, 0.15, 0.7, 0.75]);  % Adjust position to leave space for legend
hold on; grid on;

% Create stacked area plot
x = time;
y = [P_base_array - P_background * background_state_array;  % Base power (excluding background)
     P_net_array;
     P_video_array;
     P_audio_rec_array;
     P_audio_play_array;
     P_background * background_state_array]';  % Background power shown separately
area_handles = area(x, y);

% Set colors
set(area_handles(1), 'FaceColor', color_base, 'FaceAlpha', 0.7, 'EdgeColor', 'none');
set(area_handles(2), 'FaceColor', color_net, 'FaceAlpha', 0.7, 'EdgeColor', 'none');
set(area_handles(3), 'FaceColor', color_video, 'FaceAlpha', 0.7, 'EdgeColor', 'none');
set(area_handles(4), 'FaceColor', color_audio_rec, 'FaceAlpha', 0.7, 'EdgeColor', 'none');
set(area_handles(5), 'FaceColor', color_audio_play, 'FaceAlpha', 0.7, 'EdgeColor', 'none');
set(area_handles(6), 'FaceColor', color_background, 'FaceAlpha', 0.7, 'EdgeColor', 'none');

% Add total power curve
plot(time, P_total_array, 'k-', 'LineWidth', 2.5, 'DisplayName', 'Total Power');

xlabel('Time (hours)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Power (W)', 'FontSize', 12, 'FontWeight', 'bold');
title('24-hour Power Breakdown (Constant Model)', 'FontSize', 14, 'FontWeight', 'bold');
xlim([0, 24]);
ylim([0, max(P_total_array)*1.1]);

% Add legend
legend({'Base Power (Idle+Screen+CPU+GPS+GPU)', 'Network Power', 'Video Playback', ...
    'Audio Recording', 'Audio Playback', 'Background Processes', 'Total Power'}, ...
    'Location', 'eastoutside', 'FontSize', 9, 'Box', 'off');

% Add time markers
plot([6, 12, 18, 22], [0, 0, 0, 0], 'kv', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
text(6, -0.05, '6:00', 'HorizontalAlignment', 'center', 'FontSize', 10);
text(12, -0.05, '12:00', 'HorizontalAlignment', 'center', 'FontSize', 10);
text(18, -0.05, '18:00', 'HorizontalAlignment', 'center', 'FontSize', 10);
text(22, -0.05, '22:00', 'HorizontalAlignment', 'center', 'FontSize', 10);

% Add power statistics
total_energy = trapz(time, P_total_array) * 1000;  % Convert to mWh
avg_power = mean(P_total_array);
text(22, max(P_total_array)*0.85, sprintf('Avg Power: %.3f W\nTotal Energy: %.0f mWh', avg_power, total_energy), ...
    'FontSize', 10, 'BackgroundColor', [1,1,1,0.9], 'EdgeColor', 'k', 'Margin', 2);

% Add usage pattern description
text(3, max(P_total_array)*0.7, {'Usage Pattern:', '0-6h: Sleep', '6-8h: Morning Activities', '8-12h: Work'}, ...
    'FontSize', 9, 'BackgroundColor', [1,1,1,0.8], 'EdgeColor', 'k', 'Margin', 2);
text(13, max(P_total_array)*0.7, {'12-13h: Lunch Break', '13-18h: Afternoon Work', '18-22h: Evening Entertainment', '22-24h: Sleep'}, ...
    'FontSize', 9, 'BackgroundColor', [1,1,1,0.8], 'EdgeColor', 'k', 'Margin', 2);

%% 5) Calculate and Display Statistical Results
fprintf('\n=== 24-hour Power Consumption Statistics (Constant Model) ===\n\n');

% Calculate component energy consumption
E_base = trapz(time, P_base_array - P_background * background_state_array) * 1000;  % Base power (excluding background)
E_net = trapz(time, P_net_array) * 1000;
E_video = trapz(time, P_video_array) * 1000;
E_audio_rec = trapz(time, P_audio_rec_array) * 1000;
E_audio_play = trapz(time, P_audio_play_array) * 1000;
E_background = trapz(time, P_background * background_state_array) * 1000;
E_total = trapz(time, P_total_array) * 1000;

% Display statistical results
fprintf('Total Energy Consumption: %.0f mWh\n', E_total);
fprintf('Average Power: %.3f W\n\n', avg_power);

fprintf('Energy Breakdown:\n');
fprintf('  Base Power:                 %6.0f mWh (%5.1f%%)\n', E_base, E_base/E_total*100);
fprintf('  Network Power:              %6.0f mWh (%5.1f%%)\n', E_net, E_net/E_total*100);
fprintf('  Video Playback Power:       %6.0f mWh (%5.1f%%)\n', E_video, E_video/E_total*100);
fprintf('  Audio Recording Power:      %6.0f mWh (%5.1f%%)\n', E_audio_rec, E_audio_rec/E_total*100);
fprintf('  Audio Playback Power:       %6.0f mWh (%5.1f%%)\n', E_audio_play, E_audio_play/E_total*100);
fprintf('  Background Processes Power: %6.0f mWh (%5.1f%%)\n\n', E_background, E_background/E_total*100);

% Calculate application activity times
video_time = sum(video_state_array) * dt;
audio_rec_time = sum(audio_rec_state_array) * dt;
audio_play_time = sum(audio_play_state_array) * dt;
background_time = sum(background_state_array) * dt;

fprintf('Application Activity Times:\n');
fprintf('  Video Playback:     %.1f hours (%.1f%% of day)\n', video_time, video_time/24 * 100);
fprintf('  Audio Recording:    %.1f hours (%.1f%% of day)\n', audio_rec_time, audio_rec_time/24 * 100);
fprintf('  Audio Playback:     %.1f hours (%.1f%% of day)\n', audio_play_time, audio_play_time/24 * 100);
fprintf('  Background Processes: %.1f hours (%.1f%% of day)\n\n', background_time, background_time/24 * 100);

% Battery analysis
battery_capacity_mAh = 3000;
battery_voltage = 3.7;
battery_energy_mWh = battery_capacity_mAh * battery_voltage;
battery_life_hours = battery_energy_mWh / (avg_power * 1000);

fprintf('Battery Analysis (assuming 3000mAh, 3.7V battery):\n');
fprintf('  Battery Energy Capacity: %.0f mWh\n', battery_energy_mWh);
fprintf('  Estimated Battery Life:  %.1f hours\n', battery_life_hours);
fprintf('  Daily Battery Consumption: %.1f%%\n\n', E_total/battery_energy_mWh*100);

%% 6) Save Results
% Save figure
saveas(gcf, 'constant_model_24h_power_breakdown.png');
fprintf('\nFigure saved as: constant_model_24h_power_breakdown.png\n');

% Save data
results = struct();
results.time_hours = time;
results.net_activity = net_activity_array;
results.video_state = video_state_array;
results.audio_rec_state = audio_rec_state_array;
results.audio_play_state = audio_play_state_array;
results.background_state = background_state_array;
results.P_base_W = P_base_array;
results.P_net_W = P_net_array;
results.P_video_W = P_video_array;
results.P_audio_rec_W = P_audio_rec_array;
results.P_audio_play_W = P_audio_play_array;
results.P_total_W = P_total_array;

results.power_constants.P_idle = P_idle;
results.power_constants.P_scr = P_scr;
results.power_constants.P_cpu = P_cpu;
results.power_constants.P_gps = P_gps;
results.power_constants.P_gpu = P_gpu;
results.power_constants.beta_net = beta_net;
results.power_constants.alpha_net = alpha_net;
results.power_constants.P_video_play = P_video_play;
results.power_constants.P_audio_rec = P_audio_rec;
results.power_constants.P_audio_play = P_audio_play;
results.power_constants.P_background = P_background;

results.energy_breakdown_mWh.base = E_base;
results.energy_breakdown_mWh.network = E_net;
results.energy_breakdown_mWh.video = E_video;
results.energy_breakdown_mWh.audio_rec = E_audio_rec;
results.energy_breakdown_mWh.audio_play = E_audio_play;
results.energy_breakdown_mWh.background = E_background;
results.energy_breakdown_mWh.total = E_total;

results.activity_times_h.video = video_time;
results.activity_times_h.audio_rec = audio_rec_time;
results.activity_times_h.audio_play = audio_play_time;
results.activity_times_h.background = background_time;

save('constant_model_power_analysis.mat', 'results');
fprintf('Data saved as: constant_model_power_analysis.mat\n');

fprintf('\n=== Analysis Complete ===\n');