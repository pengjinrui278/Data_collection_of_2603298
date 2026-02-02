% 参数设置
t_max = 100; % 最大模拟时间（单位：分钟）
t = 0:t_max; % 时间向量（0到100分钟）
SOC_initial = 100; % 初始SOC（100%）
SOC_min = 0; % 最小SOC（0%）
decay_rate = 0.5; % SOC衰减速率（线性衰减，每分钟降低0.5%）
t_target = 80; % 用户目标使用时间（单位：分钟）

% 生成模拟SOC数据（线性衰减）
SOC = max(SOC_min, SOC_initial - decay_rate * t);

% 生成模拟的预测剩余使用时间 t_predicted（基于SOC和随机噪声）
% 假设 t_predicted 与SOC成正比，并添加随机波动
t_predicted = (SOC / 100) * t_target + 5 * randn(size(t)); % 添加高斯噪声模拟预测误差
t_predicted = max(1, t_predicted); % 确保预测时间不为负

% 计算用户紧急度 t_urg
t_urg = max(0, (t_target - t_predicted) / t_target);

% 根据策略确定CPU频率限制
cpu_freq_limit = zeros(size(t)); % 初始化CPU频率限制（单位：最大频率的百分比）
mode_labels = cell(size(t)); % 存储模式标签

for i = 1:length(t)
    if SOC(i) < 10
        % Ultra Power Saving Mode: SOC < 10%
        cpu_freq_limit(i) = 60; % 频率不超过60%
        mode_labels{i} = 'Ultra Power Saving';
    elseif (SOC(i) < 20) || (t_urg(i) > 0.5)
        % Energy Saving Mode: SOC < 20% 或 t_urg > 0.5
        cpu_freq_limit(i) = 65; % 频率限制在60-70%，取中间值65%
        mode_labels{i} = 'Energy Saving';
    else
        % Normal Mode: SOC > 20% 且 t_urg < 0.2
        cpu_freq_limit(i) = 100; % 无限制（100%最大频率）
        mode_labels{i} = 'Normal';
    end
end

% 可视化
figure('Position', [100, 100, 1200, 800]);

% 子图1: SOC曲线
subplot(3, 1, 1);
plot(t, SOC, 'b-', 'LineWidth', 2);
ylabel('SOC (%)');
title('电池SOC随时间变化');
grid on;
ylim([0, 100]);
% 添加模式区域背景
hold on;
for i = 1:length(t)-1
    if strcmp(mode_labels{i}, 'Ultra Power Saving')
        patch([t(i), t(i+1), t(i+1), t(i)], [0, 0, 100, 100], 'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
    elseif strcmp(mode_labels{i}, 'Energy Saving')
        patch([t(i), t(i+1), t(i+1), t(i)], [0, 0, 100, 100], 'y', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
    end
end
legend('SOC', 'Ultra Power Saving Zone', 'Energy Saving Zone', 'Location', 'northeast');

% 子图2: 用户紧急度 t_urg
subplot(3, 1, 2);
plot(t, t_urg, 'r-', 'LineWidth', 2);
ylabel('紧急度 t_{urg}');
title('用户紧急度随时间变化');
grid on;
ylim([0, 1]);
% 添加阈值线（t_urg = 0.2 和 0.5）
hold on;
plot([t(1), t(end)], [0.2, 0.2], 'g--', 'LineWidth', 1.5, 'DisplayName', '正常模式阈值 (0.2)');
plot([t(1), t(end)], [0.5, 0.5], 'm--', 'LineWidth', 1.5, 'DisplayName', '节能模式阈值 (0.5)');
legend('紧急度 t_{urg}', '正常模式阈值', '节能模式阈值', 'Location', 'northeast');

% 子图3: CPU频率限制及模式标注
subplot(3, 1, 3);
stairs(t, cpu_freq_limit, 'k-', 'LineWidth', 2); % 使用阶梯图显示离散变化
ylabel('CPU频率限制 (% of max)');
xlabel('时间 (分钟)');
title('CPU频率限制策略动态调整');
grid on;
ylim([50, 105]);
% 标注模式切换点
mode_changes = find(diff(cpu_freq_limit) ~= 0) + 1; % 找到频率变化的时间点
hold on;
for i = 1:length(mode_changes)
    idx = mode_changes(i);
    text(t(idx), cpu_freq_limit(idx), mode_labels{idx}, ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', ...
        'FontSize', 8, 'Color', 'blue');
end
legend('CPU频率限制', '模式切换点', 'Location', 'southeast');

% 整体标题
sgtitle('操作系统电源管理策略模拟（基于SOC和用户紧急度）');