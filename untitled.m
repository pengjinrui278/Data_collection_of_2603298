%% 1. 定义颜色方案
% 定义四种颜色组合
color1 = [0.2, 0.4, 0.8];    % 深蓝色系 - 提高对比度
color2 = [0.4, 0.4, 0.8];    % 紫色系 - 增强饱和度
color3 = [0.95, 0.8, 0.3];   % 橙色系 - 提高亮度
color4 = [0.9, 0.4, 0.2];    % 深橙色系 - 增强对比度
%% 2. 模拟数据
% 时间序列 (分钟)
t = 0:0.1:60; % 60分钟，0.1分钟步长
n = length(t);

% 模拟正常模式下的各组件功耗 (W)
% 模拟一些波动和趋势
P_cpu = 0.3 + 0.3*sin(2*pi*t/20) + 0.1*randn(1,n);
P_disp = 0.4 + 0.4*sin(2*pi*t/25 + 1) + 0.1*randn(1,n);
P_net = 0.2 + 0.2*sin(2*pi*t/30 + 2) + 0.05*randn(1,n);
P_base = 0.3; % 基础功耗

% 定义节流因子 (取中间值)
alpha_cpu = 0.65;  % CPU节流因子
alpha_disp = 0.75; % 显示节流因子
alpha_net = 0.40;   % 网络节流因子

% 计算节能模式下的各组件功耗
P_cpu_save = alpha_cpu * P_cpu;
P_disp_save = alpha_disp * P_disp;
P_net_save = alpha_net * P_net;

% 计算总功耗
P_normal = P_cpu + P_disp + P_net + P_base;
P_save = P_cpu_save + P_disp_save + P_net_save + P_base;

% 计算节电百分比
power_saving_percent = 100 * (1 - P_save ./ P_normal);

%% 3. 创建图形窗口
fig = figure('Position', [100, 100, 1200, 800], 'Color', 'white');



%% 5. 子图2: 总功耗对比
subplot(2, 2, 2);
hold on;
grid on;

% 绘制总功耗曲线
plot(t, P_normal, 'Color', color1, 'LineWidth', 2, 'DisplayName', 'Normal Mode Power Consumption');
plot(t, P_save, 'Color', color2, 'LineWidth', 2, 'DisplayName', 'Power-saving Mode Consumption');

% 填充两个曲线之间的区域
fill_x = [t, fliplr(t)];
fill_y = [P_save, fliplr(P_normal)];
fill(fill_x, fill_y, color3, 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', 'Power Reduction');

% 标记平均功耗
mean_normal = mean(P_normal);
mean_save = mean(P_save);
plot([min(t), max(t)], [mean_normal, mean_normal], ':', 'Color', color1, 'LineWidth', 1, 'HandleVisibility', 'off');
plot([min(t), max(t)], [mean_save, mean_save], ':', 'Color', color2, 'LineWidth', 1, 'HandleVisibility', 'off');

xlabel('time(min)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Total Power Consumption (W)', 'FontSize', 11, 'FontWeight', 'bold');
%title('Normal Mode vs Power-saving Mode', 'FontSize', 12, 'FontWeight',5 'bold');
legend('Location', 'best', 'FontSize', 9);
hold off;

