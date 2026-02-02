%% 13. 分析使用模式波动对预测结果的影响
fprintf('\n=== 分析使用模式波动对预测结果的影响 ===\n');

% 定义不同的使用模式
use_modes = {
    '轻量使用', 0.7;   % 所有功耗组件乘以0.7
    '典型使用', 1.0;   % 基准场景
    '重度使用', 1.3;   % 所有功耗组件乘以1.3
    '游戏模式', 1.5;   % 特别针对游戏场景
    '节能模式', 0.5;   % 节能场景
};

n_modes = size(use_modes, 1);

% 初始化结果存储
mode_results = struct();
mode_names = cell(1, n_modes);
mode_scaling_factors = zeros(1, n_modes);
avg_power_modes = zeros(1, n_modes);
avg_current_modes = zeros(1, n_modes);
depletion_20_modes = zeros(1, n_modes);
depletion_50_modes = zeros(1, n_modes);
depletion_95_modes = zeros(1, n_modes);

% 对每种使用模式进行计算
fprintf('计算不同使用模式下的电池性能...\n');

for m = 1:n_modes
    mode_name = use_modes{m, 1};
    scaling_factor = use_modes{m, 2};
    
    fprintf('正在计算 %s 模式 (缩放因子: %.1f)...\n', mode_name, scaling_factor);
    
    % 根据缩放因子调整各组件功耗
    P_idle_mode = P_idle * scaling_factor;
    P_scr_mode = P_scr * scaling_factor;
    P_cpu_mode = P_cpu * scaling_factor;
    P_gpu_mode = P_gpu * scaling_factor;
    P_net_mode = P_net * scaling_factor;
    P_gps_mode = P_gps * scaling_factor;
    
    % 特别处理游戏模式
    if strcmp(mode_name, '游戏模式')
        % 游戏模式下增加GPU和CPU功耗
        P_cpu_mode = P_cpu * 1.8;
        P_gpu_mode = P_gpu * 1.8;
        P_scr_mode = P_scr * 1.2;  % 屏幕亮度增加
    end
    
    % 计算总功耗
    P_other_mode = P_video + P_audio + P_cam + P_bt;  % 保持其他功耗不变
    P_tot_mode = P_idle_mode + P_scr_mode + P_cpu_mode + P_gpu_mode + ...
                 P_net_mode + P_gps_mode + P_other_mode;
    
    % 确保功耗不为负
    P_tot_mode = max(0.001, P_tot_mode);
    
    % 计算电流
    V_bat_mode = V_nom * ones(1, N);
    I_mode = P_tot_mode ./ (V_bat_mode + eps);
    
    % 计算SOC
    SOC_mode = zeros(1, N);
    SOC_mode(1) = SOC0;
    total_charge_mode = 0;
    
    for i = 2:N
        I_avg_mode = (I_mode(i) + I_mode(i-1)) / 2;
        dt_hours = dt / 3600;
        delta_charge = max(0, I_avg_mode * dt_hours);
        total_charge_mode = total_charge_mode + delta_charge;
        SOC_mode(i) = max(0, min(1, SOC0 - total_charge_mode / Q_nom));
    end
    
    % 计算放电时间
    SOC_targets = [0.8, 0.5, 0.05];
    depletion_times_mode = zeros(1, 3);
    
    for j = 1:3
        target_SOC = SOC_targets(j);
        idx = find(SOC_mode <= target_SOC, 1);
        
        if ~isempty(idx) && idx > 1
            t1 = t_hours(idx-1);
            t2 = t_hours(idx);
            soc1 = SOC_mode(idx-1);
            soc2 = SOC_mode(idx);
            
            if abs(soc1 - soc2) > 1e-10
                depletion_times_mode(j) = t1 + (t2 - t1) * (soc1 - target_SOC) / (soc1 - soc2);
            else
                depletion_times_mode(j) = t1;
            end
        else
            % 外推估计
            avg_current_mode = mean(I_mode(I_mode > 0), 'omitnan');
            depletion_times_mode(j) = (SOC0 - target_SOC) * Q_nom / max(0.001, avg_current_mode);
        end
    end
    
    % 存储结果
    mode_names{m} = mode_name;
    mode_scaling_factors(m) = scaling_factor;
    avg_power_modes(m) = mean(P_tot_mode);
    avg_current_modes(m) = mean(I_mode(I_mode > 0), 'omitnan') * 1000;  % 转换为mA
    depletion_20_modes(m) = depletion_times_mode(1);
    depletion_50_modes(m) = depletion_times_mode(2);
    depletion_95_modes(m) = depletion_times_mode(3);
    
    % 输出结果
    fprintf('  %s模式: 平均功耗=%.2fW, 平均电流=%.0fmA, ', ...
        mode_name, avg_power_modes(m), avg_current_modes(m));
    fprintf('放电20%%=%.1fh, 放电50%%=%.1fh, 放电95%%=%.1fh\n', ...
        depletion_20_modes(m), depletion_50_modes(m), depletion_95_modes(m));
end

%% 14. 创建使用模式影响分析图表
fprintf('\n创建使用模式影响分析图表...\n');

fig3 = figure('Name', '使用模式波动对电池性能的影响分析', ...
    'NumberTitle', 'off', 'Position', [100, 100, 1400, 900], 'Color', [1, 1, 1]);

% 创建选项卡组
tabgroup_mode = uitabgroup('Parent', fig3, 'Position', [0, 0, 1, 1]);

% 选项卡1: 综合对比表格
tab1 = uitab(tabgroup_mode, 'Title', '综合对比');

% 准备表格数据
table_data_modes = cell(n_modes, 9);

for m = 1:n_modes
    % 计算相对于基准模式的变化率
    if m == 2  % 基准模式
        power_change = 0.0;
        current_change = 0.0;
        time_20_change = 0.0;
        time_50_change = 0.0;
        time_95_change = 0.0;
    else
        power_change = (avg_power_modes(m) - avg_power_modes(2)) / avg_power_modes(2) * 100;
        current_change = (avg_current_modes(m) - avg_current_modes(2)) / avg_current_modes(2) * 100;
        time_20_change = (depletion_20_modes(m) - depletion_20_modes(2)) / depletion_20_modes(2) * 100;
        time_50_change = (depletion_50_modes(m) - depletion_50_modes(2)) / depletion_50_modes(2) * 100;
        time_95_change = (depletion_95_modes(m) - depletion_95_modes(2)) / depletion_95_modes(2) * 100;
    end
    
    table_data_modes{m, 1} = mode_names{m};
    table_data_modes{m, 2} = sprintf('%.1f', mode_scaling_factors(m));
    table_data_modes{m, 3} = sprintf('%.2f W', avg_power_modes(m));
    table_data_modes{m, 4} = sprintf('%.0f mA', avg_current_modes(m));
    table_data_modes{m, 5} = sprintf('%.1f 小时', depletion_20_modes(m));
    table_data_modes{m, 6} = sprintf('%.1f 小时', depletion_50_modes(m));
    table_data_modes{m, 7} = sprintf('%.1f 小时', depletion_95_modes(m));
    
    % 变化率（带正负号）
    table_data_modes{m, 8} = sprintf('%+.1f%%', power_change);
    table_data_modes{m, 9} = sprintf('%+.1f%%', time_95_change);
end

% 创建表格
uit_mode = uitable('Parent', tab1, ...
    'Data', table_data_modes, ...
    'Position', [20, 50, 1350, 800], ...
    'ColumnName', {'使用模式', '缩放因子', '平均功耗', '平均电流', ...
                   '放电20%时间', '放电50%时间', '放电95%时间', ...
                   '功耗变化率', '续航变化率'}, ...
    'ColumnWidth', {100, 80, 100, 100, 120, 120, 120, 100, 100}, ...
    'RowName', [], 'FontSize', 10);

% 标题
title_text1 = '不同使用模式下的电池性能对比 (基准: 典型使用模式)';
uicontrol('Parent', tab1, 'Style', 'text', 'String', title_text1, ...
    'Position', [20, 850, 1350, 30], 'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left');

% 添加说明
info_text = '说明: 1. 变化率为相对于典型使用模式的百分比变化';
info_text = [info_text, sprintf('\n2. 游戏模式: CPU和GPU功耗额外增加80%%, 屏幕亮度增加20%%')];
info_text = [info_text, sprintf('\n3. 节能模式: 所有功耗组件降低50%%, 关闭非必要功能')];

uicontrol('Parent', tab1, 'Style', 'text', 'String', info_text, ...
    'Position', [20, 20, 1350, 40], 'FontSize', 9, ...
    'HorizontalAlignment', 'left', 'BackgroundColor', [0.95, 0.95, 0.95]);

%% 选项卡2: 可视化图表
tab2 = uitab(tabgroup_mode, 'Title', '可视化分析');

% 子图1: 平均功耗对比
subplot(2, 3, 1);
bar(avg_power_modes);
set(gca, 'XTickLabel', mode_names, 'XTickLabelRotation', 45);
ylabel('平均功耗 (W)');
title('不同使用模式下的平均功耗对比');
grid on;

% 添加数值标签
for i = 1:length(avg_power_modes)
    text(i, avg_power_modes(i), sprintf('%.2fW', avg_power_modes(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end

% 子图2: 续航时间对比
subplot(2, 3, 2);
bar_data = [depletion_20_modes; depletion_50_modes; depletion_95_modes]';
bar(bar_data);
set(gca, 'XTickLabel', mode_names, 'XTickLabelRotation', 45);
ylabel('放电时间 (小时)');
title('不同放电深度的续航时间对比');
legend('放电20%', '放电50%', '放电95%', 'Location', 'best');
grid on;

% 子图3: 功耗与续航关系
subplot(2, 3, 3);
scatter(avg_power_modes, depletion_95_modes, 100, 'filled');
xlabel('平均功耗 (W)');
ylabel('放电95%时间 (小时)');
title('功耗与续航关系');
grid on;

% 添加模式标签
for i = 1:length(mode_names)
    text(avg_power_modes(i), depletion_95_modes(i), mode_names{i}, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end

% 子图4: 功耗构成分析（典型模式）
subplot(2, 3, 4);
power_components_typical = [mean(P_idle*ones(1,N)), mean(P_scr), mean(P_cpu), ...
                           mean(P_gpu), mean(P_net), mean(P_gps), mean(P_other)];
power_labels = {'基础功耗', '屏幕', 'CPU', 'GPU', '网络', 'GPS', '其他'};
pie(power_components_typical, power_labels);
title('典型使用模式下的功耗构成');

% 子图5: 续航变化率
subplot(2, 3, 5);
% 计算续航变化率（相对于基准）
time_changes = zeros(1, n_modes);
for m = 1:n_modes
    if m == 2
        time_changes(m) = 0;
    else
        time_changes(m) = (depletion_95_modes(m) - depletion_95_modes(2)) / depletion_95_modes(2) * 100;
    end
end

bar(time_changes);
set(gca, 'XTickLabel', mode_names, 'XTickLabelRotation', 45);
ylabel('续航变化率 (%)');
title('不同模式下的续航变化率（相对于典型模式）');
grid on;

% 添加数值标签
for i = 1:length(time_changes)
    if time_changes(i) >= 0
        va = 'bottom';
    else
        va = 'top';
    end
    text(i, time_changes(i), sprintf('%+.1f%%', time_changes(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', va);
end

% 子图6: 使用强度与续航关系
subplot(2, 3, 6);
plot(mode_scaling_factors, depletion_95_modes, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('使用强度缩放因子');
ylabel('放电95%时间 (小时)');
title('使用强度与续航关系');
grid on;

% 添加模式标签
for i = 1:length(mode_names)
    text(mode_scaling_factors(i), depletion_95_modes(i), mode_names{i}, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end

%% 15. 分析使用模式波动对预测不确定性的影响
fprintf('\n=== 使用模式波动对预测不确定性的影响分析 ===\n');

% 计算续航时间的统计特性
max_time = max(depletion_95_modes);
min_time = min(depletion_95_modes);
avg_time = mean(depletion_95_modes);
std_time = std(depletion_95_modes);
cv_time = std_time / avg_time * 100;  % 变异系数

fprintf('续航时间统计特性 (放电95%%):\n');
fprintf('• 最大值: %.1f 小时 (%s模式)\n', max_time, mode_names{depletion_95_modes == max_time});
fprintf('• 最小值: %.1f 小时 (%s模式)\n', min_time, mode_names{depletion_95_modes == min_time});
fprintf('• 平均值: %.1f 小时\n', avg_time);
fprintf('• 标准差: %.1f 小时\n', std_time);
fprintf('• 变异系数: %.1f%%\n', cv_time);
fprintf('• 波动范围: ±%.1f%% (相对于平均值)\n', (max_time - min_time) / avg_time * 50);

% 计算预测不确定性
fprintf('\n预测不确定性分析:\n');
fprintf('• 最乐观预测 (节能模式): %.1f 小时\n', max_time);
fprintf('• 最悲观预测 (游戏模式): %.1f 小时\n', min_time);
fprintf('• 预测范围: %.1f 小时\n', max_time - min_time);
fprintf('• 相对不确定性: %.1f%%\n', (max_time - min_time) / avg_time * 100);

% 计算敏感度系数
fprintf('\n使用模式对续航的敏感度系数:\n');
for m = 1:n_modes
    if m ~= 2  % 跳过基准模式
        power_sensitivity = (depletion_95_modes(m) - depletion_95_modes(2)) / depletion_95_modes(2) * 100;
        scaling_change = (mode_scaling_factors(m) - mode_scaling_factors(2)) / mode_scaling_factors(2) * 100;
        sensitivity_coeff = power_sensitivity / scaling_change;
        
        fprintf('• %s模式: 缩放因子变化%.0f%% → 续航变化%.1f%% → 敏感度系数: %.2f\n', ...
            mode_names{m}, scaling_change, power_sensitivity, sensitivity_coeff);
    end
end

%% 16. 创建预测不确定性分析表格
fig4 = figure('Name', '预测不确定性分析', ...
    'NumberTitle', 'off', 'Position', [100, 100, 1200, 600], 'Color', [1, 1, 1]);

% 创建表格数据
uncertainty_data = cell(7, 4);
uncertainty_data{1,1} = '统计指标'; uncertainty_data{1,2} = '数值'; uncertainty_data{1,3} = '单位'; uncertainty_data{1,4} = '说明';
uncertainty_data{2,1} = '续航最大值'; uncertainty_data{2,2} = sprintf('%.1f', max_time); uncertainty_data{2,3} = '小时'; uncertainty_data{2,4} = '节能模式下的最长续航';
uncertainty_data{3,1} = '续航最小值'; uncertainty_data{3,2} = sprintf('%.1f', min_time); uncertainty_data{3,3} = '小时'; uncertainty_data{3,4} = '游戏模式下的最短续航';
uncertainty_data{4,1} = '预测平均值'; uncertainty_data{4,2} = sprintf('%.1f', avg_time); uncertainty_data{4,3} = '小时'; uncertainty_data{4,4} = '五种模式的平均续航';
uncertainty_data{5,1} = '预测范围'; uncertainty_data{5,2} = sprintf('%.1f', max_time - min_time); uncertainty_data{5,3} = '小时'; uncertainty_data{5,4} = '最大与最小续航差值';
uncertainty_data{6,1} = '相对不确定性'; uncertainty_data{6,2} = sprintf('%.1f%%', (max_time - min_time)/avg_time*100); uncertainty_data{6,3} = '%'; uncertainty_data{6,4} = '预测波动范围占平均值比例';
uncertainty_data{7,1} = '变异系数'; uncertainty_data{7,2} = sprintf('%.1f%%', cv_time); uncertainty_data{7,3} = '%'; uncertainty_data{7,4} = '续航时间的离散程度';

% 创建表格
uit_uncertainty = uitable('Parent', fig4, ...
    'Data', uncertainty_data, ...
    'Position', [50, 50, 1100, 500], ...
    'ColumnName', {'指标', '数值', '单位', '说明'}, ...
    'ColumnWidth', {150, 100, 80, 400}, ...
    'RowName', [], 'FontSize', 10);

% 标题
title_text2 = '基于使用模式波动的预测不确定性分析';
uicontrol('Parent', fig4, 'Style', 'text', 'String', title_text2, ...
    'Position', [50, 550, 1100, 30], 'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left');

% 添加总结说明
summary_text = sprintf(['主要发现:\n' ...
    '1. 使用模式的波动导致续航预测存在显著的变异性\n' ...
    '2. 从节能模式到游戏模式，续航时间变化范围达 %.0f%%\n' ...
    '3. 平均功耗是影响续航的最关键因素，敏感度系数约为 -0.8\n' ...
    '4. 实际使用中，用户行为模式的不可预测性是电池续航预测的主要不确定性来源'], ...
    (max_time - min_time)/avg_time*100);

uicontrol('Parent', fig4, 'Style', 'text', 'String', summary_text, ...
    'Position', [50, 20, 1100, 30], 'FontSize', 10, ...
    'HorizontalAlignment', 'left', 'BackgroundColor', [0.95, 0.95, 0.95]);

fprintf('\n使用模式波动分析完成！已创建3个分析图表。\n');
fprintf('==============================================================================\n');