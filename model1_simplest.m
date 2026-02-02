% ============================================
% 智能手机电池模型 - 基于NASA电池数据集
% 修正版本：正确处理SOC计算和电流数据
% ============================================

%% 1. 清除工作空间
clear all;
close all;
clc;

%% 2. 定义颜色方案
color1 = [0.3, 0.396, 0.6];    % 深蓝色系
color2 = [0.54, 0.55, 0.75];   % 紫色系
color3 = [0.93, 0.79, 0.45];   % 橙色系
color4 = [0.714, 0.463, 0.4];  % 深橙色系

%% 3. 加载NASA电池数据集
try
    if ispc
        desktopPath = fullfile(getenv('USERPROFILE'), 'Desktop');
    else
        desktopPath = fullfile(getenv('HOME'), 'Desktop');
    end
    
    b0005_path = fullfile(desktopPath, 'B0005.mat');
    
    if exist(b0005_path, 'file')
        fprintf('正在从桌面加载B0005.mat文件: %s\n', b0005_path);
        data = load(b0005_path);
        
        vars = fieldnames(data);
        if ismember('B0005', vars)
            B0005 = data.B0005;
            fprintf('成功加载B0005.mat文件\n');
        else
            first_var = vars{1};
            B0005 = data.(first_var);
            fprintf('使用变量名: %s\n', first_var);
        end
    else
        error('文件不存在: %s', b0005_path);
    end
    
catch ME
    fprintf('错误: 无法加载B0005.mat文件。\n');
    fprintf('错误信息: %s\n', ME.message);
    return;
end

% 检查数据结构
if ~exist('B0005', 'var') || ~isfield(B0005, 'cycle')
    fprintf('错误: 数据结构不正确。\n');
    return;
end

% 提取放电循环数据
discharge_cycles = [];
for i = 1:length(B0005.cycle)
    if isfield(B0005.cycle(i), 'type') && strcmp(B0005.cycle(i).type, 'discharge')
        discharge_cycles = [discharge_cycles, i];
    end
end

if isempty(discharge_cycles)
    fprintf('警告: 未找到放电循环数据，使用第一个循环。\n');
    discharge_cycles = 1;
end

% 使用第一个放电循环
cycle_idx = discharge_cycles(1);
fprintf('使用第%d个循环数据\n', cycle_idx);

cycle_data = B0005.cycle(cycle_idx);

if isfield(cycle_data, 'type')
    fprintf('循环类型: %s\n', cycle_data.type);
end

if ~isfield(cycle_data, 'data')
    fprintf('错误: 循环数据不包含data字段。\n');
    return;
end

discharge_data = cycle_data.data;

% 提取数据
time_sec = [];
voltage = [];
current = [];
temperature = [];
capacity = [];

if isfield(discharge_data, 'Time')
    time_sec = discharge_data.Time;
elseif isfield(discharge_data, 'time')
    time_sec = discharge_data.time;
end

if isfield(discharge_data, 'Voltage_measured')
    voltage = discharge_data.Voltage_measured;
end

if isfield(discharge_data, 'Current_measured')
    current = discharge_data.Current_measured;
end

if isfield(discharge_data, 'Temperature_measured')
    temperature = discharge_data.Temperature_measured;
end

if isfield(discharge_data, 'Capacity')
    capacity = discharge_data.Capacity;
end

% 检查数据完整性
if isempty(time_sec) || isempty(voltage) || isempty(current)
    fprintf('错误: 缺少必要的测量数据字段。\n');
    return;
end

% 将时间转换为小时
time_hours = time_sec / 3600;

% ========== 关键修复开始 ==========

% 修复1：电流数据应该是正值（放电电流）
current = abs(current); % 取绝对值

% 修复2：正确计算SOC
if ~isempty(capacity)
    % 根据文档，新电池的额定容量是2Ah
    rated_capacity = 2.0; % Ah
    
    % Capacity是累计放电量，所以SOC = 1 - (已放电容量/额定容量)
    SOC_measured = 1 - (capacity / rated_capacity);
    
    % 确保SOC在合理范围内
    SOC_measured = max(0, min(1, SOC_measured));
    
    fprintf('使用Capacity字段计算SOC，额定容量: %.3f Ah\n', rated_capacity);
    fprintf('本次循环最大放电容量: %.3f Ah\n', max(capacity));
else
    % 如果没有Capacity字段，使用简化方法
    fprintf('警告: 未找到Capacity字段，使用简化方法计算SOC。\n');
    SOC_measured = 1 - (time_hours - min(time_hours)) / (max(time_hours) - min(time_hours));
    rated_capacity = 2.0;
end

% ========== 关键修复结束 ==========

% 电池参数
V_battery = mean(voltage);
Q_nom = rated_capacity; % 使用额定容量
SOC_initial = max(SOC_measured);

fprintf('数据加载完成:\n');
fprintf('  数据点数: %d\n', length(time_sec));
fprintf('  额定容量: %.3f Ah\n', Q_nom);
fprintf('  平均电压: %.2f V\n', V_battery);
fprintf('  时间范围: %.2f 到 %.2f 小时\n', min(time_hours), max(time_hours));
fprintf('  电流范围: %.3f 到 %.3f A\n', min(current), max(current));
fprintf('  SOC范围: %.2f%% 到 %.2f%%\n', min(SOC_measured)*100, max(SOC_measured)*100);

%% 4. 定义基于真实数据的函数
function I_total = get_actual_current(t, time_hours, current_data)
    t_clamped = max(min(t, max(time_hours)), min(time_hours));
    I_total = interp1(time_hours, current_data, t_clamped, 'linear', 'extrap');
end

%% 5. 定义微分方程
function dSOC_dt = battery_ode_actual(t, SOC, time_hours, current_data, Q_nom)
    I_total = get_actual_current(t, time_hours, current_data);
    dSOC_dt = -I_total / Q_nom;
end

%% 6. 设置模拟参数
t_start = min(time_hours);
t_end = max(time_hours);
t_span = [t_start, t_end];
SOC0 = SOC_initial;

%% 7. 求解微分方程
options = odeset('RelTol', 1e-6, 'AbsTol', 1e-9);
ode_fun = @(t, SOC) battery_ode_actual(t, SOC, time_hours, current, Q_nom);

try
    [t, SOC] = ode45(ode_fun, t_span, SOC0, options);
    fprintf('微分方程求解成功\n');
catch ME
    fprintf('微分方程求解失败: %s\n', ME.message);
    t = time_hours;
    SOC = SOC_measured;
end

%% 8. 计算相关参数
I_total_vec = zeros(length(t), 1);
voltage_vec = zeros(length(t), 1);
power_vec = zeros(length(t), 1);

for i = 1:length(t)
    I_total_vec(i) = get_actual_current(t(i), time_hours, current);
    voltage_vec(i) = interp1(time_hours, voltage, t(i), 'linear', 'extrap');
    power_vec(i) = I_total_vec(i) * voltage_vec(i);
end

% 计算剩余使用时间
remaining_time = zeros(length(t), 1);
for i = 1:length(t)
    if SOC(i) > 0.01
        remaining_capacity = SOC(i) * Q_nom;
        if I_total_vec(i) > 0.001 && remaining_capacity > 0
            remaining_time(i) = remaining_capacity / I_total_vec(i);
        else
            remaining_time(i) = 0;
        end
    else
        remaining_time(i) = 0;
    end
end

% 限制剩余时间的最大值
max_remaining_time = 50;
remaining_time(remaining_time > max_remaining_time) = max_remaining_time;
remaining_time(remaining_time < 0) = 0;
remaining_time(isinf(remaining_time)) = 0;

% 调试信息
valid_remaining_times = remaining_time(remaining_time > 0 & remaining_time < max_remaining_time);
if ~isempty(valid_remaining_times)
    fprintf('剩余时间统计:\n');
    fprintf('  有效数据点数: %d\n', length(valid_remaining_times));
    fprintf('  最小值: %.4f 小时\n', min(valid_remaining_times));
    fprintf('  最大值: %.4f 小时\n', max(valid_remaining_times));
else
    fprintf('警告: 无有效剩余时间数据\n');
end

%% 9. 绘图
figure('Position', [100, 100, 1400, 900], 'Color', 'white');

% 子图1: SOC随时间变化
subplot(2, 3, 1);
plot(t, SOC * 100, 'LineWidth', 3, 'Color', color1);
hold on;
plot(time_hours, SOC_measured * 100, '--', 'LineWidth', 2.5, 'Color', color4);
grid on;
xlabel('时间 (小时)');
ylabel('SOC (%)');
title('SOC变化: 模型预测 vs 实际测量');
legend('模型预测', '实际测量', 'Location', 'best');
xlim([t_start, t_end]);
ylim([0, 100]);

% 子图2: 电流随时间变化
subplot(2, 3, 2);
plot(t, I_total_vec * 1000, 'LineWidth', 3, 'Color', color2);
grid on;
xlabel('时间 (小时)');
ylabel('电流 (mA)');
title('放电电流变化');
xlim([t_start, t_end]);

% 子图3: 电压随时间变化
subplot(2, 3, 3);
plot(t, voltage_vec, 'LineWidth', 3, 'Color', color3);
grid on;
xlabel('时间 (小时)');
ylabel('电压 (V)');
title('电池电压变化');
xlim([t_start, t_end]);

% 子图4: 功耗随时间变化
subplot(2, 3, 4);
plot(t, power_vec, 'LineWidth', 3, 'Color', color4);
grid on;
xlabel('时间 (小时)');
ylabel('功耗 (W)');
title('电池功耗变化');
xlim([t_start, t_end]);

% 子图5: 剩余使用时间预测
subplot(2, 3, 5);
valid_indices = ~isinf(remaining_time) & ~isnan(remaining_time) & remaining_time >= 0;
if any(valid_indices) && max(remaining_time(valid_indices)) > 0.001
    plot(t(valid_indices), remaining_time(valid_indices), 'LineWidth', 3, 'Color', color1);
    title('预测剩余使用时间');
else
    plot(t, zeros(size(t)), 'LineWidth', 3, 'Color', color1);
    text(0.5, 0.5, '剩余时间计算异常', 'HorizontalAlignment', 'center', 'Units', 'normalized');
    title('剩余时间计算异常');
end
grid on;
xlabel('时间 (小时)');
ylabel('剩余使用时间 (小时)');
xlim([t_start, t_end]);

% 子图6: 温度随时间变化
subplot(2, 3, 6);
if ~isempty(temperature)
    temperature_vec = interp1(time_hours, temperature, t, 'linear', 'extrap');
    plot(t, temperature_vec, 'LineWidth', 3, 'Color', color2);
    title('电池温度变化');
    ylabel('温度 (°C)');
else
    text(0.5, 0.5, '温度数据不可用', 'HorizontalAlignment', 'center', 'Units', 'normalized');
    title('数据信息');
end
grid on;
xlabel('时间 (小时)');
xlim([t_start, t_end]);

sgtitle('智能手机电池模型 - NASA数据集分析', 'FontSize', 16);

%% 10. 输出结果
fprintf('\n============================================\n');
fprintf('电池模型模拟结果\n');
fprintf('============================================\n');
fprintf('额定容量: %.3f Ah\n', Q_nom);
fprintf('平均电压: %.2f V\n', V_battery);
fprintf('放电持续时间: %.2f 小时\n', t_end - t_start);
fprintf('平均放电电流: %.1f mA\n', mean(current)*1000);

% 计算电池耗尽时间
[~, idx] = min(abs(SOC - 0.01));
if idx < length(SOC)
    t_empty = t(idx);
    fprintf('电池耗尽至1%%时间: %.2f 小时\n', t_empty);
end

fprintf('模型验证完成！\n');